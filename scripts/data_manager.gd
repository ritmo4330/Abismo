extends Node

signal clue_updated(clue_id: String)
signal suspicion_updated(suspicion_id: String)
signal affinity_changed(npc_id: String, new_value: int)
signal ui_notice_requested(message: String, notice_type: String)

const CLUE_RESOURCE_ROOT: String = "res://assets/objects/clues"
const SUSPICION_RESOURCE_ROOT: String = "res://assets/objects/suspicions"
const CLUE_RESOURCE_EXTENSION: String = "tres"
const SUSPICION_RESOURCE_EXTENSION: String = "tres"

var clue_defs: Dictionary[String, ClueData] = {}
var suspicion_defs: Dictionary[String, SuspicionData] = {}
var clue_states: Dictionary[String, Dictionary] = {}
var suspicions: Dictionary[String, Dictionary] = {}
var world_flags: Dictionary[String, bool] = {}
var affinity: Dictionary[String, int] = {}
var _discover_counter: int = 0
var _suspicion_discover_counter: int = 0


func _ready() -> void:
	_register_all_clue_defs()
	_register_all_suspicion_defs()


func reset_runtime_state() -> void:
	clue_states.clear()
	suspicions.clear()
	world_flags.clear()
	affinity.clear()
	_discover_counter = 0
	_suspicion_discover_counter = 0


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


func register_suspicion_def(suspicion_def: SuspicionData) -> void:
	if suspicion_def == null:
		return
	if suspicion_def.id.is_empty():
		push_warning("DataManager.register_suspicion_def(): suspicion id is empty.")
		return
	suspicion_defs[suspicion_def.id] = suspicion_def


func register_suspicion_defs(suspicion_def_list: Array[SuspicionData]) -> void:
	for suspicion_def: SuspicionData in suspicion_def_list:
		register_suspicion_def(suspicion_def)


func add_clue(clue_id: String, source_type: String = "scene", source_id: String = "") -> bool:
	if clue_id.is_empty():
		return false

	if not clue_defs.has(clue_id):
		push_warning("DataManager.add_clue(): clue id '%s' has no registered ClueData." % clue_id)

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


func add_suspicion(suspicion_id: String, source_type: String = "dialogue", source_id: String = "") -> bool:
	if suspicion_id.is_empty():
		return false

	if not suspicion_defs.has(suspicion_id):
		push_warning("DataManager.add_suspicion(): suspicion id '%s' has no registered SuspicionData." % suspicion_id)

	if has_suspicion(suspicion_id):
		return false

	var state: Dictionary = _create_default_suspicion_state(source_type, source_id)
	state["discovered"] = true
	_suspicion_discover_counter += 1
	state["discover_order"] = _suspicion_discover_counter
	suspicions[suspicion_id] = state

	suspicion_updated.emit(suspicion_id)
	_emit_new_suspicion_notice(suspicion_id)
	return true


func has_suspicion(suspicion_id: String) -> bool:
	if suspicion_id.is_empty():
		return false
	if not suspicions.has(suspicion_id):
		return false
	var state: Dictionary = suspicions[suspicion_id]
	return bool(state.get("discovered", false))


func get_suspicion_state(suspicion_id: String) -> Dictionary:
	if suspicion_id.is_empty():
		return {}
	if not suspicions.has(suspicion_id):
		return {}
	return suspicions[suspicion_id].duplicate(true)


func get_all_suspicions() -> PackedStringArray:
	var ordered_pairs: Array[Dictionary] = []
	for suspicion_id: String in suspicions.keys():
		var state: Dictionary = suspicions[suspicion_id]
		if not bool(state.get("discovered", false)):
			continue
		ordered_pairs.append({
			"suspicion_id": suspicion_id,
			"discover_order": int(state.get("discover_order", 0)),
		})

	ordered_pairs.sort_custom(_sort_suspicions_by_discover_order)

	var result: PackedStringArray = PackedStringArray()
	for pair: Dictionary in ordered_pairs:
		result.append(String(pair.get("suspicion_id", "")))
	return result


func is_suspicion_resolved(suspicion_id: String) -> bool:
	if suspicion_id.is_empty():
		return false
	if not suspicions.has(suspicion_id):
		return false
	var state: Dictionary = suspicions[suspicion_id]
	return bool(state.get("resolved", false))


func mark_suspicion_read(suspicion_id: String) -> void:
	if suspicion_id.is_empty():
		return
	if not suspicions.has(suspicion_id):
		return

	var state: Dictionary = suspicions[suspicion_id]
	if bool(state.get("read", false)):
		return

	state["read"] = true
	suspicions[suspicion_id] = state
	suspicion_updated.emit(suspicion_id)


