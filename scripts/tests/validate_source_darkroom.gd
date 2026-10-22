extends SceneTree

var failures := 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failures += 1

func run() -> void:
	var source: Script = load("res://scripts/clues/source_investigation.gd")
	var flow: Node = root.get_node("FlowManager")
	var data: Node = root.get_node("DataManager")
	var manager: Node = root.get_node("SceneManager")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	flow.apply_flow_state("ch3_transcend", "ch3_4_route")
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	var panel: Node = load("res://scenes/UI/clue_panel.tscn").instantiate()
	host.add_child(panel)
	manager.initialize(host, "res://scenes/rooms/shu_fang.tscn", "SpawnFromZouLang")
	await create_timer(0.5).timeout
	var art: Node = manager.current_room.get_node("StaticRoomArt")
	check(not art.get_views().has("darkroom"), "Study darkroom stays locked before Wu's decision")
	check(not art.set_view("darkroom"), "A locked view cannot be entered programmatically")
	flow.open_source_darkroom()
	manager._on_scene_change_requested("res://scenes/rooms/shu_fang.tscn", "SpawnFromZouLang")
	await create_timer(0.7).timeout
	while manager.is_transitioning: await process_frame
	art = manager.current_room.get_node("StaticRoomArt")
	var physical: Array[String] = []
	for item: Node in art.get_hotspot_items():
		if item.get("clue_id") is String and item.is_visible_in_tree(): physical.append(item.clue_id)
	check(not physical.has("3_study_darkroom_4"), "Study view does not leak the hidden notebook")
	check(art.set_view("darkroom"), "Unlocked darkroom is a real investigable view")
	var found: Array[String] = []
	for item: Node in art.get_hotspot_items():
		if item.get("clue_id") is String and item.is_visible_in_tree():
			found.append(item.clue_id)
			item.interact(null)
			if panel._is_open: panel._close_panel()
	check(found.size() == 6, "All six authored darkroom objects have separate visible hotspots")
	for id: String in source.DARKROOM_CLUES:
		check(found.has(id) and data.has_clue(id), "Darkroom clue can be collected: " + id)
	flow.sync_source_plot()
	check(bool(flow.get_dialogic_var("SourcePlot.HasCycle", false)), "Collected cycle notes unlock the original Wu conversation")
	check(data.get_clue_def("3_study_darkroom_4").description.contains("第429次"), "The complete supplied cycle notes reach the reader")
	check(art.set_view("villa"), "Player can return to the study without leaving the room")
	print("Source darkroom validation finished. failures=", failures)
	quit(1 if failures else 0)
