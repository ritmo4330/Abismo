class_name ClueService
extends RefCounted

const ContentRegistry = preload("res://scripts/data/content_registry.gd")
const GameStateStore = preload("res://scripts/data/game_state_store.gd")
const ClueState = preload("res://scripts/data/clue_state.gd")

signal clue_discovered(clue_id: String)
signal clue_updated(clue_id: String)
signal deep_clues_unlocked(parent_clue_id: String, child_clue_ids: PackedStringArray)

var _store: GameStateStore
var _registry: ContentRegistry


func setup(store: GameStateStore, registry: ContentRegistry) -> void:
	_store = store
	_registry = registry


func discover_clue(clue_id: String, source_type: String = "scene", source_id: String = "") -> bool:
	if clue_id.is_empty():
		return false
	if not _registry.has_clue_def(clue_id):
		push_error("ClueService.discover_clue(): clue id '%s' has no registered ClueData." % clue_id)
		return false
	if has_clue(clue_id):
		return false

	_store.clue_states[clue_id] = ClueState.create_discovered(
		source_type,
		source_id,
		_store.next_clue_discover_order()
	)
	clue_updated.emit(clue_id)
	clue_discovered.emit(clue_id)
	return true


func has_clue(clue_id: String) -> bool:
	if clue_id.is_empty() or not _store.clue_states.has(clue_id):
		return false
	return _store.clue_states[clue_id].discovered


func mark_read(clue_id: String) -> void:
	if clue_id.is_empty() or not _store.clue_states.has(clue_id):
		return

	var state: ClueState = _store.clue_states[clue_id]
	if state.read:
		return
	state.read = true
	clue_updated.emit(clue_id)


func get_state(clue_id: String) -> ClueState:
	if clue_id.is_empty() or not _store.clue_states.has(clue_id):
		return null
	return _store.clue_states[clue_id].duplicate_state()


func get_discovered_clue_ids(_sort_mode: String = "discover") -> PackedStringArray:
	var ordered_pairs: Array[Dictionary] = []
	for clue_id: String in _store.clue_states.keys():
		var state: ClueState = _store.clue_states[clue_id]
		if not state.discovered:
			continue
		ordered_pairs.append({
			"id": clue_id,
			"order": state.discover_order,
		})

	ordered_pairs.sort_custom(_sort_by_order)

	var result: PackedStringArray = PackedStringArray()
	for pair: Dictionary in ordered_pairs:
		result.append(String(pair.get("id", "")))
	return result


func get_clues_by_category_path(path: PackedStringArray) -> PackedStringArray:
	if path.is_empty():
		return PackedStringArray()

	var result: PackedStringArray = PackedStringArray()
	for clue_id: String in get_discovered_clue_ids():
		var clue_def: ClueData = _registry.get_clue_def(clue_id)
		if clue_def == null:
			continue
		if _packed_string_array_equals(clue_def.category_path, path):
			result.append(clue_id)
	return result


func get_clues_by_tag(tag: String) -> PackedStringArray:
	if tag.is_empty():
		return PackedStringArray()

	var result: PackedStringArray = PackedStringArray()
	for clue_id: String in get_discovered_clue_ids():
		var clue_def: ClueData = _registry.get_clue_def(clue_id)
		if clue_def != null and clue_def.tags.has(tag):
			result.append(clue_id)
	return result


func get_parent_clue_id(clue_id: String) -> String:
	var clue_def: ClueData = _registry.get_clue_def(clue_id)
	if clue_def == null:
		return ""
	return clue_def.parent_clue_id


func get_child_clue_ids(clue_id: String) -> PackedStringArray:
	var clue_def: ClueData = _registry.get_clue_def(clue_id)
	if clue_def == null:
		return PackedStringArray()
	return clue_def.child_clue_ids.duplicate()


func is_deep_unlocked(parent_clue_id: String) -> bool:
	if parent_clue_id.is_empty() or not _store.clue_states.has(parent_clue_id):
		return false
	return _store.clue_states[parent_clue_id].deep_unlocked


func unlock_deep_clues(parent_clue_id: String) -> PackedStringArray:
	if parent_clue_id.is_empty() or not has_clue(parent_clue_id):
		return PackedStringArray()

	var parent_state: ClueState = _store.clue_states[parent_clue_id]
	if parent_state.deep_unlocked:
		return PackedStringArray()

	parent_state.deep_unlocked = true
	var newly_discovered_child_ids: PackedStringArray = PackedStringArray()
	for child_id: String in get_child_clue_ids(parent_clue_id):
		if child_id.is_empty() or has_clue(child_id):
			continue
		if not _registry.has_clue_def(child_id):
			push_error("ClueService.unlock_deep_clues(): child clue id '%s' has no registered ClueData." % child_id)
			continue
		_store.clue_states[child_id] = ClueState.create_discovered(
			"scene",
			parent_clue_id,
			_store.next_clue_discover_order()
		)
		newly_discovered_child_ids.append(child_id)

	clue_updated.emit(parent_clue_id)
	deep_clues_unlocked.emit(parent_clue_id, newly_discovered_child_ids)
	return newly_discovered_child_ids


func _packed_string_array_equals(left: PackedStringArray, right: PackedStringArray) -> bool:
	if left.size() != right.size():
		return false
	for i: int in left.size():
		if left[i] != right[i]:
			return false
	return true


func _sort_by_order(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("order", 0)) < int(b.get("order", 0))
