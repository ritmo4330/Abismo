extends SceneTree

var _flow: Node
var _dialogic: Node
var _bus: Node
var _manager: Node
var _failures := 0


func _initialize() -> void:
	# The watchdog measures wall time, not the Ctrl-accelerated story clock.
	create_timer(150.0, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	_flow = root.get_node("FlowManager")
	_dialogic = root.get_node("Dialogic")
	_bus = root.get_node("EventBus")
	_manager = root.get_node("SceneManager")
	_flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	_flow.apply_flow_state("ch1_snow_villa", "ch1_3_intro_hall")
	_manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	root.get_node("TextSpeedManager").set("_hold_acceleration", true)
	if OS.get_cmdline_user_args().has("--third-all"):
		var topics: Dictionary = {
			"mu": ["烧毁的教堂", "当年的选择", "关于钟歧"],
			"zhou": ["睡眠实验名单", "负责人是梅塔吗", "尸体消失的意义"],
			"lin": ["关于消失的尸体", "异常关联研究室的记录", "九岁前的记忆"],
			"zhong": ["球形装置“坐标锚”", "钟岳的研究", "梦墅究竟是什么", "梅塔与管家的目的"],
		}
		for npc: String in topics:
			_flow.reset_gameplay_runtime()
			_flow.apply_flow_state("ch2_deepening", "ch2_5_third_private_chat")
			_bus.dialogue_requested.emit("2_5_" + npc)
			for topic: String in topics[npc]:
				await _choose(topic)
			await _choose("结束私聊")
			await _wait_idle()
			var key: String = {"mu": "Mu", "zhou": "Zhou", "lin": "Lin", "zhong": "Zhong"}[npc]
			_check(bool(_flow.get_dialogic_var("Ch2.ThirdPrivate.%s.Finished" % key, false)), "All third-private topics complete: " + npc)
		print("Third-private regression failures=", _failures)
		quit(0 if _failures == 0 else 1)
		return
	for npc: String in ["mu", "zhou", "lin", "wu", "zhong"]:
		_bus.dialogue_requested.emit("1_3_" + npc)
		await _choose("")
		if npc == "zhou":
			await _choose("")
		for topic: String in ["自我介绍", "来到别墅的原因", "接下来的打算", "暂时没有问题了"]:
			await _choose(topic)
		await _wait_idle()
		var key: String = {"mu": "Mu", "zhou": "Zhou", "lin": "Lin", "wu": "Wu", "zhong": "Zhong"}[npc]
		for index: int in range(1, 4):
			_check(bool(_flow.get_dialogic_var("Ch1.NPCIntro.%s.Selected%d" % [key, index], false)), "Introduction topic recorded: %s/%d" % [npc, index])
	_check(_flow.get_current_step_id() == "ch1_3_intro_hall", "Meeting characters does not bypass first investigation")
	for order: int in [3, 6]:
		_flow.apply_flow_state("ch2_deepening", "ch2_2_second_private_chat")
		_flow.set_dialogic_var("Ch2.ThirdSearch.Enabled", false)
		_flow.set_dialogic_var("Ch2.ThirdSearch.BodyKnownBeforeTurn", false)
		for key: String in ["Mu", "Zhou", "Lin", "Wu", "Zhong"]:
			_flow.set_dialogic_var("Ch2.SecondPrivate.%s.Finished" % key, true)
		_bus.dialogue_requested.emit("2_2_butler_hall")
		await _choose("开始第三轮搜证")
		await _choose("第三个" if order == 3 else "第六个")
		await _wait_idle()
		_check(int(_flow.get_dialogic_var("Ch2.ThirdSearch.Order", 0)) == order, "Investigation order retained: %d" % order)
		_check(bool(_flow.get_dialogic_var("Ch2.ThirdSearch.BodyKnownBeforeTurn", false)) == (order == 6), "Missing-body branch agrees with chosen order")
		_check(_flow.get_current_step_id() == "ch2_3_third_search", "Third investigation begins only after the order choice")
	_flow.apply_flow_state("ch2_deepening", "ch2_5_third_private_chat")
	_flow.set_dialogic_var("Ch2.SceneRecreation.Accepted", true)
	_bus.dialogue_requested.emit("2_5_wu")
	for topic: String in ["关于密码0909", "花海与白色立方体", "那扇木门", "我会帮你复现场景", "结束私聊"]:
		await _choose(topic)
	await _wait_idle()
	_check(bool(_flow.get_dialogic_var("Ch2.ThirdPrivate.Wu.Finished", false)), "Third private conversation records all four topics and completes")
	print("AVG choice regression finished. failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _choose(text: String) -> void:
	var deadline: int = Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		if int(_dialogic.current_state) == 3:
			var info: Dictionary = _dialogic.Choices.get_current_question_info()
			for choice: Dictionary in info.get("choices", []):
				if bool(choice.get("visible", false)) and not bool(choice.get("disabled", true)) and (text.is_empty() or String(choice.text) == text):
					await create_timer(float(_dialogic.Choices.reveal_delay) + float(_dialogic.Choices.block_delay) + 0.25).timeout
					_dialogic.Choices._on_choice_selected(choice)
					await process_frame
					return
		await process_frame
	_check(false, "Choice is reachable: " + text)
	print("Question debug: state=", _dialogic.current_state, " question=", _dialogic.Choices.last_question_info)
	quit(1)


func _wait_idle() -> void:
	var deadline: int = Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if _dialogic.current_timeline == null and not _manager.is_transitioning:
			await create_timer(0.3).timeout
			if _dialogic.current_timeline == null and not _manager.is_transitioning:
				return
	_check(false, "Dialogue and transition complete")
	quit(1)


func _check(ok: bool, message: String) -> void:
	print("PASS: " + message if ok else "FAIL: " + message)
	if not ok:
		_failures += 1
