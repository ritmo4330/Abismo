extends SceneTree

var failures := 0
var flow: Node
var manager: Node
var dialogue: Node
var host: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	flow = root.get_node("FlowManager")
	manager = root.get_node("SceneManager")
	dialogue = root.get_node("Dialogic")
	root.get_node("SaveManager").cancel_pending_load()
	change_scene_to_file("res://scenes/UI/main_menu.tscn")
	await frames()
	await click(current_scene.start_button)
	await frames()
	host = current_scene
	var ctrl := InputEventKey.new()
	ctrl.keycode = KEY_CTRL
	ctrl.pressed = true
	root.push_input(ctrl, true)
	var deadline := Time.get_ticks_msec() + 60000
	var last_state := ""
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state := str([flow.get_current_step_id(), flow.get_current_room_id(), dialogue.current_state, dialogue.current_event_idx, paused])
		if state != last_state:
			last_state = state
			print("BOOT: ", state)
		if dialogue.current_state == DialogicGameHandler.States.AWAITING_CHOICE:
			await create_timer(0.4, true, false, true).timeout
			for button: Node in get_nodes_in_group("dialogic_choice_button"):
				if button is Button and button.is_visible_in_tree() and not button.disabled:
					await click(button)
					break
		for input: Node in get_nodes_in_group("dialogic_text_input"):
			if input is Control and input.is_visible_in_tree():
				var edit := input.find_child("*", true, false)
				for node: Node in input.find_children("*", "LineEdit", true, false):
					edit = node
					(edit as LineEdit).text = "测试玩家"
					(edit as LineEdit).text_submitted.emit("测试玩家")
					break
		if flow.get_current_room_id() == "ch1_study" and dialogue.current_timeline == null and not manager.is_transitioning:
			break
	ctrl.pressed = false
	root.push_input(ctrl, true)
	await frames()
	dump_state()
	check(flow.is_free_investigation_active(), "Full new-game boot restores clickable study investigation")
	if manager.current_room != null:
		var art: Node = manager.current_room.get_node_or_null("StaticRoomArt")
		check(art != null, "Full boot study creates static interaction art")
		key_escape()
		await frames()
		check(host.get_node("PausePanel").visible, "Escape in study opens a working pause menu")
		if host.get_node("PausePanel").visible:
			await click(host.get_node("PausePanel").resume_button)
		check(not paused, "Clicking resume restores study input")
		if art != null:
			for id: String in ["1_study_1", "1_study_2", "1_study_3", "1_study_4", "1_study_5"]:
				var target: Node2D = null
				for item: Variant in art.get_hotspot_items():
					if is_instance_valid(item) and item.get("clue_id") == id: target = item
				check(target != null, "Study hotspot exists: " + id)
				if target == null: continue
				await click_at(art.get_canvas_transform() * target.global_position)
				check(root.get_node("DataManager").has_clue(id), "Actual boot mouse click collects " + id)
				var panel: Node = host.get_node("CluePanel")
				if panel.visible: await click(panel.close_button)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	await frames()
	print("AFTER ESCAPE")
	dump_state()
	check(host.get_node("PausePanel").visible or dialogue.current_timeline != null, "Escape opens pause or required story continues, never an inert room")
	if OS.get_cmdline_user_args().has("--through-puzzle"):
		await complete_novel()
	print("Full boot click failures=", failures)
	quit(0 if failures == 0 else 1)

func dump_state() -> void:
	print("STATE: step=", flow.get_current_step_id(), " room=", flow.get_current_room_id(), " timeline=", dialogue.current_timeline, " dialog_state=", dialogue.current_state, " paused=", paused, " tokens=", root.get_node("GameManager")._pause_tokens, " transition=", manager.is_transitioning, " pending=", flow._scene_navigator.pending_auto_timeline, " effects=", flow._pending_after_dialogue_effects)

func key_escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)

