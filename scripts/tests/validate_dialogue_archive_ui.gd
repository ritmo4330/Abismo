extends SceneTree

var _capture: bool = false
const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"


func _initialize() -> void:
	_capture = OS.get_cmdline_user_args().has("--capture")
	create_timer(35.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	var flow: Node = root.get_node("FlowManager")
	var bus: Node = root.get_node("EventBus")
	var dialogic: Node = root.get_node("Dialogic")
	var data: Node = root.get_node("DataManager")
	flow.reset_gameplay_runtime()
	if _capture:
		(root.get_node("ToastManager").get("_canvas_layer") as CanvasLayer).hide()
	root.get_node("GameManager").enter_gameplay()
	flow.apply_flow_state("ch1_snow_villa", "ch1_3_intro_hall")
	flow.apply_character_name_state("all_revealed")
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	root.get_node("SceneManager").initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	for path: String in ["res://scenes/UI/clue_panel.tscn", "res://scenes/UI/suspicion_panel.tscn"]:
		host.add_child(load(path).instantiate())
	bus.dialogue_requested.emit("1_3_mu")
	await create_timer(1.5).timeout
	var button: Button = root.find_child("TextboxHistoryButton", true, false) as Button
	_check(button != null, "Textbox history button exists")
	var panel: Control = button.get_parent().get_parent() as Control
	var name_panel: Control = button.get_parent().get_node("NameLabelPanel") as Control
	_check(panel.name == "DialogTextPanel", "History button is owned by dialogue panel")
	_check(button.is_visible_in_tree(), "History button visible with dialogue")
	_check(absf(button.get_global_rect().position.y - name_panel.get_global_rect().position.y) < 1.0, "History button aligns with name panel")
	_check(absf(button.size.y - name_panel.size.y) < 1.0, "History button matches name panel height")
	await _snapshot("dialogue-hourglass.png")
	panel.hide()
	_check(not button.is_visible_in_tree(), "History button disappears immediately when dialogue panel hides")
	panel.show()
	var index_before: int = dialogic.current_event_idx
	button.pressed.emit()
	await process_frame
	_check(dialogic.paused, "Opening history pauses dialogue")
	var history_layer: Node = dialogic.Styles.get_layout_node().find_child("ExampleHistoryScene", true, false)
	_check(history_layer.get_history_box().visible, "History transcript opens")
	history_layer._on_hide_history_pressed()
	_check(not dialogic.paused and dialogic.current_event_idx == index_before, "Closing history resumes same dialogue line")
	await dialogic.end_timeline()
	await process_frame
	dialogic.Styles.load_style("plain_text")
	await create_timer(0.5).timeout
	button = root.find_child("TextboxHistoryButton", true, false) as Button
	_check(button == null or not button.is_visible_in_tree(), "Full-screen prose has no hourglass")
	await dialogic.end_timeline()
	await process_frame
	for clue_id: String in ["1_lin_1", "1_lin_2", "1_lin_3", "1_lin_5", "1_mei_1", "1_mu_1", "1_wu_1"]:
		data.discover_clue(clue_id, "test", "archive_ui")
	for suspicion_id: String in ["1_suspicion_locked_room", "1_suspicion_missing_weapon", "1_suspicion_ability", "1_suspicion_meta_in_lin_room"]:
		data.add_suspicion(suspicion_id, "test", "archive_ui")
	var clues: Node = host.get_node("CluePanel")
	var suspicions: Node = host.get_node("SuspicionPanel")
	_check(clues._open_archive_panel(), "Clue archive opens")
	await create_timer(3.8 if _capture else 0.2).timeout
	await _snapshot("archive-clues.png")
	_check(not clues.detail_body.text.contains("标签：") and not clues.detail_body.text.contains("房间："), "Developer metadata removed from clue details")
	clues.search_line_edit.text = "不存在的线索"
	clues.search_line_edit.text_changed.emit(clues.search_line_edit.text)
	_check(clues.detail_body.text.contains("未找到"), "Clue search still works")
	clues.search_line_edit.text = ""
	clues.search_line_edit.text_changed.emit("")
	var tabs: Node = clues.find_child("ArchiveTabs", true, false)
	(tabs.get_child(1) as Button).pressed.emit()
	await process_frame
	_check(suspicions.visible and not clues.visible, "Clue and suspicion tabs switch correctly")
	await _snapshot("archive-reasoning.png")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await create_timer(0.2).timeout
	var frame: Control = suspicions.panel_frame as Control
	var visible_rect: Rect2 = root.get_visible_rect()
	_check(frame.get_global_rect().end.x <= visible_rect.end.x + 1.0 and frame.get_global_rect().end.y <= visible_rect.end.y + 1.0, "Manual fits 1280x720 viewport")
	await _snapshot("archive-reasoning-1280.png")
	var suspicion_id: String = suspicions.get("_selected_suspicion_id")
	var definition: Resource = data.get_suspicion_def(suspicion_id)
	_check(definition != null, "Selected suspicion data retained")
	var required_ids: PackedStringArray = definition.required_clue_ids
	suspicions.set("_locked_suspicion_id", suspicion_id)
	suspicions._update_lock_widgets()
	_check(suspicions.close_button.disabled, "Locked reasoning still prevents closing")
	var reasoning_tabs: Node = suspicions.find_child("ArchiveTabs", true, false)
	_check((reasoning_tabs.get_child(0) as Button).disabled, "Archive tabs cannot bypass locked reasoning")
	suspicions._on_close_button_pressed()
	_check(suspicions.visible, "Locked reasoning remains open")
	for index: int in required_ids.size():
		data.discover_clue(required_ids[index], "test", "archive_ui")
		suspicions._on_clue_selected_for_reasoning({"source": "suspicion_ui", "suspicion_id": suspicion_id, "slot_index": index}, required_ids[index])
	_check(not suspicions.reason_button.disabled, "Evidence selection still enables reasoning")
	suspicions._on_reason_button_pressed()
	_check(data.is_suspicion_resolved(suspicion_id), "Original reasoning validation still resolves suspicion")
	print("PASS: dialogue hourglass lifecycle, alignment, transcript, full-screen suppression, archive tabs, search, clue selection and reasoning.")
	quit(0)


func _snapshot(filename: String) -> void:
	if not _capture:
		return
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	var result: Error = screenshot.save_png(OUTPUT + filename)
	_check(result == OK, "Saved UI screenshot: " + filename)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		assert(condition, message)
	print("OK: ", message)