func resolve_suspicion(suspicion_id: String) -> bool:
	if suspicion_id.is_empty():
		return false
	if not has_suspicion(suspicion_id):
		return false
	if is_suspicion_resolved(suspicion_id):
		return false

	var suspicion_def: SuspicionData = suspicion_defs.get(suspicion_id, null)
	if suspicion_def == null:
		push_warning("DataManager.resolve_suspicion(): suspicion id '%s' has no registered SuspicionData." % suspicion_id)
		return false

	var state: Dictionary = suspicions[suspicion_id]
	state["resolved"] = true
	state["read"] = true
	state["conclusion_clue_id"] = suspicion_def.conclusion_clue_id
	suspicions[suspicion_id] = state

	if not suspicion_def.conclusion_clue_id.is_empty():
		add_clue(suspicion_def.conclusion_clue_id, "reasoning", suspicion_id)

	for unlock_suspicion_id: String in suspicion_def.unlock_suspicion_ids:
		if unlock_suspicion_id.is_empty():
			continue
		add_suspicion(unlock_suspicion_id, "reasoning", suspicion_id)

	if not suspicion_def.resolved_world_flag.is_empty():
		set_world_flag(suspicion_def.resolved_world_flag, true)

	suspicion_updated.emit(suspicion_id)
	return true


func set_world_flag(flag_id: String, value: bool = true) -> void:
	if flag_id.is_empty():
		return
	world_flags[flag_id] = value


func get_world_flag(flag_id: String) -> bool:
	if flag_id.is_empty():
		return false
	return world_flags.get(flag_id, false)


func _register_all_clue_defs() -> void:
	_register_clue_defs_in_directory(CLUE_RESOURCE_ROOT)


func _register_all_suspicion_defs() -> void:
	_register_suspicion_defs_in_directory(SUSPICION_RESOURCE_ROOT)


func _register_clue_defs_in_directory(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_warning("DataManager: unable to open clue resource directory '%s'." % directory_path)
		return

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while not entry_name.is_empty():
		if entry_name.begins_with("."):
			entry_name = directory.get_next()
			continue

		var entry_path: String = directory_path.path_join(entry_name)
		if directory.current_is_dir():
			_register_clue_defs_in_directory(entry_path)
		elif entry_name.get_extension().to_lower() == CLUE_RESOURCE_EXTENSION:
			_try_register_clue_def_resource(entry_path)

		entry_name = directory.get_next()
	directory.list_dir_end()


func _try_register_clue_def_resource(resource_path: String) -> void:
	var resource: Resource = load(resource_path)
	if resource == null:
		push_warning("DataManager: failed to load clue resource '%s'." % resource_path)
		return
	if not (resource is ClueData):
		return

	register_clue_def(resource as ClueData)


func _register_suspicion_defs_in_directory(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_warning("DataManager: unable to open suspicion resource directory '%s'." % directory_path)
		return

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while not entry_name.is_empty():
		if entry_name.begins_with("."):
			entry_name = directory.get_next()
			continue

		var entry_path: String = directory_path.path_join(entry_name)
		if directory.current_is_dir():
			_register_suspicion_defs_in_directory(entry_path)
		elif entry_name.get_extension().to_lower() == SUSPICION_RESOURCE_EXTENSION:
			_try_register_suspicion_def_resource(entry_path)

		entry_name = directory.get_next()
	directory.list_dir_end()


func _try_register_suspicion_def_resource(resource_path: String) -> void:
	var resource: Resource = load(resource_path)
	if resource == null:
		push_warning("DataManager: failed to load suspicion resource '%s'." % resource_path)
		return
	if not (resource is SuspicionData):
		return

	register_suspicion_def(resource as SuspicionData)


func _create_default_clue_state(source_type: String, source_id: String) -> Dictionary:
	return {
		"discovered": false,
		"discover_order": 0,
		"read": false,
		"first_source_type": source_type,
		"first_source_id": source_id,
		"deep_unlocked": false,
	}


func _create_default_suspicion_state(source_type: String, source_id: String) -> Dictionary:
	return {
		"discovered": false,
		"discover_order": 0,
		"read": false,
		"resolved": false,
		"first_source_type": source_type,
		"first_source_id": source_id,
		"conclusion_clue_id": "",
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


func _emit_new_suspicion_notice(suspicion_id: String) -> void:
	var title: String = _get_suspicion_title(suspicion_id)
	ui_notice_requested.emit("发现新疑点：%s" % title, "suspicion")


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


func _get_suspicion_title(suspicion_id: String) -> String:
	var suspicion_def: SuspicionData = suspicion_defs.get(suspicion_id, null)
	if suspicion_def == null:
		return suspicion_id
	if suspicion_def.title.is_empty():
		return suspicion_id
	return suspicion_def.title


func _packed_string_array_equals(left: PackedStringArray, right: PackedStringArray) -> bool:
	if left.size() != right.size():
		return false
	for i: int in left.size():
		if left[i] != right[i]:
			return false
	return true


func _sort_by_discover_order(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("discover_order", 0)) < int(b.get("discover_order", 0))


func _sort_suspicions_by_discover_order(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("discover_order", 0)) < int(b.get("discover_order", 0))
