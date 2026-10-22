extends SceneTree

const Text = preload("res://scripts/flow/services/source_text.gd")
var failures := 0
var flow: Node
var data: Node
var dialogic: Node
var endings_done := false
var memory_events := 0
const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"

func _initialize() -> void:
	create_timer(160.0, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func _process(_delta: float) -> bool:
	var speed := root.get_node_or_null("TextSpeedManager")
	if speed: speed._hold_acceleration = true
	return false

func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failures += 1

func run() -> void:
	flow = root.get_node("FlowManager")
	data = root.get_node("DataManager")
	dialogic = root.get_node("Dialogic")
	var previous_slot: String = dialogic.Save.get_latest_slot()
	var saver: Node = root.get_node("SaveManager")
	saver.set_script(load("res://scripts/tests/isolated_test_save.gd"))
	saver.test_slot = "source_attachment_audit_" + str(Time.get_ticks_usec())
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	host.add_child(load("res://scenes/UI/clue_panel.tscn").instantiate())
	root.get_node("SceneManager").initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await create_timer(0.5).timeout
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/source_text/manifest.json"))
	check(manifest.size() == 20, "All twenty supplied source documents are recorded")
	check(Text.paragraphs("note_pages").size() == 7, "Six notebook fragments preserve their original paragraphs")
	for npc: String in ["mu", "zhou", "lin", "zhong"]:
		check(data.get_clue_def("source_nightmare_" + npc) != null, "Authored nightmare registered: " + npc)
	data.set_flag("source_notebook/underlined", false)
	check(not Text.notebook_body().contains("[u]"), "Early password reading has no later underlines")
	data.set_flag("source_notebook/underlined", true)
	check(Text.notebook_body().count("[u]") == 3, "Exactly three DOCX underlined passages retained")
	check(data.get_clue_def("3_mei_1").description.contains("梦境规则其八"), "Meta's eighth rule is retained")
	check(not data.get_clue_def("3_zhou_1").description.contains("梦境规则其八"), "Zhou's seven-rule document remains separate")
	for folder: String in ["res://assets/dialogues/finale/source", "res://assets/dialogues/source", "res://assets/dialogues/ch3_transcend", "res://assets/dialogues/ch2_deepening"]:
		for file: String in DirAccess.get_files_at(folder):
			if not file.ends_with(".dtl"): continue
			var timeline: Resource = load(folder.path_join(file))
			timeline.process()
			check(not timeline.events.is_empty(), "Timeline parses: " + file)
	for npc: String in ["mu", "zhou", "lin", "zhong"]:
		check(Text.character_ending(npc) == "forget", "Unknown nightmare does not force death: " + npc)
		data.set_flag("source_plot/reported_" + npc, true)
		check(Text.character_ending(npc) == "death", "Reported nightmare affects individual ending: " + npc)
		data.set_flag("source_plot/reported_" + npc, false)
	data.set_flag("source_plot/mu_knows_nightmare_lin", true)
	check(Text.character_ending("lin") == "death", "Mu knowing a nightmare is distinct from the butler knowing it")
	data.set_flag("source_plot/mu_knows_reason_lin", true)
	check(Text.character_ending("lin") == "forget", "Knowing the chosen-person reason changes Mu's action")
	for spec: Array in [[20,false,"Correction"],[50,false,"Resistance"],[80,true,"Transcend"]]:
		for route: String in ["Correction", "Resistance", "Transcend"]: flow.set_dialogic_var("Ch3.Route." + route, false)
		flow.apply_flow_state("ch3_transcend", "ch3_4_route")
		flow.set_dialogic_var("Affinity.Wu", spec[0])
		flow.set_dialogic_var("Ch3.KeyDialogue.Freedom", spec[1])
		root.get_node("EventBus").dialogue_requested.emit("3_1_route")
		await idle()
		check(bool(flow.get_dialogic_var("Ch3.Route." + spec[2], false)), "Source route condition: " + spec[2])
		check(data.has_flag("source_plot/darkroom_open"), "Route sets the darkroom unlock after Wu's private conversation")
		await create_timer(0.35).timeout
	flow.set_dialogic_var("Ending.ClearSnow", true)
	for npc: String in ["mu", "zhou", "lin", "zhong", "wu", "player"]:
		check(Text.character_ending(npc) == "perfect", "Successful transcendence selects authored perfect ending: " + npc)
	var bus := root.get_node("EventBus")
	bus.flow_signal_requested.disconnect(flow._on_flow_signal_requested)
	bus.flow_signal_requested.connect(func(id: String) -> void:
		if id == "ending_finished": endings_done = true
		if id == "source_memory_recreated": memory_events += 1)
	flow.set_dialogic_var("Ch2.MemoryFragments.Flower", false)
	flow.set_dialogic_var("Ch2.MemoryFragments.Cube", false)
	bus.dialogue_requested.emit("source_recreate_flower")
	await choose("穆执")
	await question()
	check(not bool(flow.get_dialogic_var("Ch2.MemoryFragments.Flower", false)), "Wrong flower actor does not complete a memory")
	await choose("林玖")
	await idle()
	check(bool(flow.get_dialogic_var("Ch2.MemoryFragments.Flower", false)), "Lin recreates the flower-sea memory")
	await create_timer(0.35).timeout
	bus.dialogue_requested.emit("source_recreate_cube")
	await choose("周崇安")
	await question()
	check(not bool(flow.get_dialogic_var("Ch2.MemoryFragments.Cube", false)), "Older male actor does not complete the cube memory")
	await choose("林玖")
	await question()
	check(not bool(flow.get_dialogic_var("Ch2.MemoryFragments.Cube", false)), "Female actor does not complete the cube memory")
	await choose("穆执")
	await idle()
	check(bool(flow.get_dialogic_var("Ch2.MemoryFragments.Cube", false)) and memory_events == 2, "Young male actor completes the cube memory exactly once")
	await create_timer(0.35).timeout
	if OS.get_cmdline_user_args().has("--capture"):
		data.add_clue("2_wu_dream_notes", "test", "attachment")
		var panel: Node = host.get_node("CluePanel")
		panel._open_interaction_panel({"display_type":"single", "clue_ids":["2_wu_dream_notes"]}, true)
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT + "source-attachments-notebook.png")
		panel._close_panel()
	bus.dialogue_requested.emit("source_character_endings")
	await idle()
	check(endings_done, "All six authored endings return and reach the epilogue boundary")
	dialogic.Save.delete_slot(saver.test_slot + "_before_endings")
	dialogic.Save.set_latest_slot(previous_slot)
	print("Source attachment validation finished. failures=", failures)
	quit(1 if failures else 0)

func question() -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if dialogic.current_state == dialogic.States.AWAITING_CHOICE:
			await create_timer(0.8, true, false, true).timeout
			return
	check(false, "Reconstruction question became available")

func choose(text: String) -> void:
	await question()
	for choice: Dictionary in dialogic.Choices.get_current_question_info().get("choices", []):
		if String(choice.text) == text and bool(choice.get("visible", false)) and not bool(choice.get("disabled", true)):
			dialogic.Choices._on_choice_selected(choice)
			# Selection animation briefly leaves the previous choice state alive.
			await create_timer(0.5, true, false, true).timeout
			return
	check(false, "Reconstruction choice exists: " + text)

func idle() -> void:
	await process_frame
	for i in 15000:
		if dialogic.current_timeline == null:
			await create_timer(0.2).timeout
			return
		# Do not consume actual source choices during route introduction.
		if dialogic.current_state == dialogic.States.AWAITING_CHOICE:
			check(false, "Unexpected player choice in an NPC-selected route")
			dialogic.end_timeline()
			return
		await process_frame
	check(false, "Timeline did not finish")
