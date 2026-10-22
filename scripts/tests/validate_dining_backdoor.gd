extends SceneTree

const RULES = preload("res://scripts/clues/dining_backdoor_rules.gd")
var routes: Script
const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
var failures := 0
var flow: Node
var data: Node
var manager: Node
var host: Node2D
var saver: Node
var previous_slot: String

func _initialize() -> void:
	create_timer(85, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	routes = load("res://scripts/UI/villa_map_routes.gd")
	flow = root.get_node("FlowManager")
	data = root.get_node("DataManager")
	manager = root.get_node("SceneManager")
	var dialogic: Node = root.get_node("Dialogic")
	previous_slot = dialogic.Save.get_latest_slot()
	saver = load("res://scripts/tests/isolated_test_save.gd").new()
	saver.test_slot = "flower_sea_audit_" + str(Time.get_ticks_usec())
	root.add_child(saver)
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	flow.apply_flow_state("ch1_snow_villa", "ch1_4_first_search")
	host = Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	host.add_child(load("res://scenes/UI/clue_panel.tscn").instantiate())
	host.add_child(load("res://scenes/UI/suspicion_panel.tscn").instantiate())
	var ui: Node = load("res://scripts/UI/static_investigation_ui.gd").new()
	host.add_child(ui)
	manager.initialize(host, "res://scenes/rooms/can_ting.tscn", "SpawnFromHall")
	await settle()
	ui._casebook.show_exploration()
	await process_frame
	check(not routes.reachable("can_ting").has("flower_sea"), "Map cannot bypass the locked rear door")
	check(not flow.request_scene(RULES.SCENE, "SpawnFromDining"), "Direct navigation cannot bypass the lock")
	await click_world(Vector2(0.93, 0.4))
	var panel := lock_panel()
	check(panel != null and paused, "Painted clue hotspot opens the lock modal, not only a dead-end description")
	if panel == null:
		quit(1)
		return
	check(data.has_clue("1_dining_2"), "Door investigation retains the original authored clue")
	check(panel.confirm_button.disabled, "Early chapter correctly keeps the four-world door locked")
	for button: Button in panel.buttons: button.button_pressed = true
	panel.confirm()
	check(not data.has_flag(RULES.OPEN_FLAG), "Early chapter and missing research cannot open the lock")
	panel.close()
	await settle()
	check(not paused, "Cancelling the lock releases its own pause token")
	flow.apply_flow_state("ch2_deepening", "ch2_5_third_private_chat")
	check(not RULES.ready(), "Late stage alone never invents missing research")
	data.add_clue("1_zhongyue_1", "test", "flower_sea")
	flow.reveal_source_research("mu")
	flow.reveal_source_research("zhou")
	check(not RULES.ready(), "Three research worlds are insufficient")
	flow.reveal_source_research("lin")
	check(RULES.ready(), "Existing authored evidence from all four worlds enables the mechanism")
	# Older save compatibility: research records are sufficient even without flags.
	for npc: String in ["mu", "zhou", "lin"]: data.set_flag("source_research/" + npc, false)
	check(RULES.ready(), "Legacy research evidence is recognized without replaying conversations")
	check(not RULES.confirm(["α", "β", "γ", "γ"]), "Repeated handprints do not count as four symbols")
	await click_world(Vector2(0.93, 0.4))
	panel = lock_panel()
	for index: int in 3: panel.buttons[index].button_pressed = true
	panel.confirm()
	check(not data.has_flag(RULES.OPEN_FLAG) and panel.confirm_button.disabled, "Three selected handprints cannot confirm")
	panel.buttons[3].button_pressed = true
	check(not data.has_flag(RULES.OPEN_FLAG), "Selecting all four never unlocks before explicit confirmation")
	if OS.get_cmdline_user_args().has("--capture"):
		await capture("flower-backdoor-lock.png")
	panel.close()
	await settle()
	await click_world(Vector2(0.93, 0.4))
	panel = lock_panel()
	check(panel.handprints.is_empty(), "Cancelled selections do not masquerade as confirmed handprints")
	if OS.get_cmdline_user_args().has("--lock-only"):
		panel.close()
		dialogic.Save.set_latest_slot(previous_slot)
		print("Dining lock validation finished. failures=", failures)
		quit(0 if failures == 0 else 1)
		return
	for button: Button in panel.buttons: await click_control(button)
	await click_control(panel.confirm_button)
	await settle()
	check(RULES.can_enter() and flow.get_current_room_id() == "flower_sea", "Confirm opens the physical door and travels into the flower sea")
	check(not paused and not manager.is_transitioning, "Door transition leaves gameplay unpaused")
	var art: Node = manager.current_room.get_node("StaticRoomArt")
	check(art.background.get_node_or_null("TemporaryFlowerSea") != null or (art.background.texture != null and art.background.texture.resource_path.contains("flower_sea-v1")), "Flower sea uses its own authorized native background or replacement art, not an interior placeholder")
	check(not data.has_clue("3_flower_sea_1") and not data.has_clue("3_flower_sea_2"), "Entering alone never auto-grants either investigation clue")
	if OS.get_cmdline_user_args().has("--capture"):
		await capture("flower-sea-gameplay.png")
	await click_world(Vector2(0.73, 0.73))
	check(data.has_clue("3_flower_sea_2"), "Folded white dress is collected by its visible hotspot")
	await close_clue()
	await click_world(Vector2(0.18, 0.43))
	check(data.has_clue("3_flower_sea_1"), "Security-bar body is collected by its visible hotspot")
	check(not data.has_clue("3_flower_sea_1_4"), "Body detail is not silently granted on first inspection")
	await close_clue()
	await click_world(Vector2(0.18, 0.43))
	check(data.is_deep_unlocked("3_flower_sea_1"), "Re-inspecting the body enables all three authored detail entries")
	await close_clue()
	check(routes.reachable("flower_sea").has("can_ting"), "Garden always has a route back to the dining room")
	check(saver.save_game() == OK, "Garden room and opened door are saved in an isolated test slot")
	root.get_node("GameManager").enter_main_menu()
	host.queue_free()
	await process_frame
	flow.reset_gameplay_runtime()
	check(saver.request_load_game(), "Isolated garden save can be read")
	host = Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	check(saver.restore_pending_game(host), "Actual garden scene restores from save")
	await settle()
	check(RULES.can_enter() and flow.get_current_room_id() == "flower_sea", "Door confirmation and garden location persist across load")
	check(data.has_clue("3_flower_sea_2") and data.has_clue("3_flower_sea_1"), "Collected garden evidence persists across load")
	await click_world(Vector2(0.84, 0.36))
	check(flow.get_current_room_id() == "can_ting", "Clicking the painted return door actually reaches the dining room")
	await click_world(Vector2(0.93, 0.4))
	check(flow.get_current_room_id() == "flower_sea" and not paused, "Confirmed door reopens without repeating the mechanism")
	check(routes.travel("hall"), "Map navigation also works from the new garden room")
	await settle()
	check(flow.get_current_room_id() == "hall", "Map travel leaves the garden and reaches the selected room")
	dialogic.Save.delete_slot(saver.test_slot)
	dialogic.Save.set_latest_slot(previous_slot)
	print("Dining backdoor validation finished. failures=", failures)
	quit(0 if failures == 0 else 1)

func lock_panel() -> Node:
	return manager.current_room.find_child("DiningBackdoorPanel", true, false)

func settle() -> void:
	await create_timer(1.1, true, false, true).timeout
	var deadline := Time.get_ticks_msec() + 5000
	while manager.is_transitioning and Time.get_ticks_msec() < deadline: await process_frame
	await process_frame

func click_world(normalized: Vector2) -> void:
	var art: Node2D = manager.current_room.get_node("StaticRoomArt")
	var at: Vector2 = art.get_canvas_transform() * (normalized * Vector2(1920, 1080))
	var motion := InputEventMouseMotion.new()
	motion.position = at
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = at
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await settle()

func close_clue() -> void:
	var clue: Node = host.get_node("CluePanel")
	clue._close_panel()
	await process_frame
	await process_frame

func click_control(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + filename)

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
