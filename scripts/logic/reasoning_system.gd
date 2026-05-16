class_name ReasoningSystem
extends RefCounted


static func validate(suspicion_def: SuspicionData, selected_clue_ids: PackedStringArray) -> bool:
	if suspicion_def == null:
		return false

	var required_ids: PackedStringArray = suspicion_def.required_clue_ids
	if required_ids.is_empty():
		return false
	if _has_empty_or_duplicate(selected_clue_ids):
		return false

	match suspicion_def.match_mode:
		"contains":
			return _contains_match(required_ids, selected_clue_ids)
		_:
			return _exact_match(required_ids, selected_clue_ids)


static func _exact_match(required_ids: PackedStringArray, selected_ids: PackedStringArray) -> bool:
	if required_ids.size() != selected_ids.size():
		return false
	for required_id: String in required_ids:
		if not selected_ids.has(required_id):
			return false
	return true


static func _contains_match(required_ids: PackedStringArray, selected_ids: PackedStringArray) -> bool:
	for required_id: String in required_ids:
		if not selected_ids.has(required_id):
			return false
	for selected_id: String in selected_ids:
		if not required_ids.has(selected_id):
			return false
	return true


static func _has_empty_or_duplicate(selected_ids: PackedStringArray) -> bool:
	var seen_ids: Dictionary[String, bool] = {}
	for selected_id: String in selected_ids:
		if selected_id.is_empty():
			return true
		if seen_ids.has(selected_id):
			return true
		seen_ids[selected_id] = true
	return false
