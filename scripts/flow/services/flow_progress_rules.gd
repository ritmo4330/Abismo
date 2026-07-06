extends RefCounted

const FlowIds = preload("res://scripts/flow/flow_ids.gd")
const Ch0FlowConfig = preload("res://scripts/flow/configs/ch0_flow_config.gd")
const Ch1FlowConfig = preload("res://scripts/flow/configs/ch1_flow_config.gd")

var _last_initial_search_missing_signature: String = ""


func are_manual_panels_unlocked(
	current_chapter_id: String,
	current_step_id: String,
	is_standalone_debug_flow_active: bool
) -> bool:
	if OS.is_debug_build() and is_standalone_debug_flow_active:
		return true
	if current_chapter_id != FlowIds.CHAPTER_CH0_PROLOGUE:
		return true
	return Ch0FlowConfig.MANUAL_UNLOCKED_STEPS.has(current_step_id)


func should_block_current_room_exit(
	current_chapter_id: String,
	current_step_id: String,
	current_room_id: String
) -> bool:
	if current_chapter_id != FlowIds.CHAPTER_CH1:
		return false
	if current_step_id != FlowIds.STEP_CH1_INTRO_HALL:
		return false
	if current_room_id != FlowIds.ROOM_HALL:
		return false
	EventBus.dialogue_requested.emit(FlowIds.TIMELINE_CH1_BUTLER_BLOCK_LEAVE)
	return true


func refresh_ch1_initial_search_finished(current_step_id: String, dialogic_bridge: RefCounted) -> void:
	if current_step_id != FlowIds.STEP_CH1_FIRST_SEARCH:
		return

	var missing_clue_ids: Array[String] = _get_missing_required_clues(Ch1FlowConfig.INITIAL_SEARCH_REQUIRED_CLUES)
	var is_finished: bool = missing_clue_ids.is_empty()
	if bool(dialogic_bridge.get_var("Ch1.InitialSearch.Finished", false)) == is_finished:
		if not is_finished:
			_log_initial_search_missing_clues(missing_clue_ids)
		return

	dialogic_bridge.set_var("Ch1.InitialSearch.Finished", is_finished)
	if is_finished:
		_last_initial_search_missing_signature = ""
	else:
		_log_initial_search_missing_clues(missing_clue_ids)


func _get_missing_required_clues(required_clue_ids: Array[String]) -> Array[String]:
	var missing_clue_ids: Array[String] = []
	if DataManager == null:
		return required_clue_ids.duplicate()
	for clue_id: String in required_clue_ids:
		if clue_id.is_empty():
			continue
		if not DataManager.has_clue(clue_id):
			missing_clue_ids.append(clue_id)
	return missing_clue_ids


func _log_initial_search_missing_clues(missing_clue_ids: Array[String]) -> void:
	var signature: String = ",".join(missing_clue_ids)
	if signature == _last_initial_search_missing_signature:
		return
	_last_initial_search_missing_signature = signature
	push_warning("Ch1 initial search is not finished. Missing clues: %s" % signature)
