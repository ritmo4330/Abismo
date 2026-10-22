extends SceneTree

var failures := 0
var flow: Node
var data: Node
var dialogic: Node
var manager: Node
var host: Node2D
var spoken: Array[String] = []
var received_signals: Array[String] = []

func _initialize() -> void:
	create_timer(320, true, false, true).timeout.connect(func() -> void:
		push_error("Source fidelity test timed out")
		quit(1))
	call_deferred("run")

func _process(_delta: float) -> bool:
	var speed := root.get_node_or_null("TextSpeedManager")
	if speed: speed._hold_acceleration = true
	return false

func run() -> void:
	flow = root.get_node("FlowManager")
	data = root.get_node("DataManager")
	dialogic = root.get_node("Dialogic")
	manager = root.get_node("SceneManager")
	var part := "load"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--part="): part = argument.trim_prefix("--part=")
	# Keep actual play groups separate from the bulk preprocessing diagnostic.
	# The latter reproduces a native shutdown crash even without playing a scene.
	if part in ["load", "preprocess"]:
		await validate_all_timelines("res://assets/dialogues", part == "preprocess")
		print("Source fidelity ", part, " validation finished. failures=", failures)
		quit(0 if failures == 0 else 1)
		return
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	host = Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	host.add_child(load("res://scenes/UI/clue_panel.tscn").instantiate())
	flow.apply_flow_state("ch1_snow_villa", "ch1_3_intro_hall")
	manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await create_timer(0.5).timeout
	# Exercise actual Dialogic choices but do not leave the isolated test scene.
	var bus: Node = root.get_node("EventBus")
	bus.flow_signal_requested.disconnect(flow._on_flow_signal_requested)
	bus.flow_signal_requested.connect(func(id: String) -> void: received_signals.append(id))
	dialogic.Text.about_to_show_text.connect(func(info: Dictionary) -> void: spoken.append(String(info.text)))
	match part:
		"novel":
			start("1_1_puzzle_story")
			await idle()
			check(not data.has_clue("1_puzzle_x_impossible_2"), "Reading the novel does not prematurely grant summary clues")
			check(not "\n".join(spoken).contains("X站出来"), "Removed incorrect X action is never played")
		"orders": await validate_orders()
		"arrivals": await validate_arrivals()
		"hall": await validate_hall_responses()
		"gender": await validate_gender()
		"accusation": await validate_accusation_confirmation()
		"routes":
			await validate_route_menus()
			validate_perfect_gate()
		"scene":
			start("1_7_all")
			await idle()
			check(manager.get_static_art_view() == "storeroom", "Second search actually gathers in the storeroom view")
			check("\n".join(spoken).contains("周先生似乎有一些急于调查的东西"), "Zhou enters the trapdoor first per user decision")
			check(not "\n".join(spoken).contains("确认前方是否安全"), "Unsupported player speech is removed")
		_: check(false, "Unknown test part: " + part)
	# Release the live layout before shutting down the loaded resource graph.
	await dialogic.end_timeline(true)
	await process_frame
	print("Source fidelity ", part, " validation finished. failures=", failures)
	quit(0 if failures == 0 else 1)

func validate_all_timelines(folder: String, preprocess := false) -> void:
	for directory: String in DirAccess.get_directories_at(folder):
		await validate_all_timelines(folder.path_join(directory), preprocess)
	for file: String in DirAccess.get_files_at(folder):
		if not file.ends_with(".dtl"): continue
		var timeline: Resource = load(folder.path_join(file))
		check(timeline != null, "Timeline loads: " + file)
		if timeline != null and preprocess:
			timeline.process()
			# The production engine cleans each played timeline asynchronously.
			# Keep that lifecycle in bulk parse tests instead of releasing an
			# entire processed graph during native engine shutdown.
			await timeline.clean()
			timeline.events.clear()

