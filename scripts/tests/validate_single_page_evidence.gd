extends SceneTree

const Catalog = preload("res://scripts/data/evidence_card_catalog.gd")
const Reader = preload("res://scripts/UI/evidence_card_browser.gd")
const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
var failures := 0
var tested := 0

func _initialize() -> void:
	create_timer(180, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	var data = root.get_node("DataManager")
	var flow = root.get_node("FlowManager")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	flow.apply_flow_state("ch1_snow_villa", "ch1_6_private_chat")
	for id: String in data._registry._clue_defs:
		data.add_clue(id, "test", "single-page")
	var reader := Reader.new()
	root.add_child(reader)
	reader.open()
	var pages: Array[Dictionary] = reader.cards.duplicate(true)
	var whitespace := RegEx.new()
	whitespace.compile("\\s+")
	if OS.get_cmdline_user_args().has("--capture-only"):
		pages = pages.filter(func(card: Dictionary) -> bool: return card.id in ["1_testimony_3_all/1", "1_testimony_4_all", "3_study_darkroom_4", "2_wu_dream_notes"])
	for resolution: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = resolution
		root.content_scale_size = resolution
		await process_frame
		reader._layout()
		var smallest := 100
		var smallest_id := ""
		for card: Dictionary in pages:
			reader._select(card.id)
			await fitted(reader)
			tested += 1
			var height: float = reader.content.get_combined_minimum_size().y
			if height > reader.reading_area.size.y + 1:
				check(false, "%s overflows %s: %.1f / %.1f at font %d" % [card.id, resolution, height, reader.reading_area.size.y, reader.fitted_font_size])
			var rendered: PackedStringArray = []
			for label: Control in reader._reading_labels:
				if label is RichTextLabel:
					rendered.append(label.text)
					check(not label.scroll_active and label.get_content_height() <= label.size.y + 1, "Text is clipped: " + card.id, false)
					check(label.get_global_rect().end.x <= reader.reading_area.get_global_rect().end.x + 1, "Text exceeds page width: " + card.id, false)
			check(whitespace.sub("\n\n".join(rendered), "", true) == whitespace.sub("\n\n".join(card.paragraphs), "", true), "Rendered text differs from source: " + card.id, false)
			if reader.fitted_font_size < smallest:
				smallest = reader.fitted_font_size
				smallest_id = card.id
			if OS.get_cmdline_user_args().has("--capture-only") and card.id == "3_study_darkroom_4":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUTPUT + "single-page-long-note-%dx%d.png" % [resolution.x, resolution.y])
		print("Measured pages=", pages.size(), " resolution=", resolution, " smallest font=", smallest, " card=", smallest_id)
		reader._select("1_testimony_3_all/1")
		await fitted(reader)
		check(reader.fitted_font_size >= 22, "Ordinary testimony retains readable text at " + str(resolution))
		if OS.get_cmdline_user_args().has("--capture"):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUTPUT + "single-page-testimony-%dx%d.png" % [resolution.x, resolution.y])
	# A pending older fit must not overwrite a newly selected card.
	reader._select("3_study_darkroom_4")
	reader._select("1_testimony_3_all/0")
	await fitted(reader)
	check(reader.selected_id == "1_testimony_3_all/0" and reader.content.modulate.a == 1, "Rapid card changes display the final card")
	var small_font: int = reader.fitted_font_size
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	reader._layout()
	await fitted(reader)
	check(reader.fitted_font_size >= small_font and reader.content.get_combined_minimum_size().y <= reader.reading_area.size.y + 1, "Resizing reflows the same card without overflow")
	check(not reader.reading_area is ScrollContainer, "Reading page has no scrolling container")
	reader.queue_free()
	print("Single-page evidence tested=", tested, " failures=", failures)
	quit(0 if failures == 0 else 1)

func fitted(reader: CanvasLayer) -> void:
	for i: int in range(120):
		await process_frame
		if reader.is_page_fitted(): return
	check(false, "Page layout did not settle")

func check(ok: bool, message: String, verbose := true) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)
	elif verbose:
		print("PASS: ", message)
