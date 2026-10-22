extends SceneTree

# Stage-entry fixtures deliberately isolate each investigation round. Travel,
# evidence collection, modal closing and completion choices use viewport input.
const ROOMS := ["hall", "floor2", "room_lin_jiu", "room_mu_zhi", "room_zhou_chong_an", "room_wu_ting_xiang", "room_zhong_qi", "room_meta", "shu_fang", "can_ting", "hui_ke_ting", "zou_lang"]
const PHASES := ["ch1_4_first_search", "ch1_6_private_chat", "ch2_2_second_private_chat", "ch2_3_third_search", "ch2_5_third_private_chat"]
var failures := 0
var travel_count := 0
var clue_clicks := 0
var flow: Node
var manager: Node
var data: Node
var dialogue: Node
var host: Node2D
var navigation: Node
var hub: Control
var chosen: Dictionary = {}
var visited_steps: Array[String] = []

func _initialize() -> void:
	create_timer(600, true, false, true).timeout.connect(func() -> void: push_error("Map audit timed out"); quit(1))
	call_deferred("run")

func run() -> void:
	flow = root.get_node("FlowManager")
	manager = root.get_node("SceneManager")
	data = root.get_node("DataManager")
	dialogue = root.get_node("Dialogic")
	dialogue.Choices.choice_selected.connect(func(info: Dictionary) -> void: print("SELECTED: ", info))
	root.get_node("GameManager").enter_gameplay()
	host = Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	for name: String in ["clue_panel", "suspicion_panel", "pause_panel", "system_panel"]:
		host.add_child(load("res://scenes/UI/%s.tscn" % name).instantiate())
	navigation = load("res://scripts/UI/static_investigation_ui.gd").new()
	host.add_child(navigation)
	hub = navigation._casebook
	flow.reset_gameplay_runtime()
	flow.apply_flow_state("ch1_snow_villa", PHASES[0])
	manager.initialize(host, "res://scenes/rooms/hall.tscn", "InitialSpawn")
	if OS.get_cmdline_user_args().has("--exit-only"):
		await frames()
		key(KEY_ESCAPE)
		await frames()
		var pause_panel: Node = host.get_node("PausePanel")
		check(pause_panel.visible, "Escape opens actionable pause UI")
		await click(pause_panel.quit_to_title_button)
		check(current_scene != null and current_scene.scene_file_path == "res://scenes/UI/main_menu.tscn", "Mouse click on quit-to-title exits gameplay")
		print("Exit click failures=", failures)
		quit(0 if failures == 0 else 1)
		return
	if OS.get_cmdline_user_args().has("--lab-gates-only"):
		await laboratory()
		await phase_gate_checks()
		print("Lab gate click failures=", failures)
		quit(0 if failures == 0 else 1)
		return
	if OS.get_cmdline_user_args().has("--gates-only"):
		await phase_gate_checks()
		print("Gate click failures=", failures)
		quit(0 if failures == 0 else 1)
		return
	for phase: String in PHASES:
		chosen.clear()
		visited_steps.clear()
		flow.clear_pending_after_dialogue()
		flow.apply_flow_state("ch2_deepening" if phase.begins_with("ch2") else "ch1_snow_villa", phase, String(manager.current_room.get("room_id")))
		flow.set_dialogic_var("Ch1.BodySearch.Enabled", true)
		flow.set_dialogic_var("Ch2.ThirdSearch.Enabled", phase == "ch2_3_third_search")
		flow.set_dialogic_var("Ch2.ThirdPrivate.Enabled", phase == "ch2_5_third_private_chat")
		for npc: String in ["Mu", "Zhou", "Lin", "Wu", "Zhong"]:
			flow.set_dialogic_var("Ch1.NPCIntro.%s.Introed" % npc, true)
		await frames()
		navigation._refresh_navigation()
		print("PHASE: ", phase)
		for room_id: String in ROOMS:
			if not await travel(room_id): continue
			await collect_room()
			if room_id == "hall":
				for view: String in ["view:kitchen", "view:pantry", "view:storeroom", "hall"]:
					if await travel(view): await collect_room()
			await verify_lifecycle()
		if phase in ["ch1_4_first_search", "ch2_3_third_search"]:
			if phase == "ch1_4_first_search":
				check(data.has_clue("1_lin_4"), "Optional carpet drag marks are spawned and collectible")
			var required: Array = (load("res://scripts/UI/investigation_tasks.gd").FIRST if phase.begins_with("ch1") else load("res://scripts/UI/investigation_tasks.gd").THIRD)
			for clue: String in required: check(data.has_clue(clue), phase + " required collected by clicking: " + clue)
			await travel("floor2")
			print("COMPLETION STATE: ", flow.get_current_step_id(), " first=", flow.get_dialogic_var("Ch1.InitialSearch.Finished"), " third=", flow.get_dialogic_var("Ch2.ThirdSearch.Finished"))
			await click_npc("butler")
			await pump()
			var next := "ch1_5_initial_reasoning" if phase.begins_with("ch1") else "ch2_4_third_reasoning"
			check(visited_steps.has(next), "Butler completion choice enters " + next)
			await close_modals()
	await laboratory()
	await phase_gate_checks()
	print("Map click audit: travels=", travel_count, " clue_clicks=", clue_clicks, " failures=", failures)
	quit(0 if failures == 0 else 1)