func validate_orders() -> void:
	for turn: int in [1, 2, 3]:
		flow.reset_gameplay_runtime()
		for npc: String in ["Mu", "Zhou", "Lin", "Wu", "Zhong"]:
			for i: int in [1, 2, 3]: flow.set_dialogic_var("Ch1.NPCIntro.%s.Selected%d" % [npc, i], true)
		flow.set_dialogic_var("PlayerGender", "female")
		flow.set_dialogic_var("PlayerName", "测试")
		start("1_3_butler")
		await choose("准备好了")
		await question("我先去吧")
		check(choices().has("我第二个") and choices().has("我第三个"), "All three original search-order choices are selectable")
		await choose(["我先去吧", "我第二个", "我第三个"][turn - 1])
		await idle()
		check(int(flow.get_dialogic_var("Ch1.InitialSearch.PlayerTurn", 0)) == turn, "Chosen search position persists: " + str(turn))
		var id := "1_initial_search_order_" + str(turn)
		check(data.has_clue(id), "Corresponding order is recorded in the casebook: " + str(turn))
		check(data.get_clue_def(id).description == String(flow.get_dialogic_var("Ch1.InitialSearch.Order", "")), "Casebook order matches the selected narrative")
		check(received_signals.has("start_initial_search"), "Each order continues into the normal investigation")

func validate_arrivals() -> void:
	flow.reset_gameplay_runtime()
	for npc: String in ["zhou", "lin", "wu", "zhong"]:
		start("1_6_" + npc)
		await question("来到别墅的原因")
		if npc == "wu": check(not choices().has("关于异测会"), "Wu's society topic waits for the private arrival question")
		await choose("来到别墅的原因")
		await question("与死者的关系")
		check(bool(flow.get_dialogic_var("Ch1.PrivateChat.%s.Asked.Arrival" % npc.capitalize(), false)), "Arrival question records only the selected NPC: " + npc)
		if npc == "wu": check(choices().has("关于异测会"), "Wu's society topic opens after the correct source prerequisite")
		await stop()
		for path: String in ["ch2_deepening/2_2_", "ch2_deepening/2_5_", "ch3_transcend/3_source_"]:
			check(FileAccess.get_file_as_string("res://assets/dialogues/" + path + npc + ".dtl").contains("- 来到别墅的原因"), "Later rounds retain arrival question: " + path + npc)

func validate_hall_responses() -> void:
	for spec: Array in [["mu", "乐意效劳。"], ["zhou", "嗯，请便。"], ["lin", "好，我会配合的。"], ["wu", "好，我们走吧。"], ["zhong", "嗯。"]]:
		start("2_2_" + spec[0] + "_hall")
		await choose("邀请私聊")
		await idle()
		check(spoken == [spec[1]], "Invitation plays only the authored acceptance: " + spec[0])
		check(received_signals.has("enter_private_chat"), "Invitation still enters private chat: " + spec[0])

func validate_gender() -> void:
	for gender: String in ["female", "male", "unspecified"]:
		flow.set_dialogic_var("Ch1.NPCIntro.Mu.Introed", false)
		flow.set_dialogic_var("PlayerGender", gender)
		flow.set_dialogic_var("PlayerName", "测试")
		start("1_3_mu")
		await choose("我叫测试")
		await question("自我介绍")
		var expected := {"female": "好的，测试女士。", "male": "好的，测试先生。", "unspecified": "好的，测试。"}
		check(spoken.has(expected[gender]), "Mu uses the selected gender's address: " + gender)
		await stop()

func validate_route_menus() -> void:
	for route: String in ["Correction", "Resistance", "Transcend"]:
		flow.reset_gameplay_runtime()
		flow.apply_flow_state("ch3_transcend", "ch3_4_route")
		flow.set_dialogic_var("Ch3.Route." + route, true)
		for id: String in ["3_study_darkroom_1", "3_study_darkroom_4", "3_study_darkroom_2"]:
			data.add_clue(id, "test", "source_fidelity")
		start("3_source_wu")
		await choose("关于全家福")
		await question("暂时没有问题了")
		check(choices().has("与死者的关系"), "Late Wu retains earlier private topics: " + route)
		if route == "Correction":
			check(choices().has("关于笔记本") and not choices().has("关于房间内的其它线索"), "Correction uses the notebook-first structure")
			await choose("关于笔记本")
			await question("关于房间内的其它线索")
			check("\n".join(spoken).contains("我不来自任何一个平行世界"), "Correction plays its own notebook disclosure")
		else:
			check(choices().has("关于房间内的其它线索") and not choices().has("关于笔记本"), "Non-correction opens room clues after the photo, without the notebook gate")
		await choose("关于房间内的其它线索")
		await question("关于报纸")
		if route != "Correction":
			check(choices().has("关于笔记本"), "Figure 38 nests the notebook inside room clues")
			await choose("关于笔记本")
			await question("关于报纸")
			check("\n".join(spoken).contains("这就是我说过的那段经历"), "Non-correction plays its own notebook text")
		await choose("关于报纸")
		await choose("箱庭计划是什么？")
		await question("解构学是什么？")
		check(not choices().has("箱庭计划是什么？"), "Asked newspaper follow-up is removed without removing the other question")
		await choose("解构学是什么？")
		await question("暂时没有问题了")
		check("\n".join(spoken).contains("似乎没有可以询问的线索"), "Empty room topics return safely to the main menu")
		await stop()
		data.add_suspicion("3_suspicion_god_weapon", "test", "source_fidelity")
		data.resolve_suspicion("3_suspicion_god_weapon")
		start("3_source_zhong")
		await question("暂时没有问题了")
		check(choices().has("关于建构师") == (route != "Correction"), "Architect identity is gated by route: " + route)
		check(choices().has("我找到武器了") == (route != "Correction"), "Even a resolved weapon clue cannot expose handover on Correction: " + route)
		await stop()

