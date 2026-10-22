extends SceneTree

var failures := 0

func _initialize() -> void:
	create_timer(55.0).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	var flow: Node = root.get_node("FlowManager")
	var manager: Node = root.get_node("SceneManager")
	var dialogic: Node = root.get_node("Dialogic")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	for path: String in ["clue_panel", "suspicion_panel", "system_panel", "pause_panel"]:
		host.add_child(load("res://scenes/UI/%s.tscn" % path).instantiate())
	host.add_child(load("res://scripts/UI/static_investigation_ui.gd").new())
	flow.apply_flow_state("ch0_prologue", "ch0_0_2_snow_camp")
	root.get_node("TextSpeedManager").set("_hold_acceleration", true)
	if OS.get_cmdline_user_args().has("--chapter-title"):
		manager.initialize(host, "res://scenes/chapter_titles/chapter1_title.tscn", "InitialSpawn")
	else:
		# Leave the old room's presentation callback queued while entering study.
		manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
		flow.start_flow("ch1_snow_villa", "ch1_study_from_prologue")
	var deadline := Time.get_ticks_msec() + 25000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if flow.get_current_room_id() == "ch1_study" and flow.get_current_step_id() == "ch1_1_study_free_investigation" and dialogic.current_timeline == null and not manager.is_transitioning:
			break
	await create_timer(0.2).timeout
	print("STATE: ", flow.get_current_step_id(), " paused=", paused, " free=", flow.is_free_investigation_active(), " pending=", flow.get("_pending_after_dialogue_effects"))
	check(flow.is_free_investigation_active(), "Study wake dialogue naturally restores investigation")
	var art: Node = manager.current_room.get_node_or_null("StaticRoomArt")
	check(art != null, "Study has static art")
	if art != null:
		for clue_id: String in ["1_study_1", "1_study_2", "1_study_3", "1_study_4", "1_study_5"]:
			var target: Node2D = null
			for item: Variant in art.get_hotspot_items():
				if not is_instance_valid(item):
					continue
				if item.get("clue_id") == clue_id:
					target = item
			if target == null:
				check(false, "Hotspot exists: " + clue_id)
				continue
			var event := InputEventMouseButton.new()
			event.pressed = true
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = art.get_canvas_transform() * target.global_position
			print("CLICK: ", clue_id, " at ", event.position)
			root.push_input(event, true)
			await process_frame
			await process_frame
			check(root.get_node("DataManager").has_clue(clue_id), "Mouse click collects " + clue_id)
			host.get_node("CluePanel")._close_panel()
			await create_timer(0.2).timeout
	print("Study click regression failures=", failures)
	quit(0 if failures == 0 else 1)

func check(ok: bool, description: String) -> void:
	print("PASS: " + description if ok else "FAIL: " + description)
	if not ok:
		failures += 1
