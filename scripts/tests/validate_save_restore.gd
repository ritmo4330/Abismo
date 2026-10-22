extends SceneTree

var failures := 0

func _initialize() -> void:
	create_timer(35.0).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	var flow: Node = root.get_node("FlowManager")
	var data: Node = root.get_node("DataManager")
	var manager: Node = root.get_node("SceneManager")
	var dialogic: Node = root.get_node("Dialogic")
	var game: Node = root.get_node("GameManager")
	var previous_slot: String = dialogic.Save.get_latest_slot()
	var saver: Node = load("res://scripts/tests/isolated_test_save.gd").new()
	saver.test_slot = "flow_audit_" + str(Time.get_ticks_usec())
	root.add_child(saver)
	flow.reset_gameplay_runtime()
	game.enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	flow.apply_flow_state("ch2_deepening", "ch2_5_third_private_chat")
	manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await process_frame
	manager.restore_static_art_view("kitchen")
	data.discover_clue("2_missing_body", "test", "save")
	data.set_flag("novel_hint/1_suspicion_x_disability/failure_3", true)
	data.set_flag("reasoning_confirmed/1_suspicion_x_disability/1_puzzle_x_impossible_1", true)
	for npc: String in ["Mu", "Zhou", "Lin", "Wu", "Zhong"]:
		flow.set_dialogic_var("Ch2.ThirdPrivate.%s.Finished" % npc, true)
	flow.set_dialogic_var("Affinity.Wu", 80)
	# Simulate an older save whose derived completion boolean is stale.
	flow.set_dialogic_var("Ch2.ContentComplete.Ready", false)
	game.request_pause("system_panel")
	check(saver.save_game() == OK, "Save from paused system panel")
	data.set_flag("autosave_only", true)
	check(saver.autosave_before_endings() == OK and saver.has_autosave(), "Independent ending autosave is written")
	game.enter_main_menu()
	host.queue_free()
	await process_frame
	flow.reset_gameplay_runtime()
	check(saver.request_load_game(), "Isolated save is readable")
	var restored := Node2D.new()
	restored.name = "GameRoot"
	root.add_child(restored)
	current_scene = restored
	check(saver.restore_pending_game(restored), "Restore saved room and dialogue state")
	await process_frame
	await process_frame
	await process_frame
	check(flow.get_current_step_id() == "ch2_5_third_private_chat", "Flow step survives load")
	check(manager.get_static_art_view() == "kitchen", "Service view survives load")
	check(data.has_clue("2_missing_body"), "Collected evidence survives load")
	check(data.has_flag("novel_hint/1_suspicion_x_disability/failure_3"), "Novel hint progress survives load")
	check(data.has_flag("reasoning_confirmed/1_suspicion_x_disability/1_puzzle_x_impossible_1"), "Explicitly confirmed evidence survives save and load")
	check(not data.has_flag("autosave_only"), "Automatic save does not overwrite manual progress")
	check(int(flow.get_dialogic_var("Affinity.Wu", 0)) == 80, "Trust survives load")
	check(not paused and flow.is_free_investigation_active(), "Load does not retain system pause")
	check(bool(flow.get_dialogic_var("Ch2.ContentComplete.Ready", false)), "Private chat completion is recalculated after variables load")
	check(saver.request_load_game(saver._get_autosave_slot_name()), "Ending autosave can be selected independently")
	check(saver.restore_pending_game(restored), "Ending autosave restores successfully")
	check(data.has_flag("autosave_only"), "Selected autosave restores its own state")
	dialogic.Save.delete_slot(saver.test_slot)
	dialogic.Save.delete_slot(saver._get_autosave_slot_name())
	dialogic.Save.set_latest_slot(previous_slot)
	print("Save restore regression failures=", failures)
	quit(0 if failures == 0 else 1)

func check(ok: bool, text: String) -> void:
	print("PASS: " + text if ok else "FAIL: " + text)
	if not ok:
		failures += 1
