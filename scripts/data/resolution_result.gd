class_name ResolutionResult
extends RefCounted

var success: bool = false
var suspicion_id: String = ""
var conclusion_clue_id: String = ""
var unlocked_suspicion_ids: PackedStringArray = PackedStringArray()
var resolved_world_flag: String = ""


static func failure(target_suspicion_id: String = ""):
	var result = new()
	result.suspicion_id = target_suspicion_id
	return result


static func success_result(
	target_suspicion_id: String,
	target_conclusion_clue_id: String,
	target_unlocked_suspicion_ids: PackedStringArray,
	target_resolved_world_flag: String
):
	var result = new()
	result.success = true
	result.suspicion_id = target_suspicion_id
	result.conclusion_clue_id = target_conclusion_clue_id
	result.unlocked_suspicion_ids = target_unlocked_suspicion_ids.duplicate()
	result.resolved_world_flag = target_resolved_world_flag
	return result
