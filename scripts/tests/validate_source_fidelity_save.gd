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
	saver.test_slot = "fidelity_audit_" + str(Time.get_ticks_usec())
	root.add_child(saver)
	flow.reset_gameplay_runtime()
	game.enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	flow.apply_flow_state("ch1_snow_villa", "ch1_4_first_search")
	manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	await create_timer(0.5).timeout
	manager.restore_static_art_view("storeroom")
	flow.record_initial_search_order(2)
	flow.set_dialogic_var("Ch1.PrivateChat.Wu.Asked.Arrival", true)
	flow.set_dialogic_var("SourcePlot.WuSandbox", true)
	flow.set_dialogic_var("SourcePlot.WuDeconstruction", false)
	check(saver.save_game() == OK, "Write isolated save with new source progress")
	game.enter_main_menu()
	host.queue_free()
	await process_frame
	flow.reset_gameplay_runtime()
	check(saver.request_load_game(), "Read isolated save")
	var restored := Node2D.new()
	restored.name = "GameRoot"
	root.add_child(restored)
	current_scene = restored
	check(saver.restore_pending_game(restored), "Restore actual room and Dialogic state")
	await create_timer(0.5).timeout
	check(data.has_clue("1_initial_search_order_2"), "Search-order evidence survives load")
	check(data.get_clue_def("1_initial_search_order_2").description == "钟歧、你、周崇安、林玖、乌停湘、穆执", "Search-order definition remains available after reset/load")
	check(int(flow.get_dialogic_var("Ch1.InitialSearch.PlayerTurn", 0)) == 2, "Selected search position survives load")
	check(bool(flow.get_dialogic_var("Ch1.PrivateChat.Wu.Asked.Arrival", false)), "Private arrival prerequisite survives load")
	check(bool(flow.get_dialogic_var("SourcePlot.WuSandbox", false)) and not bool(flow.get_dialogic_var("SourcePlot.WuDeconstruction", true)), "Individual newspaper follow-ups survive load separately")
	check(manager.get_static_art_view() == "storeroom", "Storeroom presentation survives load")
	# Exercise Dialogic's actual old-save defaults merge without touching a user slot.
	var variables: Dictionary = dialogic.current_state_info.variables
	variables.Ch1.PrivateChat.Wu.Asked.erase("Arrival")
	variables.SourcePlot.erase("WuSandbox")
	variables.SourcePlot.erase("WuDeconstruction")
	variables.SourcePlot.erase("WuPaper")
	dialogic.VAR.load_game_state()
	check(dialogic.VAR.has("Ch1.PrivateChat.Wu.Asked.Arrival"), "An old save gains the new arrival variable")
	check(not bool(flow.get_dialogic_var("SourcePlot.WuSandbox", true)), "Old saves default missing follow-ups to unasked, not completed")
	check(int(flow.get_dialogic_var("Ch1.InitialSearch.PlayerTurn", 0)) == 2, "Default migration does not erase an existing search order")
	dialogic.Save.delete_slot(saver.test_slot)
	dialogic.Save.set_latest_slot(previous_slot)
	print("Source fidelity save validation finished. failures=", failures)
	quit(0 if failures == 0 else 1)

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