func validate_accusation_confirmation() -> void:
	flow.set_dialogic_var("Ch3.Route.Started", true)
	for timeline: String in ["2_2_butler_hall", "3_source_butler"]:
		start(timeline)
		await choose("指认凶手")
		await choose("是的")
		await choose("穆执")
		await choose("确定")
		await idle()
		check(spoken.back() == "好的，我明白了。", "Accusation ends with the exact source confirmation: " + timeline)
		check(received_signals.has("source_accusation"), "Source confirmation continues to the existing accusation flow")

func validate_perfect_gate() -> void:
	for npc: String in ["Mu", "Zhou", "Lin", "Zhong"]: flow.set_dialogic_var("Ch3.NightmareRecall." + npc, true)
	for fact: String in ["mu_correct_recognition", "world_truth_solved"]: data.set_flag("source_plot/" + fact, true)
	flow.set_dialogic_var("SourcePlot.ZhongArchitect", true)
	flow.set_dialogic_var("Ch2.SecondPrivate.Lin.RememberedQuote", true)
	flow.set_dialogic_var("Ch2.SecondPrivate.Zhou.Shijin", true)
	flow.set_dialogic_var("Ch2.AccusedKiller", "穆执")
	flow.prepare_source_endings()
	check(not bool(flow.get_dialogic_var("SourcePlot.PerfectReady", false)), "Asking about the architect cannot fabricate Zhong's reconciliation")
	data.set_flag("source_plot/zhong_reconciled", true)
	flow.prepare_source_endings()
	check(bool(flow.get_dialogic_var("SourcePlot.PerfectReady", false)), "Complete explicit facts satisfy the gate in an isolated unit test")
	data.set_flag("source_plot/mu_correct_recognition", false)
	flow.prepare_source_endings()
	check(not bool(flow.get_dialogic_var("SourcePlot.PerfectReady", false)), "Unwritten Mu recognition is never granted automatically")

func start(timeline: String) -> void:
	spoken.clear()
	received_signals.clear()
	root.get_node("EventBus").dialogue_requested.emit(timeline)

func choices() -> Array[String]:
	var result: Array[String] = []
	for choice: Dictionary in dialogic.Choices.get_current_question_info().get("choices", []):
		if bool(choice.get("visible", false)) and not bool(choice.get("disabled", true)): result.append(String(choice.text))
	return result

func question(expected: String) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if dialogic.current_state == DialogicGameHandler.States.AWAITING_CHOICE and choices().has(expected):
			await create_timer(0.8, true, false, true).timeout
			return
	check(false, "Expected choice: " + expected + "; actual=" + str(choices()))

func choose(text: String) -> void:
	await question(text)
	for choice: Dictionary in dialogic.Choices.get_current_question_info().get("choices", []):
		if String(choice.text) == text and bool(choice.get("visible", false)) and not bool(choice.get("disabled", true)):
			dialogic.Choices._on_choice_selected(choice)
			await create_timer(0.5, true, false, true).timeout
			return
	check(false, "Selectable option: " + text)

func idle() -> void:
	var deadline := Time.get_ticks_msec() + 18000
	await process_frame
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if dialogic.current_timeline == null and not root.get_node("DialogueManager")._is_dialogue_active:
			await create_timer(0.2).timeout
			return
	check(false, "Timeline finishes")

func stop() -> void:
	await dialogic.end_timeline(true)
	await idle()

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
