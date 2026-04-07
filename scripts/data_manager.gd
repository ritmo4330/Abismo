extends Node

signal clue_updated(clue_id: String)
signal suspicion_updated(suspicion_id: String)
signal affinity_changed(npc_id: String, new_value: int)
signal ui_notice_requested(message: String, notice_type: String)

var clue_defs: Dictionary[String, ClueData] = {}
var clue_states: Dictionary[String, Dictionary] = {}
var suspicions: Dictionary[String, Variant] = {}
var world_flags: Dictionary[String, bool] = {}
var affinity: Dictionary[String, int] = {}
var _discover_counter: int = 0


func register_clue_def(clue_def: ClueData) -> void:
	if clue_def == null:
		return
	if clue_def.id.is_empty():
		push_warning("DataManager.register_clue_def(): clue id is empty.")
		return
	clue_defs[clue_def.id] = clue_def


func register_clue_defs(clue_def_list: Array[ClueData]) -> void:
	for clue_def: ClueData in clue_def_list:
		register_clue_def(clue_def)


func add_clue(clue_id: String, source_type: String = "scene", source_id: String = "") -> bool:
	if clue_id.is_empty():
		return false

	if has_clue(clue_id):
		return false

	var state: Dictionary = _create_default_clue_state(source_type, source_id)
	state["discovered"] = true
	_discover_counter += 1
	state["discover_order"] = _discover_counter
	clue_states[clue_id] = state

	clue_updated.emit(clue_id)
	_emit_new_clue_notice(clue_id)
	return true


func has_clue(clue_id: String) -> bool:
	if clue_id.is_empty():
		return false
	if not clue_states.has(clue_id):
		return false
	var state: Dictionary = clue_states[clue_id]
	return bool(state.get("discovered", false))


func mark_clue_read(clue_id: String) -> void:
	if clue_id.is_empty():
		return
	if not clue_states.has(clue_id):
		return

	var state: Dictionary = clue_states[clue_id]
	if bool(state.get("read", false)):
		return

	state["read"] = true
	clue_states[clue_id] = state
	clue_updated.emit(clue_id)


func get_clue_state(clue_id: String) -> Dictionary:
	if clue_id.is_empty():
		return {}
	if not clue_states.has(clue_id):
		return {}
	return clue_states[clue_id].duplicate(true)


func get_discovered_clues() -> PackedStringArray:
	var ordered_pairs: Array[Dictionary] = []
	for clue_id: String in clue_states.keys():
		var state: Dictionary = clue_states[clue_id]
		if not bool(state.get("discovered", false)):
			continue
		ordered_pairs.append({
			"clue_id": clue_id,
			"discover_order": int(state.get("discover_order", 0)),
		})

	ordered_pairs.sort_custom(_sort_by_discover_order)

	var result: PackedStringArray = PackedStringArray()
	for pair: Dictionary in ordered_pairs:
		result.append(String(pair.get("clue_id", "")))
	return result


func get_clues_by_category_path(path: PackedStringArray) -> PackedStringArray:
	if path.is_empty():
		return PackedStringArray()

	var result: PackedStringArray = PackedStringArray()
	for clue_id: String in get_discovered_clues():
		var clue_def: ClueData = clue_defs.get(clue_id, null)
		if clue_def == null:
			continue
		if _packed_string_array_equals(clue_def.category_path, path):
			result.append(clue_id)
	return result


func get_clues_by_tag(tag: String) -> PackedStringArray:
	if tag.is_empty():
		return PackedStringArray()

	var result: PackedStringArray = PackedStringArray()
	for clue_id: String in get_discovered_clues():
		var clue_def: ClueData = clue_defs.get(clue_id, null)
		if clue_def == null:
			continue
		if clue_def.tags.has(tag):
			result.append(clue_id)
	return result


func get_parent_clue_id(clue_id: String) -> String:
	if clue_id.is_empty():
		return ""
	var clue_def: ClueData = clue_defs.get(clue_id, null)
	if clue_def == null:
		return ""
	return clue_def.parent_clue_id


func get_child_clue_ids(clue_id: String) -> PackedStringArray:
	if clue_id.is_empty():
		return PackedStringArray()
	var clue_def: ClueData = clue_defs.get(clue_id, null)
	if clue_def == null:
		return PackedStringArray()
	return clue_def.child_clue_ids.duplicate()


func is_deep_unlocked(parent_clue_id: String) -> bool:
	if parent_clue_id.is_empty():
		return false
	if not clue_states.has(parent_clue_id):
		return false
	var state: Dictionary = clue_states[parent_clue_id]
	return bool(state.get("deep_unlocked", false))


func mark_deep_unlocked(parent_clue_id: String) -> bool:
	if parent_clue_id.is_empty():
		return false
	if not has_clue(parent_clue_id):
		return false

	var state: Dictionary = clue_states[parent_clue_id]
	if bool(state.get("deep_unlocked", false)):
		return false

	state["deep_unlocked"] = true
	clue_states[parent_clue_id] = state
	_discover_deep_child_clues(parent_clue_id)

	clue_updated.emit(parent_clue_id)
	_emit_deep_clue_notice(parent_clue_id)
	return true


func set_world_flag(flag_id: String, value: bool = true) -> void:
	if flag_id.is_empty():
		return
	world_flags[flag_id] = value


func get_world_flag(flag_id: String) -> bool:
	if flag_id.is_empty():
		return false
	return world_flags.get(flag_id, false)


func _create_default_clue_state(source_type: String, source_id: String) -> Dictionary:
	return {
		"discovered": false,
		"discover_order": 0,
		"read": false,
		"first_source_type": source_type,
		"first_source_id": source_id,
		"deep_unlocked": false,
	}


func _discover_deep_child_clues(parent_clue_id: String) -> void:
	var child_ids: PackedStringArray = get_child_clue_ids(parent_clue_id)
	for child_id: String in child_ids:
		if child_id.is_empty():
			continue
		if has_clue(child_id):
			continue

		# 深入调查子线索加入手册，但不重复触发“发现新线索”提示。
		var state: Dictionary = _create_default_clue_state("scene", parent_clue_id)
		state["discovered"] = true
		_discover_counter += 1
		state["discover_order"] = _discover_counter
		clue_states[child_id] = state


func _emit_new_clue_notice(clue_id: String) -> void:
	var title: String = _get_clue_title(clue_id)
	ui_notice_requested.emit("发现新线索：%s" % title, "clue")


func _emit_deep_clue_notice(parent_clue_id: String) -> void:
	var child_ids: PackedStringArray = get_child_clue_ids(parent_clue_id)
	var titles: Array[String] = []
	for child_id: String in child_ids:
		titles.append(_get_clue_title(child_id))

	if titles.is_empty():
		titles.append(_get_clue_title(parent_clue_id))

	var message: String = "发现深入线索%d条：%s" % [titles.size(), "、".join(titles)]
	ui_notice_requested.emit(message, "deep_clue")


func _get_clue_title(clue_id: String) -> String:
	var clue_def: ClueData = clue_defs.get(clue_id, null)
	if clue_def == null:
		return clue_id
	if clue_def.title.is_empty():
		return clue_id
	return clue_def.title


func _packed_string_array_equals(left: PackedStringArray, right: PackedStringArray) -> bool:
	if left.size() != right.size():
		return false
	for i: int in left.size():
		if left[i] != right[i]:
			return false
	return true


func _sort_by_discover_order(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("discover_order", 0)) < int(b.get("discover_order", 0))
