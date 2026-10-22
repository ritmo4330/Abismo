extends SceneTree

const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
var failures := 0
var flow: Node
var dialogic: Node
var accelerate := true

func _process(_delta: float) -> bool:
	root.get_node("TextSpeedManager")._hold_acceleration = accelerate
	return false

func _initialize() -> void:
	create_timer(95, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	flow = root.get_node("FlowManager")
	dialogic = root.get_node("Dialogic")
	var manager: Node = root.get_node("SceneManager")
	var data: Node = root.get_node("DataManager")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	var nav: Node = load("res://scripts/UI/static_investigation_ui.gd").new()
	host.add_child(nav)
	flow.apply_flow_state("ch1_snow_villa", "ch1_6_private_chat")
	manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await frames()
	flow.apply_flow_state("ch1_snow_villa", "ch1_6_private_chat")
	await frames()
	nav._refresh_navigation()
	var hub: Node = nav._casebook
	var seen: Dictionary = {}
	for index: int in 16:
		hub.show_home()
		seen[hub._preview_id] = true
		check(hub._preview_id != "butler" and hub._portrait_candidates().has(hub._preview_id), "Hall menu selects a present guest")
	check(seen.size() > 1, "Reopening the hall menu randomizes guest portraits")
	await snapshot("doc-hall-context.png")
	flow.apply_flow_state("ch1_snow_villa", "ch1_1_puzzle")
	nav._refresh_navigation()
	check(hub._preview_id.is_empty() and not hub._portrait.visible and not hub._portrait_shadow.visible, "Study puzzle clears even a stale hall portrait")
	hub.preview_character("butler")
	check(not hub._portrait.visible, "Hover cannot reintroduce the absent butler in a novel puzzle")
	await snapshot("doc-novel-no-portrait.png")
	flow.apply_flow_state("ch1_snow_villa", "ch1_6_private_chat")
	manager.restore_static_art_view("kitchen")
	nav._refresh_navigation()
	check(hub._preview_id.is_empty(), "An empty service room never borrows hall portraits")
	manager.restore_static_art_view("hall")
	flow.apply_flow_state("ch2_deepening", "ch2_1_second_reasoning")
	flow.set_dialogic_var("Affinity.Zhong", 45)
	root.get_node("TextSpeedManager")._hold_acceleration = true
	root.get_node("EventBus").dialogue_requested.emit("2_1_second_reasoning")
	await question("穆执的世界")
	check(dialogic.Choices.get_current_question_info().choices.size() == 6, "Choice 19 restores all six original world-origin branches")
	await choose("穆执的世界")
	await choose("不确定")
	await question("穆执的世界")
	check(dialogic.Choices.get_current_question_info().choices.size() == 6, "Uncertain answer returns to world-origin selection")
	await choose("钟歧的世界")
	var deadline := Time.get_ticks_msec() + 16000
	while dialogic.current_timeline != null and Time.get_ticks_msec() < deadline: await process_frame
	check(flow.get_current_step_id() == "ch2_2_second_private_chat", "Original discussion still enables second private chats")
	check(int(flow.get_dialogic_var("Affinity.Zhong", 0)) == 50, "Original Zhong origin branch grants exactly five trust")
	check(data.has_clue("2_parallel_world_rules"), "Original parallel-world law testimony is recorded")
	for id: String in ["2_suspicion_dream_space", "2_suspicion_parallel_worlds"]:
		check(data.has_suspicion(id), "Discussion records " + id)
	var wake := FileAccess.get_file_as_string("res://assets/dialogues/ch1_snow_villa/1_1_study_wake.dtl")
	check(wake.contains("是的，请先允许我做个自我介绍。") and not wake.contains("如你所见我是一名"), "Document point seven replaces the actual butler dialogue")
	check(not wake.contains("您"), "Butler consistently addresses the player as 你")
	var poem := FileAccess.get_file_as_string("res://assets/dialogues/ch0_prologue/0_2_villa_gate_story.dtl")
	var text_lines := 0
	for line: String in poem.split("\n"):
		if not line.strip_edges().is_empty() and not line.begins_with("["): text_lines += 1
	check(text_lines == 1, "Document point five is one continuous text event")
	check(poem.count("[br][br]") == 3 and poem.count("[br]") == 13, "The single performance preserves the four approved stanzas and eleven text lines")
	var curtain_config: Dictionary = load("res://scripts/scenes/static_room_art.gd").get_config("room_meta")
	check(curtain_config.asset == "meta_room_curtains" and ResourceLoader.exists("res://assets/art/static_scenes/meta_room_curtains-v1.png"), "Meta curtain correction is connected to the actual room")
	var title_scene: Node = load("res://scenes/chapter_titles/prologue_title.tscn").instantiate()
	check(title_scene.title_text.is_empty(), "Prologue title omits the unwanted subtitle")
	title_scene.free()
	# timeline.clean() yields before DialogueManager releases its active flag.
	deadline = Time.get_ticks_msec() + 5000
	while (root.get_node("DialogueManager")._is_dialogue_active or manager.is_transitioning) and Time.get_ticks_msec() < deadline:
		await process_frame
	await frames()
	accelerate = false
	root.get_node("TextSpeedManager")._hold_acceleration = false
	root.get_node("EventBus").dialogue_requested.emit("0_2_villa_gate_story")
	deadline = Time.get_ticks_msec() + 7000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if str(dialogic.current_state_info.get("text", "")).contains("她们彼此相伴而行"): break
	dialogic.Text.skip_text_reveal()
	await frames()
	check(str(dialogic.current_state_info.get("text", "")).contains("再度起行") and str(dialogic.current_state_info.get("text", "")).contains("她们彼此相伴而行"), "Entire poem is present together in the running textbox")
	for node: Node in get_nodes_in_group("dialogic_dialog_text"):
		if node.is_visible_in_tree(): check(node.get_content_height() < root.get_visible_rect().size.y - 100, "Continuous paragraph fits the screen")
	for node: Node in root.find_children("TextboxHistoryButton", "Button", true, false):
		check(not node.is_visible_in_tree(), "Full-screen paragraph never shows the dialogue hourglass")
	await snapshot("doc-poem-one-paragraph.png")
	await dialogic.end_timeline(true)
	print("Change document regression failures=", failures)
	quit(0 if failures == 0 else 1)

func question(text: String) -> void:
	var deadline := Time.get_ticks_msec() + 25000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if dialogic.current_state != DialogicGameHandler.States.AWAITING_CHOICE: continue
		for choice: Dictionary in dialogic.Choices.get_current_question_info().get("choices", []):
			if str(choice.text) == text:
				await create_timer(0.8, true, false, true).timeout
				return
	check(false, "Choice reached: " + text)

func choose(text: String) -> void:
	await question(text)
	for button: Node in get_nodes_in_group("dialogic_choice_button"):
		if button.is_visible_in_tree() and button.text == text and not button.disabled:
			var motion := InputEventMouseMotion.new()
			motion.position = button.get_global_rect().get_center()
			root.push_input(motion, true)
			var click := InputEventMouseButton.new()
			click.position = motion.position
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			root.push_input(click, true)
			await process_frame
			click = click.duplicate()
			click.pressed = false
			root.push_input(click, true)
			return
	check(false, "Clickable option: " + text)

func frames() -> void:
	await process_frame
	await process_frame
	await process_frame

func snapshot(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + name)

func check(ok: bool, description: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + description)
	if not ok: failures += 1
