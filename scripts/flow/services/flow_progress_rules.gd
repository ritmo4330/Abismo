extends RefCounted

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowRoomExitResult = preload("res://scripts/flow/flow_room_exit_result.gd")
const FlowRooms = preload("res://scripts/flow/flow_rooms.gd")
const FlowSteps = preload("res://scripts/flow/flow_steps.gd")
const FlowTimelines = preload("res://scripts/flow/flow_timelines.gd")

var _last_initial_search_missing_signature: String = ""


func are_manual_panels_unlocked(
	current_chapter_id: String,
	current_step_id: String,
	is_standalone_debug_flow_active: bool,
	chapter_definition: RefCounted
) -> bool:
	if OS.is_debug_build() and is_standalone_debug_flow_active:
		return true
	if current_chapter_id != FlowChapters.CH0_PROLOGUE:
		return true
	if chapter_definition == null:
		return false
	return chapter_definition.manual_unlocked_steps.has(current_step_id)


func evaluate_room_exit(
	current_chapter_id: String,
	current_step_id: String,
	current_room_id: String
) -> RefCounted:
	if current_chapter_id != FlowChapters.CH1:
		return FlowRoomExitResult.allow()
	if current_step_id != FlowSteps.CH1_INTRO_HALL:
		return FlowRoomExitResult.allow()
	if current_room_id != FlowRooms.HALL:
		return FlowRoomExitResult.allow()
	return FlowRoomExitResult.block_with_dialogue(FlowTimelines.CH1_BUTLER_BLOCK_LEAVE)


func evaluate_initial_search_finished(current_step_id: String, required_clue_ids: Array) -> Dictionary:
	if current_step_id != FlowSteps.CH1_FIRST_SEARCH:
		return {"applies": false, "finished": false, "missing_clue_ids": []}

	var missing_clue_ids: Array[String] = _get_missing_required_clues(required_clue_ids)
	return {
		"applies": true,
		"finished": missing_clue_ids.is_empty(),
		"missing_clue_ids": missing_clue_ids,
	}


func log_initial_search_missing_clues(missing_clue_ids: Array[String]) -> void:
	var signature: String = ",".join(missing_clue_ids)
	if signature == _last_initial_search_missing_signature:
		return
	_last_initial_search_missing_signature = signature
	push_warning("Ch1 initial search is not finished. Missing clues: %s" % signature)


func clear_initial_search_missing_log() -> void:
	_last_initial_search_missing_signature = ""


func _get_missing_required_clues(required_clue_ids: Array) -> Array[String]:
	var missing_clue_ids: Array[String] = []
	if DataManager == null:
		for required_clue_id: Variant in required_clue_ids:
			missing_clue_ids.append(String(required_clue_id))
		return missing_clue_ids
	for clue_id_value: Variant in required_clue_ids:
		var clue_id: String = String(clue_id_value)
		if clue_id.is_empty():
			continue
		if not DataManager.has_clue(clue_id):
			missing_clue_ids.append(clue_id)
	return missing_clue_ids
