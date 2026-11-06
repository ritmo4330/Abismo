extends SceneTree
var failures := 0
func _initialize() -> void:
	create_timer(45.0, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("run")
func run() -> void:
	var flow = root.get_node("FlowManager")
	var dialogic = root.get_node("Dialogic")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	flow.apply_flow_state("ch2_deepening", "ch2_5_third_private_chat")
	root.get_node("TextSpeedManager").set("_hold_acceleration", true)
	for path in ["Ch1.PrivateChat.Wu.Asked.Lighthouse", "Ch1.PrivateChat.Zhou.Asked.DeadTrusted", "Ch2.SourceEvidence.C_2_zhou_1", "Ch2.SourceEvidence.C_2_zhou_2", "Ch2.SourceEvidence.C_2_zhou_3_6"]:
		flow.set_dialogic_var(path, true)
	root.get_node("EventBus").dialogue_requested.emit("2_5_zhou")
	var deadline = Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if dialogic.current_state == DialogicGameHandler.States.AWAITING_CHOICE and not dialogic.Choices.last_question_info.is_empty():
			break
	await create_timer(1.2, true, false, true).timeout
	var info: Dictionary = dialogic.Choices.last_question_info
	var visible: Array = info.get("choices", []).filter(func(c): return c.visible and not c.disabled)
	check(visible.size() > 10, "Real third-round menu contains more than ten available choices: " + str(visible.size()))
	for choice in visible:
		var button = dialogic.Choices.get_choice_button(choice.button_index)
		check(button != null and button.visible and button.text == choice.text, "Choice has its own visible button: " + str(choice.text))
	var first = dialogic.Choices.get_choice_button(1)
	var scroll = first.get_parent().get_parent() if first else null
	check(scroll is ScrollContainer, "Choices use a scroll container")
	if scroll is ScrollContainer:
		scroll.size.y = 300
		await process_frame
		await process_frame
		check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "Long menu is scrollable")
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await process_frame
		check(scroll.scroll_vertical > 0, "Last choices can be reached by scrolling")
	var last = dialogic.Choices.get_choice_button(visible.back().button_index) if not visible.is_empty() else null
	if last:
		last._pressed()
		await process_frame
		check(scroll.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Choice overlay releases mouse after selection")
	print("Private choice UI regression failures=", failures)
	quit(0 if failures == 0 else 1)
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