func complete_novel() -> void:
	root.get_node("TextSpeedManager")._hold_acceleration = true
	await pump_story()
	check(flow.get_current_step_id() == "ch1_1_puzzle", "Five clicked study clues naturally enter the novel reasoning stage")
	var data: Node = root.get_node("DataManager")
	var manual: Node = host.get_node("SuspicionPanel")
	var hub: Control = host.get_node("StaticInvestigationUI")._casebook
	var count := 0
	while flow.get_current_step_id() == "ch1_1_puzzle" and count < 12:
		if not manual.visible: await click(hub._buttons.reason)
		check(manual.visible, "Novel reasoning manual opens through visible menu")
		if not manual.visible: break
		var work: RefCounted = manual._workspace
		var next := ""
		for id: String in data.get_discovered_suspicion_ids():
			if data.is_suspicion_resolved(id): continue
			var definition: Resource = data.get_suspicion_def(id)
			if definition == null or not definition.tags.has("puzzle"): continue
			var ready := true
			for required: String in definition.required_clue_ids:
				if not data.has_clue(required): ready = false
			if ready:
				next = id
				break
		check(not next.is_empty(), "An original novel problem has all discoverable evidence")
		if next.is_empty(): break
		work._on_question_selected(work._questions.find(next))
		var problem: Resource = data.get_suspicion_def(next)
		for index: int in problem.required_clue_ids.size():
			await click(manual.slot_row.get_child(index))
			var id: String = problem.required_clue_ids[index]
			work.search.text = data.get_clue_def(id).title
			work.search.text_changed.emit(work.search.text)
			await frames()
			var item: TreeItem = work.catalog.get_root().get_first_child()
			while item != null and item.get_metadata(0) != id:
				item = item.get_next_in_tree()
			check(item != null and item.get_metadata(0) == id, "Required clue is selectable in the left catalogue: " + id)
			if item == null or item.get_metadata(0) != id: break
			work.catalog.scroll_to_item(item)
			await frames()
			var rect: Rect2 = work.catalog.get_item_area_rect(item, 0)
			await click_at(work.catalog.get_global_transform() * rect.get_center())
			await click(work.add_button)
		await click(manual.reason_button)
		check(data.is_suspicion_resolved(next), "Mouse-selected evidence resolves original novel problem: " + next)
		check(is_instance_valid(manual._success_layer), "Correct reasoning displays a conclusion before continuing")
		if is_instance_valid(manual._success_layer): await click(manual._success_layer.continue_button)
		var clues: Node = host.get_node("CluePanel")
		if clues.visible: await click(clues.close_button)
		await pump_story()
		count += 1
	check(data.has_clue("1_conclusion_parallel_worlds"), "Novel final conclusion is reachable without bypassing the puzzle")
	check(flow.get_current_step_id() == "ch1_3_intro_hall", "Solved novel -> request -> crime scene -> CG -> hall interviews")
	dump_state()

func pump_story() -> void:
	var deadline := Time.get_ticks_msec() + 90000
	var idle := 0
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if dialogue.current_timeline != null and dialogue.current_state == DialogicGameHandler.States.AWAITING_CHOICE:
			await create_timer(0.9, true, false, true).timeout
			for button: Node in get_nodes_in_group("dialogic_choice_button"):
				if button is Button and button.is_visible_in_tree() and not button.disabled:
					await click(button)
					break
		if dialogue.current_timeline == null and not manager.is_transitioning and flow.get_current_step_id() in ["ch1_1_puzzle", "ch1_3_intro_hall"]:
			idle += 1
			if idle >= 10: return
		else: idle = 0
	check(false, "Story finishes instead of stranding the study")
	dump_state()

func click(button: Control) -> void:
	await frames()
	print("CLICK UI: ", button.get_path(), " ", button.get_global_rect())
	await click_at(button.get_global_rect().get_center())

func click_at(point: Vector2) -> void:
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
	await frames()

func frames() -> void:
	await process_frame
	await process_frame

func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
