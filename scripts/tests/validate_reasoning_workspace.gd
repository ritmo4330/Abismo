extends SceneTree

const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/"
var failures := 0

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	var flow: Node = root.get_node("FlowManager")
	var data: Node = root.get_node("DataManager")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	flow.apply_flow_state("ch1_snow_villa", "ch1_1_puzzle")
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	for name: String in ["clue_panel", "suspicion_panel"]:
		host.add_child(load("res://scenes/UI/%s.tscn" % name).instantiate())
	var manual: Node = host.get_node("SuspicionPanel")
	var clues: Node = host.get_node("CluePanel")
	var workspace: RefCounted = manual._workspace
	var id := "1_suspicion_x_disability"
	data.discover_clue("1_study_1", "test", "workspace")
	clues._open_interaction_panel({"display_type": "single", "clue_ids": ["1_study_1"]})
	await frames()
	check(not clues._question_workspace.question_body.visible and clues.detail_body.is_visible_in_tree(), "Clue page shows details without duplicating the reasoning workspace")
	check(clues._question_workspace.enter_button.disabled, "No undiscovered problems are invented for a new clue")
	data.add_suspicion(id, "test", "workspace")
	data.add_suspicion("1_suspicion_crime_info", "test", "workspace")
	data.add_suspicion("1_suspicion_locked_room", "test", "workspace")
	var definition: Resource = data.get_suspicion_def(id)
	var required: PackedStringArray = definition.required_clue_ids
	for clue: String in required: data.discover_clue(clue, "test", "workspace")
	data.discover_clue("1_study_1", "test", "workspace")
	clues._question_workspace.refresh()
	check(clues._question_workspace._ids.size() == 2, "Interaction problem list updates after discovery")
	await snapshot("clue-interaction-left-evidence-right-question.png")
	await click(clues._question_workspace.enter_button)
	check(manual.visible and not clues.visible and paused, "Scene interaction enters reasoning and preserves modal pause")
	check(workspace.selected_clue == "1_study_1", "Entering reasoning preserves the inspected clue without filling evidence")
	check(manual._get_slot_ids(id).all(func(value: String) -> bool: return value.is_empty()), "Interaction never automatically supplies an answer")
	manual._close_panel()
	clues._open_interaction_panel({"display_type": "single", "clue_ids": ["1_study_1"], "followup_timeline": "1_3_mu"})
	check(clues._question_workspace.enter_button.disabled, "A required story follow-up cannot be bypassed through reasoning")
	clues._interaction_payload["followup_timeline"] = ""
	clues._close_panel()
	manual._selected_suspicion_id = id
	manual._open_archive_panel()
	await frames()
	check(workspace.catalog.is_visible_in_tree() and not manual.suspicion_tree.is_visible_in_tree(), "Left page contains collected clues, not the old problem directory")
	check(workspace.catalog.get_global_rect().end.x < workspace.question_select.get_global_rect().position.x, "Evidence stays left and questions stay right")
	check(workspace._questions.size() == 2, "Right selector includes only discovered questions")
	workspace.search.text = "__no_matching_evidence__"
	workspace.refresh()
	check(workspace.selected_clue.is_empty() and workspace.add_button.disabled, "Empty search cannot submit hidden or unavailable evidence")
	workspace.search.text = ""
	workspace.refresh()
	for index: int in required.size():
		workspace.active_slot = index
		workspace.selected_clue = required[index]
		workspace.refresh()
		await click(workspace.add_button)
		check(manual._get_slot_ids(id)[index] == required[index], "Clicking left evidence action fills right slot %d" % index)
		check(manual.visible and not host.get_node("CluePanel").visible, "Evidence selection keeps the problem open")
	check(not manual.reason_button.disabled, "All selected evidence enables original reasoning validation")
	for clue: String in required:
		check(not manual._is_novel_evidence_fixed(id, clue), "Filling a correct clue does not confirm it: " + clue)
	await snapshot("reasoning-filled-before-confirm.png")
	data.set_flag("novel_confirmed/%s/%s" % [id, required[0]], true)
	check(not manual._is_novel_evidence_fixed(id, required[0]), "Legacy selection flags do not restore premature locks")
	workspace.active_slot = 0
	workspace.refresh()
	await click(workspace.remove_button)
	check(manual._get_slot_ids(id)[0].is_empty(), "A correct but unsubmitted clue can still be removed")
	manual._on_reason_button_pressed()
	check(not manual._is_novel_evidence_fixed(id, required[1]), "An incomplete submission confirms nothing")
	workspace.active_slot = 0
	workspace.selected_clue = required[0]
	workspace.refresh()
	workspace._add_evidence()
	workspace.active_slot = 2
	workspace.selected_clue = "1_study_1"
	workspace.refresh()
	workspace._add_evidence()
	check(manual._get_slot_ids(id)[2] == "1_study_1", "Unsubmitted evidence can be replaced, even when it was correct")
	await click(manual.reason_button)
	check(not data.is_suspicion_resolved(id), "One wrong clue does not solve the question")
	check(manual._is_novel_evidence_fixed(id, required[0]) and manual._is_novel_evidence_fixed(id, required[1]), "Confirming three clues fixes only the submitted correct evidence")
	check(not manual._is_novel_evidence_fixed(id, "1_study_1") and not manual.slot_buttons[2].disabled, "Submitted wrong evidence remains editable")
	await snapshot("reasoning-partial-after-confirm.png")
	var confirmed_state: Dictionary = data.save_runtime_state().duplicate(true)
	data.set_flag("reasoning_confirmed/%s/%s" % [id, required[0]], false)
	data.load_runtime_state(confirmed_state)
	await frames()
	check(manual._is_novel_evidence_fixed(id, required[0]) and not manual._is_novel_evidence_fixed(id, "1_study_1"), "Restoring progress preserves submitted confirmations without confirming the wrong clue")
	workspace.active_slot = 0
	workspace.refresh()
	await click(workspace.remove_button)
	check(manual._get_slot_ids(id)[0] == required[0] and workspace.remove_button.disabled, "Submitted correct evidence cannot be removed")
	workspace.active_slot = 2
	workspace.selected_clue = required[0]
	workspace.refresh()
	workspace._add_evidence()
	check(manual._get_slot_ids(id)[0] == required[0] and manual._get_slot_ids(id)[2] == "1_study_1", "Confirmed evidence cannot be displaced or counted twice")
	workspace.active_slot = 2
	workspace.refresh()
	await click(workspace.remove_button)
	check(manual._get_slot_ids(id)[2].is_empty(), "Wrong evidence can be removed after confirmation")
	workspace.active_slot = 2
	workspace.selected_clue = required[2]
	workspace.refresh()
	workspace._add_evidence()
	check(not manual._is_novel_evidence_fixed(id, required[2]), "Replacement correct evidence waits for the next confirmation")
	check(not workspace._questions.has("1_suspicion_locked_room"), "Novel page hides questions from later investigations")
	var alternate: int = workspace._questions.find("1_suspicion_crime_info")
	workspace._on_question_selected(alternate)
	check(manual._selected_suspicion_id == "1_suspicion_crime_info", "Question selector switches the right-hand problem")
	workspace._on_question_selected(workspace._questions.find(id))
	check(manual._get_slot_ids(id) == Array(required), "Switching questions preserves selected evidence")
	manual._on_locked_suspicion_requested(id, "")
	check(workspace.question_select.disabled and workspace.search.editable, "Locked reasoning locks the problem, not evidence search")
	manual._on_close_button_pressed()
	check(manual.visible, "Locked reasoning cannot be bypassed by closing")
	root.get_node("EventBus").clue_selection_requested.emit({"source": "suspicion_ui", "suspicion_id": id, "slot_index": 1})
	check(manual.visible and not clues.visible and workspace.active_slot == 1, "Legacy evidence interaction routes into the same two-page workspace")
	await frames()
	await snapshot("reasoning-left-evidence-right-question.png")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await frames()
	check(workspace.add_button.get_global_rect().end.y <= 720 and manual.reason_button.get_global_rect().end.y <= 720, "Both evidence and confirmation actions fit 1280x720")
	check(manual.reason_button.get_global_rect().end.x <= 1281, "Right problem and confirmation stay within small viewport")
	await snapshot("reasoning-left-evidence-right-question-1280.png")
	manual._on_reason_button_pressed()
	check(data.is_suspicion_resolved(id), "Correct evidence still resolves the original problem")
	check(manual._is_novel_evidence_fixed(id, required[2]), "The second confirmation fixes the corrected clue")
	check(is_instance_valid(manual._success_layer), "Successful reasoning waits for explicit conclusion acknowledgement")
	if is_instance_valid(manual._success_layer): await click(manual._success_layer.continue_button)
	print("Reasoning workspace failures=", failures)
	quit(0 if failures == 0 else 1)

func frames() -> void:
	await process_frame
	await process_frame

func click(button: Button) -> void:
	await frames()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	var motion := InputEventMouseMotion.new()
	motion.position = event.position
	root.push_input(motion, true)
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await frames()

func snapshot(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await create_timer(4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + name)

func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
