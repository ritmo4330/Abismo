extends SceneTree

const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
var failures := 0
var flow: Node
var data: Node
var dialogic: Node
var host: Node2D
var manager: Node
var nav: Node

func _initialize() -> void:
	create_timer(200.0, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func _process(_delta: float) -> bool:
	root.get_node("TextSpeedManager")._hold_acceleration = true
	return false

func run() -> void:
	flow = root.get_node("FlowManager")
	data = root.get_node("DataManager")
	dialogic = root.get_node("Dialogic")
	manager = root.get_node("SceneManager")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	host = Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	nav = load("res://scripts/UI/static_investigation_ui.gd").new()
	host.add_child(nav)
	host.add_child(load("res://scenes/UI/clue_panel.tscn").instantiate())
	host.add_child(load("res://scenes/UI/suspicion_panel.tscn").instantiate())
	flow.apply_flow_state("ch2_deepening", "ch2_2_second_private_chat")
	manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await create_timer(0.4).timeout
	flow.set_dialogic_var("Affinity.Mu", 50)
	start("2_2_mu")
	await choose("储物间暗门下的东西")
	await question()
	check(not data.has_flag("source_research/mu"), "Neutral Mu keeps research-site evidence private")
	flow.set_dialogic_var("Affinity.Mu", 80)
	await choose("储物间暗门下的东西")
	await question()
	check(data.has_clue("3_mei_4") and data.has_flag("source_research/mu"), "Trusted Mu shares source research evidence")
	check(not data.has_clue("3_zhou_5"), "Mu disclosure does not expose Zhou's research site")
	await choose("暂时没有问题了")
	await idle()
	flow.set_dialogic_var("Affinity.Zhou", 80)
	start("2_2_zhou")
	await choose("储物间暗门下的东西")
	await choose("关于研究所内的线索")
	await choose("关于实验床上的女子")
	await choose("关于梦境规则")
	await question()
	check(choices().has("关于时今的死"), "Shijin's story requires both prior research questions")
	await choose("关于时今的死")
	await question()
	check(choices().has("关于研究所储物间的装置"), "Device question opens after Shijin's story")
	await choose("关于研究所储物间的装置")
	await choose("还有其他问题")
	await choose("暂时没有问题了")
	await idle()
	flow.apply_flow_state("ch2_deepening", "ch2_5_third_private_chat")
	flow.set_dialogic_var("Affinity.Mu", 80)
	for id: String in ["2_mu_2", "2_mu_1_8", "2_mu_1_9", "2_mu_1_10", "2_mu_3"]:
		data.add_clue(id, "test", "source")
	start("2_5_mu")
	for text: String in ["关于衣柜中的长袍", "关于教义复古运动", "关于先知伊斯", "关于笔记本的内容", "关于报纸头条的事故", "关于林羽的信", "暂时没有问题了"]:
		await choose(text)
		print("MU_TOPIC: ", text, " affinity=", flow.get_dialogic_var("Affinity.Mu", 0))
	await idle()
	check(int(flow.get_dialogic_var("Affinity.Mu", 0)) == 95, "Only the three source-marked Mu topics add affinity; actual=" + str(flow.get_dialogic_var("Affinity.Mu", 0)))
	data.add_clue("2_lin_2", "test", "source")
	flow.set_dialogic_var("Affinity.Lin", 50)
	start("2_5_lin")
	await choose("关于贴有封条的门")
	await question()
	check(not bool(flow.get_dialogic_var("Ch2.ThirdPrivate.Lin.DoorStarted", false)), "Untrusted Lin is not forced through her memory door")
	flow.set_dialogic_var("Affinity.Lin", 80)
	await choose("关于贴有封条的门")
	await choose("当然")
	await choose("暂时没有问题了")
	await idle()
	check(bool(flow.get_dialogic_var("Ch2.ThirdPrivate.Lin.DoorReady", false)), "Lin's follow-up waits until leaving the conversation")
	start("2_5_lin")
	await choose("关于调查结果")
	await question()
	check(data.has_clue("2_lin_5_11") and data.has_clue("2_lin_6_26"), "Lin shares the inaccessible childhood-home clues herself")
	await choose("暂时没有问题了")
	await idle()
	await validate_spaces()
	await validate_password()
	await validate_third_discussion()
	for npc: String in ["Mu", "Zhou", "Lin", "Wu", "Zhong"]:
		flow.set_dialogic_var("Ch2.ThirdPrivate.%s.Finished" % npc, true)
	flow.refresh_derived_progress()
	check(not bool(flow.get_dialogic_var("Ch2.ContentComplete.Ready", false)), "Talking to five people cannot fabricate completed memories")
	print("Source private validation finished. failures=", failures)
	quit(0 if failures == 0 else 1)

func validate_spaces() -> void:
	flow.apply_flow_state("ch2_deepening", "ch2_3_third_search")
	data.set_flag("subconscious_entered/room_mu_zhi", true)
	manager._on_scene_change_requested("res://scenes/rooms/room_mu_zhi.tscn", "InitialSpawn")
	await create_timer(0.6).timeout
	while manager.is_transitioning: await process_frame
	var art: Node = manager.current_room.get_node("StaticRoomArt")
	check(art.current_view == "villa", "Entering a bedroom starts in the physical villa")
	var physical: Array[String] = []
	var subconscious: Array[String] = []
	for item: Node in art.get_hotspot_items():
		if item.get("clue_id") is String and item.is_visible_in_tree(): physical.append(item.clue_id)
	art.set_view("subconscious")
	for item: Node in art.get_hotspot_items():
		if item.get("clue_id") is String and item.is_visible_in_tree(): subconscious.append(item.clue_id)
	check(physical.has("1_mu_1") and not physical.has("2_mu_1"), "Physical room does not display subconscious clues")
	check(subconscious.has("2_mu_1") and not subconscious.has("1_mu_1"), "Subconscious room does not display physical clues")
	check(not subconscious.has("2_mu_burnt_church"), "Fabricated charred-church clue is not spawned")
	nav._refresh_navigation()
	nav._casebook.open_map()
	check(nav._casebook._space_toggle.visible and not nav._casebook._space_toggle.disabled, "Chapter-two map exposes the subconscious browser")
	nav._casebook._toggle_map_space()
	check(nav._casebook._dream_locations.visible and not nav._casebook._floor_plan.visible, "Subconscious map is separate from the villa floor plan")
	await snapshot("source-subconscious-map.png")
	nav._casebook.close_map()
	art.set_view("villa")

func validate_password() -> void:
	check(not String(data.get_clue_def("2_wu_2").description).contains("老师"), "Locked notebook does not leak its contents")
	for password: String in ["0000", "0909"]:
		start("2_3_notebook_password")
		var deadline := Time.get_ticks_msec() + 8000
		while Time.get_ticks_msec() < deadline:
			await process_frame
			if dialogic.TextInput.input_confirmed.get_connections().size() > 0: break
		dialogic.TextInput.input_confirmed.emit(password)
		await idle()
		check(data.has_flag("source_notebook/unlocked") == (password == "0909"), "Password " + password + " has the source-defined result")
	check(data.has_flag("source_notebook/early_unlock") and data.has_clue("2_wu_dream_notes"), "Correct early password records the hidden memory and actual notebook")

func validate_third_discussion() -> void:
	flow.apply_flow_state("ch2_deepening", "ch2_4_third_reasoning")
	flow.set_dialogic_var("Ch2.ThirdSearch.BodyKnownBeforeTurn", true)
	manager._on_scene_change_requested("res://scenes/rooms/hall.tscn", "InitialSpawn")
	await create_timer(0.6).timeout
	while manager.is_transitioning: await process_frame
	start("2_4_third_reasoning")
	await choose("可以")
	await idle()
	check(bool(flow.get_dialogic_var("Ch2.MemoryFragments.Door", false)), "Choice 21 retains Wu's already-recreated door memory")
	check(data.has_suspicion("3_suspicion_memory_flower") and data.has_suspicion("3_suspicion_memory_cube"), "Choice 21 opens only the two remaining source reconstruction questions")
	check(flow.get_current_step_id() == "ch2_5_third_private_chat", "Source discussion opens free investigation without auto-completing memories")

func start(timeline: String) -> void:
	root.get_node("EventBus").dialogue_requested.emit(timeline)

func choices() -> Array[String]:
	var result: Array[String] = []
	for choice: Dictionary in dialogic.Choices.get_current_question_info().get("choices", []):
		if bool(choice.get("visible", false)) and not bool(choice.get("disabled", true)): result.append(String(choice.text))
	return result

func question() -> void:
	var deadline := Time.get_ticks_msec() + 18000
	while Time.get_ticks_msec() < deadline:
		await pump()
		if dialogic.current_state == DialogicGameHandler.States.AWAITING_CHOICE:
			await create_timer(0.8, true, false, true).timeout
			return
	check(false, "Reached a source question")

func choose(text: String) -> void:
	await question()
	for choice: Dictionary in dialogic.Choices.get_current_question_info().get("choices", []):
		if String(choice.text) == text and bool(choice.get("visible", false)) and not bool(choice.get("disabled", true)):
			dialogic.Choices._on_choice_selected(choice)
			await process_frame
			return
	check(false, "Source choice exists: " + text + "; visible=" + str(choices()))

func idle() -> void:
	var deadline := Time.get_ticks_msec() + 18000
	while Time.get_ticks_msec() < deadline:
		await pump()
		if dialogic.current_timeline == null and not root.get_node("DialogueManager")._is_dialogue_active and not manager.is_transitioning: return
	check(false, "Source timeline ended")

func pump() -> void:
	await process_frame
	var panel: Node = host.get_node("CluePanel")
	if panel._is_open:
		await snapshot("source-notebook-detail.png")
		panel._close_panel()

func snapshot(filename: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + filename)

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