func travel(id: String) -> bool:
	await pump()
	if not flow.is_free_investigation_active():
		check(false, "Free interaction available before travel: " + id)
		return false
	key(KEY_M)
	await frames()
	if not hub.map_open:
		check(false, "M opens map for " + id)
		return false
	var button: Button = hub._floor_plan.buttons.get(id)
	if button != null and not button.visible:
		var floor_index: int = int(hub._floor_plan.ROOMS[id][1]) - 1
		await click(hub._floor_plan._floor_tabs[floor_index])
	if button == null or button.disabled:
		check(false, "Destination is clickable: " + id + " at " + flow.get_current_step_id())
		hub.close_map()
		return false
	await click(button)
	await pump()
	var actual: String = flow.get_current_room_id()
	if id.begins_with("view:"):
		check(manager.get_static_art_view() == id.trim_prefix("view:"), "Map click changes service view: " + id)
	else:
		check(load("res://scripts/UI/villa_floor_plan.gd").canonical(actual) == id, "Map click reaches " + id)
	check(not hub.map_open and not paused, "Map travel releases pause: " + id)
	travel_count += 1
	hub.show_exploration()
	await frames()
	return true

func collect_room() -> void:
	var art: Node = manager.current_room.get_node_or_null("StaticRoomArt")
	check(art != null, "Room has clickable background: " + flow.get_current_room_id())
	if art == null: return
	var ids: Array[String] = []
	for item: Node2D in art.get_hotspot_items():
		if item.get("clue_id") != null and item.is_visible_in_tree() and not ids.has(item.clue_id): ids.append(item.clue_id)
	for id: String in ids:
		for attempt: int in range(2):
			await pump()
			if not is_instance_valid(art) or manager.current_room != art.room: return
			var target: Node2D = null
			for item: Node2D in art.get_hotspot_items():
				if item.get("clue_id") == id: target = item
			if target == null or not target.is_visible_in_tree(): continue
			var point := find_click_point(art, target)
			if point == Vector2.INF:
				check(false, "Evidence hotspot is reachable: " + id)
				break
			await click_at(art.get_canvas_transform() * point)
			clue_clicks += 1
			check(data.has_clue(id), "Scene click collects " + id)
			var panel: Node = host.get_node("CluePanel")
			if panel.visible: await click(panel.close_button)
			await pump()
			if attempt == 1 and not data.get_child_clue_ids(id).is_empty():
				check(data.is_deep_unlocked(id), "Second click unlocks deep evidence: " + id)

func find_click_point(art: Node, target: Node2D) -> Vector2:
	var rect: Rect2 = art._hotspots.get(target.get_instance_id(), Rect2())
	var central: Node = art.pick_hotspot(rect.get_center())
	if central != null and central.get("clue_id") == target.clue_id: return rect.get_center()
	for y: int in range(1, 10):
		for x: int in range(1, 10):
			var point := rect.position + rect.size * Vector2(x / 10.0, y / 10.0)
			var picked: Node = art.pick_hotspot(point)
			if picked != null and picked.get("clue_id") == target.clue_id: return point
	return Vector2.INF

func verify_lifecycle() -> void:
	var art: Node = manager.current_room.get_node_or_null("StaticRoomArt")
	if art == null: return
	# Reproduce the rebuild that previously left freed Object dictionary keys.
	for index: int in range(3):
		root.get_node("CluePlacementManager").setup_room_clues(manager.current_room, flow.get_current_room_id())
		await frames()
		art.pick_hotspot(Vector2(950, 500))
		check(art.get_hotspot_items().size() == art._hotspots.size(), "Rebuilt hotspots contain only live IDs")

func click_npc(id: String) -> void:
	navigation._refresh_navigation()
	hub.show_dialogues()
	await frames()
	for button: Button in navigation._npc_row.get_children():
		for connection: Dictionary in button.pressed.get_connections():
			var args: Array = connection.callable.get_bound_arguments()
			if not args.is_empty() and args[0] is Node and args[0].get("npc_id") == id:
				await click(button)
				return
	check(false, "NPC card is clickable: " + id)

func laboratory() -> void:
	await close_modals()
	flow.clear_pending_after_dialogue()
	flow.apply_flow_state("ch1_snow_villa", "ch1_7_second_search", String(manager.current_room.get("room_id")))
	flow.request_scene("res://scenes/rooms/zhong_yue_lab.tscn", "InitialSpawn")
	await pump()
	hub.show_exploration()
	await collect_room()
	for id: String in ["1_zhongyue_1", "1_zhongyue_2", "1_zhongyue_3"]:
		check(data.has_clue(id), "Laboratory clue collected by clicking: " + id)
	print("COMPLETION LAB: ", flow.get_current_step_id(), " finished=", flow.get_dialogic_var("Ch1.SecondSearch.Finished"))
	var art: Node = manager.current_room.get_node("StaticRoomArt")
	for item: Node2D in art.get_hotspot_items():
		if item.get("flow_signal_name") != null and not String(item.flow_signal_name).is_empty():
			await click_at(art.get_canvas_transform() * item.global_position)
			await pump()
			break
	check(visited_steps.has("ch2_1_second_reasoning"), "Clicking lab exit and completion choice reaches second reasoning")

