extends SceneTree

var failures := 0
var flow: Node
var manager: Node
var dialogic: Node
var events: Array[String] = []
var finished := false
var test_saver: Node
var previous_slot := ""

func _initialize() -> void:
	create_timer(100.0, true, false, true).timeout.connect(func() -> void:
		if finished:
			return
		push_error("Runtime route timed out: " + str(events))
		quit(1))
	call_deferred("run")

func run() -> void:
	flow = root.get_node("FlowManager")
	manager = root.get_node("SceneManager")
	dialogic = root.get_node("Dialogic")
	previous_slot = dialogic.Save.get_latest_slot()
	test_saver = root.get_node("SaveManager")
	test_saver.set_script(load("res://scripts/tests/isolated_test_save.gd"))
	test_saver.test_slot = "route_audit_" + str(Time.get_ticks_usec())
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	root.get_node("EventBus").flow_signal_requested.connect(func(id: String) -> void: events.append(id))
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	flow.apply_flow_state("ch3_transcend", "ch3_4_route")
	manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await process_frame
	root.get_node("TextSpeedManager").set("_hold_acceleration", true)
	var route := "dust"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--route="):
			route = arg.trim_prefix("--route=")
	flow.set_dialogic_var("Affinity.Wu", 80 if route == "clear" else 50)
	if route == "clear":
		for npc: String in ["Mu", "Zhou", "Lin", "Zhong"]:
			flow.set_dialogic_var("Ch1.PrivateChat.%s.NightmareSolved" % npc, true)
	if route.begins_with("memory"):
		flow.apply_flow_state("ch2_deepening", "ch2_5_third_private_chat")
		flow.set_dialogic_var("Ch2.SceneRecreation.Accepted", route != "memory-refuse")
		root.get_node("EventBus").dialogue_requested.emit("2_6_memory_fragments")
		if route == "memory-refuse":
			await choose("指认穆执")
		elif route == "memory-full":
			await choose("继续复现花海")
			await choose("接过白色立方体")
			await choose("跟老师离开")
		else:
			await choose("到此为止")
			await choose("指认钟歧")
	else:
		root.get_node("EventBus").dialogue_requested.emit("3_1_route")
		match route:
			"dust": await choose("跟老师离开")
			"godslayer":
				await choose("留下来保护箱庭中的人")
				await choose("开枪切断上界控制")
			"calm":
				await choose("留下来保护箱庭中的人")
				await choose("放下武器")
			"clear": await choose("拒绝这两种选择")
	var deadline := Time.get_ticks_msec() + 60000
	var next_report := Time.get_ticks_msec()
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if dialogic.current_timeline != null and dialogic.current_event_idx >= 0 and dialogic.current_event_idx < dialogic.current_timeline_events.size():
			var active_event: Resource = dialogic.current_timeline_events[dialogic.current_event_idx]
			if active_event is DialogicTextInputEvent and dialogic.TextInput.input_confirmed.get_connections().size() > 0:
				var value := "时今" if active_event.variable == "Epilogue.NarratorGuess" else "流程测试"
				dialogic.TextInput.input_confirmed.emit(value)
		if Time.get_ticks_msec() >= next_report:
			next_report += 10000
			print("ROUTE STATE: ", flow.get_current_step_id(), " timeline=", dialogic.current_timeline, " active=", root.get_node("DialogueManager").get("_is_dialogue_active"), " state=", dialogic.current_state, " dialogic_paused=", dialogic.paused, " events=", events)
		if current_scene != null and current_scene.scene_file_path == "res://scenes/UI/main_menu.tscn":
			break
	var expected: String = {"dust": "Dust", "godslayer": "Godslayer", "calm": "Calm", "clear": "ClearSnow"}.get(route, "Dust")
	check(bool(flow.get_dialogic_var("Ending." + expected, false)), "Ending selected: " + expected)
	check(events.has("ending_finished"), "Ending reaches epilogue")
	check(events.has("game_finished"), "Epilogue reaches game completion")
	if route == "memory-full":
		for fragment: String in ["Door", "Flower", "Cube"]:
			check(bool(flow.get_dialogic_var("Ch2.MemoryFragments." + fragment, false)), "Memory collected: " + fragment)
		check(events.has("chapter3_title_finished"), "Full memory enters chapter three")
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/UI/main_menu.tscn", "Completed game returns to menu")
	print("Runtime route ", route, " failures=", failures)
	finished = true
	if test_saver.has_autosave(): dialogic.Save.delete_slot(test_saver._get_autosave_slot_name())
	dialogic.Save.set_latest_slot(previous_slot)
	quit(0 if failures == 0 else 1)

func choose(text: String) -> void:
	var deadline := Time.get_ticks_msec() + 25000
	while Time.get_ticks_msec() < deadline:
		if int(dialogic.current_state) == 3:
			for choice: Dictionary in dialogic.Choices.get_current_question_info().get("choices", []):
				if String(choice.get("text", "")) == text and bool(choice.get("visible", false)):
					await create_timer(0.9, true, false, true).timeout
					for button: Node in get_nodes_in_group("dialogic_choice_button"):
						if button is Button and button.is_visible_in_tree() and not button.disabled and button.text == text:
							var click := InputEventMouseButton.new()
							click.button_index = MOUSE_BUTTON_LEFT
							click.position = button.get_global_rect().get_center()
							click.pressed = true
							root.push_input(click, true)
							await process_frame
							click = click.duplicate()
							click.pressed = false
							root.push_input(click, true)
							return
		await process_frame
	check(false, "Choice available: " + text)

func check(ok: bool, text: String) -> void:
	print("PASS: " + text if ok else "FAIL: " + text)
	if not ok:
		failures += 1
