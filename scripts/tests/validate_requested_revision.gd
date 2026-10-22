extends SceneTree

const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
var failures := 0

func _initialize() -> void:
	create_timer(55, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	var flow: Node = root.get_node("FlowManager")
	var manager: Node = root.get_node("SceneManager")
	var data: Node = root.get_node("DataManager")
	change_scene_to_file("res://scenes/UI/main_menu.tscn")
	await frames()
	await click(current_scene.get_node("SettingsButton"))
	check(is_instance_valid(current_scene._menu_overlay), "Main menu settings opens by mouse")
	var buttons: Array[Node] = current_scene._menu_overlay.find_children("*", "Button", true, false)
	await snapshot("revision-settings.png")
	for button: Node in buttons:
		if button.text == "返回": await click(button)
	check(current_scene._menu_overlay == null, "Settings closes without blocking menu")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	root.add_child(host)
	current_scene.queue_free()
	current_scene = host
	await frames()
	flow.apply_flow_state("ch1_snow_villa", "ch1_4_first_search")
	manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await frames()
	var art: Node = manager.current_room.get_node("StaticRoomArt")
	check(art._dream_material.get_shader_parameter("dream_strength") == 0.0, "First chapter keeps original background colors")
	flow.apply_flow_state("ch2_deepening", "ch2_3_third_search")
	await frames()
	check(art._dream_material.get_shader_parameter("dream_strength") == 1.0, "Dream chapter applies background-only dream filter")
	await snapshot("revision-dream-hall.png")
	var cases = load("res://scripts/UI/casebook_cases.gd")
	check(not cases.visible_now("1_suspicion_x_disability"), "New investigation hides previous novel puzzles")
	check(not cases.visible_now("2_suspicion_dream_space"), "Third investigation hides second-round questions")
	check(cases.visible_now("1_suspicion_missing_body"), "Third investigation exposes current missing-body question")
	flow.apply_flow_state("ch1_snow_villa", "ch1_4_first_search")
	await travel("res://scenes/rooms/floor2.tscn")
	await frames()
	check(manager.current_room.find_child("StairsVisualLeft", true, false) == null and manager.current_room.find_child("StairsVisualRight", true, false) == null, "Second-floor background has no added staircase icons")
	flow.apply_flow_state("ch2_deepening", "ch2_3_third_search")
	await travel("res://scenes/rooms/zhong_yue_lab.tscn")
	await frames()
	var visible_legacy := false
	for node: Node in manager.current_room.find_children("*", "CanvasItem", true, false):
		var script: Script = node.get_script()
		if script != null and script.resource_path.ends_with("_visual.gd") and node.is_visible_in_tree(): visible_legacy = true
	check(not visible_legacy, "Legacy lab geometry cannot obscure the static background")
	await snapshot("revision-dream-lab.png")
	var initial := FileAccess.get_file_as_string("res://assets/UI/default_visual_novel.tres")
	var meta := FileAccess.get_file_as_string("res://assets/UI/dialogues/plain_text.tres")
	var input_path := "res://assets/UI/dialogues/SimpleTextInputBox/custom_simple_text_input_box.tscn"
	check(initial.contains(input_path) and meta.contains(input_path), "Meta and initial name inputs use the exact same scene")
	flow.apply_flow_state("ch1_snow_villa", "ch1_2_crime_scene")
	await travel("res://scenes/rooms/room_lin_jiu.tscn")
	# The authored meeting uses a dedicated flow room id rather than the normal bedroom.
	manager.current_room.room_id = "ch1_crime_scene_lin_room"
	art = manager.current_room.get_node("StaticRoomArt")
	check(art._resolve_asset() == "hall", "First group meeting after study uses hall artwork")
	var plan: Control = load("res://scripts/UI/planning_floor_plan.gd").new()
	host.add_child(plan)
	plan.size = Vector2(730, 790)
	plan.configure("floor2", {"hall": true, "room_meta": true})
	check(plan.shown_floor == 2 and not plan.buttons.hall.visible, "Map selects actual current floor")
	check(plan.ROOMS.room_meta[2].position.x < plan.ROOMS.room_mu_zhi[2].position.x, "Original plan keeps master bedroom left of Mu's room")
	await click(plan._floor_tabs[0])
	check(plan.shown_floor == 1 and plan.buttons.hall.visible, "Floor tab is mouse-clickable")
	print("Requested revision failures=", failures)
	quit(0 if failures == 0 else 1)

func click(button: Button) -> void:
	await frames()
	var event := InputEventMouseButton.new()
	event.position = button.get_global_rect().get_center()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await frames()

func frames() -> void:
	await process_frame
	await process_frame
	await process_frame

func travel(path: String) -> void:
	root.get_node("EventBus").scene_change_requested.emit(path, "InitialSpawn")
	await process_frame
	while root.get_node("SceneManager").is_transitioning: await process_frame
	await frames()
	await process_frame
	await process_frame

func snapshot(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + name)

func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
