extends SceneTree

var failures := 0
var flow: Node
var dialogic: Node

func _initialize() -> void:
	create_timer(55, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	flow = root.get_node("FlowManager")
	dialogic = root.get_node("Dialogic")
	var previous: String = dialogic.Save.get_latest_slot()
	var saver: Node = root.get_node("SaveManager")
	saver.set_script(load("res://scripts/tests/isolated_test_save.gd"))
	saver.test_slot = "ending_autosave_audit_" + str(Time.get_ticks_usec())
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	root.add_child(host)
	current_scene = host
	flow.apply_flow_state("ch3_transcend", "ch3_4_route")
	root.get_node("SceneManager").initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	flow.set_dialogic_var("Affinity.Wu", 50)
	root.get_node("TextSpeedManager")._hold_acceleration = true
	root.get_node("EventBus").dialogue_requested.emit("3_1_route")
	await wait_question()
	check(saver.has_autosave(), "Ending choice automatically creates an independent save")
	check(not saver.has_save(), "Ending auto checkpoint leaves the manual slot untouched")
	# Fully await layout teardown before testing main-menu mouse input.
	await dialogic.end_timeline(true)
	await frames()
	root.get_node("GameManager").enter_main_menu()
	flow.reset_gameplay_runtime()
	change_scene_to_file("res://scenes/UI/main_menu.tscn")
	await frames()
	check(not current_scene.load_button.disabled, "Main menu enables Load when only an automatic save exists")
	await click(current_scene.load_button)
	if not is_instance_valid(current_scene._menu_overlay):
		check(false, "Mouse opens the save selection sheet")
		dialogic.Save.delete_slot(saver._get_autosave_slot_name())
		dialogic.Save.set_latest_slot(previous)
		quit(1)
		return
	var automatic: Button
	for node: Node in current_scene._menu_overlay.find_children("*", "Button", true, false):
		if node.text == "结局前 · 自动存档": automatic = node
	check(automatic != null and not automatic.disabled, "Ending checkpoint is visible in the load menu")
	if automatic != null: await click(automatic)
	await frames()
	await wait_question()
	check(dialogic.current_timeline != null and dialogic.current_timeline.resource_path.ends_with("3_1_route.dtl"), "Automatic load restores the ending decision timeline")
	var texts := ""
	for choice: Dictionary in dialogic.Choices.get_current_question_info().get("choices", []): texts += str(choice.get("text", ""))
	check(texts.contains("跟老师离开") and texts.contains("留下来保护箱庭中的人"), "Restored checkpoint returns before the ending is selected")
	dialogic.end_timeline()
	saver.cancel_pending_load()
	dialogic.Save.delete_slot(saver._get_autosave_slot_name())
	dialogic.Save.set_latest_slot(previous)
	print("Ending autosave failures=", failures)
	quit(0 if failures == 0 else 1)

func wait_question() -> void:
	var deadline := Time.get_ticks_msec() + 22000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if dialogic.current_state == DialogicGameHandler.States.AWAITING_CHOICE: return
	check(false, "Ending question reached before timeout")

func frames() -> void:
	await process_frame
	await process_frame
	await process_frame

func click(button: Button) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = button.get_global_rect().get_center()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await frames()

func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
