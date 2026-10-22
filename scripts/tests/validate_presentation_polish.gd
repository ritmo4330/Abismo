extends SceneTree

const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
var _failures := 0
var _capture := false


func _initialize() -> void:
	_capture = OS.get_cmdline_user_args().has("--capture")
	create_timer(60.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	var flow: Node = root.get_node("FlowManager")
	var manager: Node = root.get_node("SceneManager")
	var data: Node = root.get_node("DataManager")
	var dialogic: Node = root.get_node("Dialogic")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	var navigation: Node = load("res://scripts/UI/static_investigation_ui.gd").new()
	host.add_child(navigation)
	for path: String in ["clue_panel", "suspicion_panel", "system_panel"]:
		host.add_child(load("res://scenes/UI/%s.tscn" % path).instantiate())
	var manual: Node = host.get_node("SuspicionPanel")
	flow.apply_flow_state("ch0_prologue", "ch0_0_2_snow_camp")
	manager.initialize(host, "res://scenes/ch0_prologue/ch0_snow_field.tscn", "InitialSpawn")
	await create_timer(0.3).timeout
	_check(not navigation.visible, "Prologue never shows exploration UI")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.get_node("GameManager")._unhandled_input(escape)
	_check(not paused, "Prologue cannot open pause menu while automatic story continues")
	_check(not root.get_node("ToastManager").get("_canvas_layer").visible, "Prologue hides notification UI")
	host.get_node("SystemPanel")._open_panel()
	_check(not host.get_node("SystemPanel").visible, "Prologue cannot open investigation system")
	await _snapshot("polish-prologue.png")
	flow.apply_flow_state("ch1_snow_villa", "ch1_1_study_free_investigation")
	await _visit("res://scenes/ch1_snow_villa/ch1_study.tscn")
	_check(flow.is_current_room_exit_blocked(), "Study exit blocked before novel puzzle")
	_check(not navigation._navigation_panel.visible, "Study does not offer premature corridor navigation")
	var door: Node = manager.current_room.find_child("Door", true, false)
	if door != null:
		door.interact(manager.current_player)
		await process_frame
		_check(not manager.is_transitioning and manager.current_room.get("room_id") == "ch1_study", "Clicking study door cannot bypass novel puzzle")
	await _snapshot("polish-study-marker.png")
	flow.advance_to_step("ch1_1_puzzle")
	await process_frame
	await process_frame
	_check(navigation._npc_row.get_child_count() == 0 and navigation._navigation_row.get_child_count() == 1, "Novel reasoning only offers the reasoning manual, no exploration navigation")
	_check(flow.is_current_room_exit_blocked(), "Study remains locked during unsolved novel reasoning")
	var suspicion_id := "1_suspicion_x_disability"
	var definition: Resource = data.get_suspicion_def(suspicion_id)
	data.add_suspicion(suspicion_id, "test", "polish")
	for clue_id: String in ["1_puzzle_maid_scene", "1_puzzle_first_discussion", "1_puzzle_cast"]:
		data.discover_clue(clue_id, "test", "polish")
	for clue_id: String in definition.required_clue_ids:
		data.discover_clue(clue_id, "test", "polish")
	manual.set("_selected_suspicion_id", suspicion_id)
	manual._open_archive_panel()
	var wrong: Array[String] = ["1_puzzle_maid_scene", "1_puzzle_first_discussion", "1_puzzle_cast"]
	manual._store_slot_ids(suspicion_id, wrong)
	manual._show_suspicion_detail(suspicion_id)
	for attempt: int in range(1, 4):
		manual._on_reason_button_pressed()
		_check(manual._novel_hint_label.visible == (attempt >= 3), "Hint threshold: attempt %d" % attempt)
	_check(not data.is_suspicion_resolved(suspicion_id), "Hint does not automatically solve novel reasoning")
	for clue_id: String in definition.required_clue_ids:
		_check(manual._novel_hint_label.text.contains(data.get_clue_def(clue_id).title), "Hint includes required evidence title")
	_check(data.has_flag("novel_hint/%s/failure_3" % suspicion_id), "Hint progress is stored with game flags")
	await _snapshot("polish-novel-hint.png")
	manual._close_panel()
	flow.apply_flow_state("ch1_snow_villa", "ch1_3_intro_hall")
	await _visit("res://scenes/rooms/hall.tscn")
	await create_timer(0.2).timeout
	_check(navigation.visible, "Exploration UI appears during free hall investigation")
	root.get_node("GameManager")._unhandled_input(escape)
	_check(paused, "Free investigation still allows pause")
	root.get_node("GameManager")._unhandled_input(escape)
	_check(not paused, "Escape resumes paused investigation")
	var regular_room: Node2D = manager.current_room
	var cinematic := Node2D.new()
	manager.current_room = cinematic
	_check(not flow.is_player_interface_available(), "Cinematic-only rooms reject player UI even at an investigation step")
	manager.current_room = regular_room
	cinematic.free()
	for index: int in range(2):
		if index == 1:
			root.size = Vector2i(1280, 720)
			root.content_scale_size = Vector2i(1280, 720)
			await create_timer(0.3).timeout
		var panel: Control = navigation._navigation_panel
		var view: Vector2 = root.get_visible_rect().size
		_check(panel.get_global_rect().position.x > view.x * 0.5, "Newspaper menu occupies the right side")
		_check(panel.get_global_rect().position.x >= 0 and panel.get_global_rect().end.x <= view.x + 1, "Newspaper menu fits viewport")
		await _snapshot("polish-bottom-%d.png" % index)
	flow.set_dialogic_var("Ch1.NPCIntro.Mu.Introed", true)
	for index: int in range(1, 4):
		flow.set_dialogic_var("Ch1.NPCIntro.Mu.Selected%d" % index, true)
	root.get_node("TextSpeedManager").set("_hold_acceleration", true)
	root.get_node("EventBus").dialogue_requested.emit("1_3_mu")
	await create_timer(1.6).timeout
	_check(not navigation.visible, "Dialogue hides bottom menu")
	var selected := false
	var choice_deadline: int = Time.get_ticks_msec() + 10000
	while not selected and Time.get_ticks_msec() < choice_deadline:
		if int(dialogic.current_state) == 3:
			for choice: Dictionary in dialogic.Choices.get_current_question_info().get("choices", []):
				if String(choice.get("text", "")) == "暂时没有问题了" and bool(choice.get("visible", false)):
					await create_timer(0.95).timeout
					dialogic.Choices._on_choice_selected(choice)
					selected = true
					break
		await process_frame
	_check(selected, "Normal conversation end option is selected")
	var deadline: int = Time.get_ticks_msec() + 10000
	while dialogic.current_timeline != null and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	await process_frame
	_check(navigation.visible, "End of free conversation restores bottom menu")
	print("Presentation polish regression finished. failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _visit(path: String) -> void:
	root.get_node("EventBus").scene_change_requested.emit(path, "InitialSpawn")
	while root.get_node("SceneManager").is_transitioning:
		await process_frame
	await process_frame
	await process_frame


func _snapshot(filename: String) -> void:
	if _capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT + filename)


func _check(ok: bool, message: String) -> void:
	print("PASS: " + message if ok else "FAIL: " + message)
	if not ok:
		_failures += 1
