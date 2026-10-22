extends SceneTree

const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
const ORIGINAL := "再度起行，哪怕终点遥不可及，周而复始的生命，汇成聚沙成塔的权柄。依然会有灯笼鱼为她点亮光明，“我见过你吗？”“我想没有。”她继续着她的独行。依然会有章鱼嘲弄她的决定，“我见过你吗？”“怎么可能？”她继续着她的笃行。依然会有水母与她同行，“我见过你吗？”“应该没有吧。”她们彼此相伴而行。"
var failures := 0

func _initialize() -> void:
	create_timer(35.0).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1

func run() -> void:
	var flow: Node = root.get_node("FlowManager")
	var dialogic: Node = root.get_node("Dialogic")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	var timeline: Resource = load("res://assets/dialogues/ch0_prologue/0_2_villa_gate_story.dtl")
	timeline.process()
	var count := 0
	for event: Resource in timeline.events:
		if "text" in event:
			count += 1
			check(String(event.text).replace("[br]", "") == ORIGINAL, "Poem retains every authored character")
			check(String(event.text).count("[br][br]") == 3, "Four stanzas share one text event")
	check(count == 1, "The poem requires only one performance, not eleven clicks")
	root.get_node("EventBus").dialogue_requested.emit("0_2_villa_gate_story")
	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if String(dialogic.current_state_info.get("text", "")).contains("她们彼此相伴而行"): break
	check(String(dialogic.current_state_info.get("text", "")).contains("她们彼此相伴而行"), "Poem reaches the actual dialogue display")
	dialogic.Text.skip_text_reveal()
	await create_timer(0.4).timeout
	for size: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = size
		await create_timer(0.3).timeout
		var visible_textboxes := 0
		for node: Node in get_nodes_in_group("dialogic_dialog_text"):
			if not node.is_visible_in_tree(): continue
			visible_textboxes += 1
			check(node.get_parsed_text().replace("\n", "") == ORIGINAL, "All four stanzas are simultaneously visible at " + str(size))
			var rect: Rect2 = node.get_global_rect()
			check(node.get_content_height() <= 820 and rect.position.y >= 20 and rect.end.y <= root.get_visible_rect().size.y - 20, "Poem fits vertically without clipping at " + str(size))
		check(visible_textboxes == 1, "Exactly one visible poem textbox at " + str(size))
		if OS.get_cmdline_user_args().has("--capture"):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUTPUT + "prologue-four-stanzas-" + str(size.x) + ".png")
	await dialogic.end_timeline(true)
	print("Poem layout failures=", failures)
	quit(1 if failures else 0)
