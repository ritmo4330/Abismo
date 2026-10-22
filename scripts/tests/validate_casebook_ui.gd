extends SceneTree

const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
var failures := 0

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	var flow: Node = root.get_node("FlowManager")
	var manager: Node = root.get_node("SceneManager")
	var data: Node = root.get_node("DataManager")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	for name: String in ["clue_panel", "suspicion_panel", "system_panel"]:
		host.add_child(load("res://scenes/UI/%s.tscn" % name).instantiate())
	var navigation: Node = load("res://scripts/UI/static_investigation_ui.gd").new()
	host.add_child(navigation)
	flow.apply_flow_state("ch1_snow_villa", "ch1_3_intro_hall")
	manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await create_timer(0.4).timeout
	var hub: Node = navigation._casebook
	check(navigation.visible and hub._actions.get_child_count() == 3, "Three investigation actions appear")
	check(navigation._npc_row.get_child_count() == 6, "All six original dialogue entries retained")
	check(hub._portrait.get_global_rect().end.x < hub._paper.get_global_rect().position.x, "Portrait stage stays clear of the newspaper")
	for id: String in ["mu", "zhou", "lin", "wu", "zhong", "butler"]:
		hub.preview_character(id)
		var texture_size: Vector2 = hub._portrait.texture.get_size()
		var portrait_size: Vector2 = hub._portrait.size
		var rendered_height := texture_size.y * minf(portrait_size.x / texture_size.x, portrait_size.y / texture_size.y)
		check(rendered_height >= 900 and rendered_height <= 931, "Consistent portrait height: " + id)
		check(hub._portrait_shadow.texture == hub._portrait.texture, "Portrait shadow follows selection: " + id)
		check(hub._portrait_name.text == ("管家" if id == "butler" else "？？？"), "Name card respects first introduction: " + id)
		if OS.get_cmdline_user_args().has("--portraits"):
			await create_timer(0.20).timeout
			await snapshot("casebook-portrait-" + id + ".png")
	await create_timer(0.20).timeout
	await snapshot("casebook-home.png")
	hub.show_dialogues()
	await process_frame
	await process_frame
	await snapshot("casebook-dialogues.png")
	check(hub._talk_scroll.visible, "Dialogue mode opens character cards")
	var last_card: Control = navigation._npc_row.get_child(navigation._npc_row.get_child_count() - 1)
	check(last_card.get_global_rect().end.y <= hub._talk_scroll.get_global_rect().end.y + 1, "All six dialogue ribbons fit without clipped portraits")
	hub.show_exploration()
	hub.open_map()
	await process_frame
	check(paused and navigation.visible and hub.map_open, "Map remains visible while world pauses")
	check(hub._destinations.is_empty(), "Initial interviews cannot bypass hall restriction")
	hub.close_map()
	check(not paused, "Map closes without retaining pause")
	var map_key := InputEventKey.new()
	map_key.keycode = KEY_M
	map_key.pressed = true
	hub._input(map_key)
	check(hub.map_open, "M opens the map")
	hub._input(map_key)
	check(not hub.map_open and not paused, "M closes the map and releases pause")
	hub.open_tasks()
	check(hub.map_open and hub._destinations.is_empty(), "Task book is read-only")
	await snapshot("casebook-task.png")
	hub.close_map()
	flow.apply_flow_state("ch1_snow_villa", "ch1_4_first_search")
	navigation._refresh_navigation()
	hub.open_map()
	await create_timer(0.2).timeout
	check(not hub._destinations.is_empty(), "Map uses existing exits")
	check(hub._destinations.has("room_mu_zhi") and hub._destinations.has("room_zhou_chong_an"), "Map enables non-adjacent reachable bedrooms")
	check(not hub._destinations.has("zhong_yue_lab"), "Map cannot bypass laboratory entrance story")
	check(hub.map_open and navigation._navigation_row.get_child_count() >= hub._destinations.size(), "Open map keeps the complete destination list during deferred refresh")
	check(hub._floor_plan.current_room == "hall" and hub._floor_plan.buttons.hall.text.begins_with("●"), "Map marks actual current location")
	await snapshot("casebook-map.png")
	if not hub._destinations.is_empty():
		var destination: String = "room_mu_zhi" if hub._destinations.has("room_mu_zhi") else String(hub._destinations.keys()[0])
		var room_button: Button = hub._floor_plan.buttons[destination]
		hub._floor_plan.show_floor(int(hub._floor_plan.ROOMS[destination][1]))
		await process_frame
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = room_button.get_global_rect().get_center()
		click.pressed = true
		var motion := InputEventMouseMotion.new()
		motion.position = click.position
		root.push_input(motion, true)
		root.push_input(click, true)
		await process_frame
		var release := click.duplicate() as InputEventMouseButton
		release.pressed = false
		root.push_input(release, true)
		await create_timer(2.0).timeout
		check(not hub.map_open and not paused, "Map travel releases modal pause")
		check(flow.get_current_room_id() == destination, "Mouse click on map reaches selected scene")
	flow.apply_flow_state("ch1_snow_villa", "ch1_1_puzzle")
	data.add_suspicion("1_suspicion_x_disability", "test", "casebook")
	var manual: Node = host.get_node("SuspicionPanel")
	manual._open_archive_panel()
	await create_timer(0.3).timeout
	check(manual.visible and manual.slot_row is HFlowContainer, "Book reasoning and wrapping evidence slots open")
	await snapshot("casebook-reasoning.png")
	manual._close_panel()
	for id: String in ["1_study_1", "1_study_2", "1_study_3"]: data.discover_clue(id, "test", "casebook")
	host.get_node("CluePanel")._open_archive_panel()
	await snapshot("casebook-evidence.png")
	host.get_node("CluePanel")._close_panel()
	flow.apply_flow_state("ch1_snow_villa", "ch1_4_first_search")
	navigation._refresh_navigation()
	hub.show_home()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await create_timer(0.3).timeout
	check(hub._paper.get_global_rect().end.x <= 1281, "Newspaper fits 1280x720")
	check(not hub._portrait.visible or hub._portrait.get_global_rect().end.x <= hub._paper.get_global_rect().position.x, "Portrait remains clear of menu at 1280x720")
	var notices: Node = root.get_node("ToastManager")
	notices.show_notice("线索已收录")
	await process_frame
	check(notices._panel.get_global_rect().size.x <= 400, "Compact notification fits small viewport")
	await snapshot("casebook-1280.png")
	hub.open_map()
	await create_timer(0.2).timeout
	var book: Control = hub.find_child("VillaMapBook", true, false)
	check(book.get_global_rect().end.x <= 1281 and book.get_global_rect().end.y <= 721, "Map book fits 1280x720")
	await snapshot("casebook-map-1280.png")
	hub.close_map()
	print("Casebook UI regression failures=", failures)
	quit(0 if failures == 0 else 1)

func snapshot(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	var toast: Node = root.get_node("ToastManager")
	var timeout := Time.get_ticks_msec() + 6000
	while bool(toast.get("_is_showing_notice")) and Time.get_ticks_msec() < timeout:
		await create_timer(0.15).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + name.replace("casebook-", "casebook-v3-"))

func check(ok: bool, text: String) -> void:
	print("PASS: " + text if ok else "FAIL: " + text)
	if not ok: failures += 1
