extends SceneTree

const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
var _capture: bool = false
var _failures: int = 0
var _host: Node2D
var _manager: Node
var _flow: Node
var _data: Node
var _navigation: CanvasLayer


func _initialize() -> void:
	_capture = OS.get_cmdline_user_args().has("--capture")
	create_timer(110.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	_manager = root.get_node("SceneManager")
	_flow = root.get_node("FlowManager")
	_data = root.get_node("DataManager")
	_flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	_host = Node2D.new()
	_host.name = "GameRoot"
	root.add_child(_host)
	current_scene = _host
	_navigation = load("res://scripts/UI/static_investigation_ui.gd").new()
	_host.add_child(_navigation)
	_host.add_child(load("res://scenes/UI/clue_panel.tscn").instantiate())
	_flow.apply_flow_state("ch1_snow_villa", "ch1_4_first_search")
	_manager.initialize(_host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await create_timer(0.5).timeout
	if OS.get_cmdline_user_args().has("--click-only"):
		await _validate_later_round_click()
		print("Static click test finished. failures=", _failures)
		quit(0 if _failures == 0 else 1)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/static_scenes/manifest.json"))
	for room_id: String in manifest.rooms:
		var step := "ch1_4_first_search"
		if room_id == "ch1_study":
			step = "ch1_1_study_free_investigation"
		elif room_id == "zhong_yue_lab":
			step = "ch1_7_second_search"
		_flow.apply_flow_state("ch1_snow_villa", step)
		var path := "res://scenes/rooms/%s.tscn" % room_id
		if room_id in ["ch1_study", "ch1_crime_scene_lin_room"]:
			path = "res://scenes/ch1_snow_villa/%s.tscn" % room_id
		if not ResourceLoader.exists(path):
			_check(false, "Room path exists: " + path)
			continue
		await _visit(path)
		var room: Node2D = _manager.current_room
		var art: Node = room.get_node_or_null("StaticRoomArt")
		_check(art != null, "Scene painting applied: " + room_id)
		if art == null:
			continue
		_check(room.get("room_id") == room_id, "Correct room loaded: " + room_id)
		_check(art.background.texture != null, "Texture loaded: " + room_id)
		_check(not _manager.current_player.visible, "No movable avatar: " + room_id)
		_check(art.background.texture.get_size().x > 1000, "Full-size painting: " + room_id)
		if room_id == "room_mu_zhi":
			_check(art.background.texture.resource_path.ends_with("mu_room_clean-v1.png"), "Early chapter does not show later charred evidence")
		for item: Node in room.find_children("*", "Area2D", true, false):
			if item.get("clue_id") != null:
				_check(art._hotspots.has(item.get_instance_id()), "Clue mapped: " + String(item.get("clue_id")))
		if room_id == "ch1_study":
			_check(art._hotspots.size() >= 5, "All initial study objects mapped")
		if room_id == "zhong_yue_lab":
			_check(art._hotspots.size() >= 3, "All laboratory evidence objects mapped")
		if room_id == "hall":
			for view_id: String in ["kitchen", "pantry", "storeroom", "hall"]:
				_check(art.set_view(view_id), "Service view opens: " + view_id)
				for item: Node in room.find_children("*", "Area2D", true, false):
					if item.get("clue_id") != null:
						var expected: String = String(art.config.get("clue_views", {}).get(item.clue_id, "hall"))
						_check(item.visible == (expected == view_id), "Clue visibility: " + item.clue_id)
			_manager.restore_static_art_view("pantry")
			_check(_manager.get_static_art_view() == "pantry", "Saved service view restored")
			art.set_view("hall")
		if room_id in ["hall", "ch1_study", "room_lin_jiu", "zhong_yue_lab", "floor2"]:
			await _snapshot("avg-" + room_id + ".png")
		print("PASS room: ", room_id)
	await _validate_later_round_click()
	await _validate_navigation_resize()
	await _validate_transition_queue()
	print("Static art integration finished. failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _visit(path: String) -> void:
	root.get_node("EventBus").scene_change_requested.emit(path, "InitialSpawn")
	while _manager.is_transitioning:
		await process_frame
	await process_frame
	await process_frame


func _validate_later_round_click() -> void:
	_flow.apply_flow_state("ch2_deepening", "ch2_3_third_search")
	await _visit("res://scenes/rooms/room_lin_jiu.tscn")
	_navigation._casebook.show_exploration()
	_data.discover_clue("1_lin_6", "test", "avg")
	var art: Node = _manager.current_room.get_node("StaticRoomArt")
	var picked: Node = art.pick_hotspot(Vector2(0.78, 0.47) * Vector2(1920, 1080))
	_check(picked != null and picked.get("clue_id") == "2_missing_body", "New missing-body clue wins over old wardrobe")
	if picked != null:
		picked.set("followup_timeline", "")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = art.get_canvas_transform() * picked.global_position
		print("Click state: ", root.get_node("GameManager").current_state, " paused=", paused, " position=", click.position)
		root.push_input(click, true)
		await process_frame
		await process_frame
		_check(_data.has_clue("2_missing_body"), "Click records later-round clue")
		_check(art.background.texture.resource_path.ends_with("lin_room_empty-v1.png"), "Missing-body discovery updates wardrobe artwork")
		_host.get_node("CluePanel")._close_panel()
		# This test covers evidence UI only, not the follow-up dialogue timeline.
		_flow.clear_pending_after_dialogue()
		var dialogue: Node = root.get_node("Dialogic")
		await process_frame
		if dialogue.current_timeline != null:
			await dialogue.end_timeline()


func _validate_navigation_resize() -> void:
	_flow.apply_flow_state("ch1_snow_villa", "ch1_3_intro_hall")
	await _visit("res://scenes/rooms/hall.tscn")
	_navigation._refresh_navigation()
	await process_frame
	_check(_navigation._npc_row.get_child_count() == 6, "All six dialogue entries remain accessible")
	await _snapshot("avg-hall-characters.png")
	root.size = Vector2i(1280, 720)
	await create_timer(0.5).timeout
	var panel: Control = _navigation._navigation_panel
	_check(panel.get_global_rect().position.x >= 0, "Navigation fits left screen edge")
	_check(panel.get_global_rect().end.x <= root.get_visible_rect().size.x + 1, "Navigation fits right screen edge")
	await _snapshot("avg-hall-1280.png")


func _validate_transition_queue() -> void:
	_manager.is_transitioning = true
	_flow.request_scene("res://scenes/rooms/floor2.tscn", "InitialSpawn")
	await process_frame
	_manager.is_transitioning = false
	await create_timer(2.0).timeout
	_check(_flow.get_current_room_id() == "floor2", "Story scene request is not lost during another transition")


func _snapshot(filename: String) -> void:
	if not _capture:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + filename)


func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error(message)