func close_modals() -> void:
	for name: String in ["CluePanel", "SuspicionPanel", "SystemPanel"]:
		var panel: Node = host.get_node(name)
		if panel.visible and panel.has_method("_close_panel"): panel._close_panel()
	await frames()

func phase_gate_checks() -> void:
	await close_modals()
	for step: String in ["ch1_1_puzzle", "ch1_5_initial_reasoning", "ch2_1_second_reasoning", "ch2_4_third_reasoning"]:
		flow.apply_flow_state("ch2_deepening" if step.begins_with("ch2") else "ch1_snow_villa", step, String(manager.current_room.get("room_id")))
		await frames()
		navigation._refresh_navigation()
		key(KEY_M)
		await frames()
		check(not hub.map_open, "Reasoning cannot bypass stage through map: " + step)
		print("MANUAL ENTRY STATE: ", step, " game=", root.get_node("GameManager").current_state, " ui=", navigation.visible, " mode=", hub.mode, " paper=", hub._paper.visible, " action=", hub._buttons.reason.is_visible_in_tree(), " tokens=", root.get_node("GameManager")._pause_tokens)
		await click(hub._buttons.reason)
		var panel: Node = host.get_node("SuspicionPanel")
		check(panel.visible, "Reasoning stage has a clickable manual entry: " + step)
		if panel.visible: await click(panel.find_child("CloseButton", true, false))
		check(not paused, "Closing reasoning manual restores controls: " + step)
	flow.apply_flow_state("ch1_snow_villa", "ch1_3_intro_hall", String(manager.current_room.get("room_id")))
	flow.request_scene("res://scenes/rooms/hall.tscn", "InitialSpawn")
	await pump()
	key(KEY_M)
	await frames()
	check(hub.map_open and hub._destinations.is_empty(), "First interviews show map without allowing premature travel")
	if hub.map_open: hub.close_map()
	for id: String in ["mu", "zhou", "lin", "wu", "zhong"]:
		chosen.clear()
		await click_npc(id)
		await pump()
		var actor: String = {"mu": "Mu", "zhou": "Zhou", "lin": "Lin", "wu": "Wu", "zhong": "Zhong"}[id]
		for index: int in range(1, 4):
			check(bool(flow.get_dialogic_var("Ch1.NPCIntro.%s.Selected%d" % [actor, index], false)), "NPC mouse dialogue completes topic: %s/%d" % [id, index])
	chosen.clear()
	await click_npc("butler")
	await pump()
	check(flow.get_current_step_id() == "ch1_4_first_search", "First-interview completion enters upstairs search through butler card")

func pump() -> void:
	var deadline := Time.get_ticks_msec() + 90000
	var idle_frames := 0
	root.get_node("TextSpeedManager")._hold_acceleration = true
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var step: String = flow.get_current_step_id()
		if not visited_steps.has(step): visited_steps.append(step)
		if dialogue.current_state == DialogicGameHandler.States.AWAITING_CHOICE and dialogue.current_timeline != null:
			await create_timer(float(dialogue.Choices.reveal_delay) + float(dialogue.Choices.block_delay) + 0.15, true, false, true).timeout
			var options: Array = dialogue.Choices.get_current_question_info().choices.filter(func(c: Dictionary) -> bool: return c.visible and not c.disabled)
			var selected := ""
			var selected_token := ""
			for option: Dictionary in options:
				var token := str([dialogue.current_timeline.resource_path, dialogue.current_event_idx, option.text])
				if not chosen.has(token):
					selected_token = token
					selected = option.text
					break
			if selected.is_empty() and not options.is_empty(): selected = options[-1].text
			for button: Node in get_nodes_in_group("dialogic_choice_button"):
				if button is Button and button.is_visible_in_tree() and not button.disabled and button.text == selected:
					print("CHOICE CLICK: ", selected)
					await click(button)
					if not selected_token.is_empty(): chosen[selected_token] = true
					break
		if dialogue.current_timeline == null and not manager.is_transitioning:
			idle_frames += 1
			if idle_frames >= 8 and (flow.is_player_interface_available() or host.get_node("SuspicionPanel").visible): return
		else: idle_frames = 0
	check(false, "Story returns control: " + str([flow.get_current_step_id(), dialogue.current_timeline, dialogue.current_state]))

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)

func click(button: Control) -> void:
	await frames()
	await click_at(button.get_global_rect().get_center())

func click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = point
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await frames()

func frames() -> void:
	await process_frame
	await process_frame

func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
