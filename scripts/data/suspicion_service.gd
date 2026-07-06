class_name SuspicionService
extends RefCounted

const ContentRegistry = preload("res://scripts/data/content_registry.gd")
const GameStateStore = preload("res://scripts/data/game_state_store.gd")
const SuspicionState = preload("res://scripts/data/suspicion_state.gd")

signal suspicion_discovered(suspicion_id: String)
signal suspicion_updated(suspicion_id: String)

var _store: GameStateStore
var _registry: ContentRegistry


func setup(store: GameStateStore, registry: ContentRegistry) -> void:
	_store = store
	_registry = registry


func discover_suspicion(suspicion_id: String, source_type: String = "dialogue", source_id: String = "") -> bool:
	if suspicion_id.is_empty():
		return false
	if not _registry.has_suspicion_def(suspicion_id):
		push_error("SuspicionService.discover_suspicion(): suspicion id '%s' has no registered SuspicionData." % suspicion_id)
		return false
	if has_suspicion(suspicion_id):
		return false

	_store.suspicion_states[suspicion_id] = SuspicionState.create_discovered(
		source_type,
		source_id,
		_store.next_suspicion_discover_order()
	)
	suspicion_updated.emit(suspicion_id)
	suspicion_discovered.emit(suspicion_id)
	return true


func has_suspicion(suspicion_id: String) -> bool:
	if suspicion_id.is_empty() or not _store.suspicion_states.has(suspicion_id):
		return false
	return _store.suspicion_states[suspicion_id].discovered


func get_state(suspicion_id: String) -> SuspicionState:
	if suspicion_id.is_empty() or not _store.suspicion_states.has(suspicion_id):
		return null
	return _store.suspicion_states[suspicion_id].duplicate_state()


func get_discovered_suspicion_ids(_sort_mode: String = "discover") -> PackedStringArray:
	var ordered_pairs: Array[Dictionary] = []
	for suspicion_id: String in _store.suspicion_states.keys():
		var state: SuspicionState = _store.suspicion_states[suspicion_id]
		if not state.discovered:
			continue
		ordered_pairs.append({
			"id": suspicion_id,
			"order": state.discover_order,
		})

	ordered_pairs.sort_custom(_sort_by_order)

	var result: PackedStringArray = PackedStringArray()
	for pair: Dictionary in ordered_pairs:
		result.append(String(pair.get("id", "")))
	return result


func is_resolved(suspicion_id: String) -> bool:
	if suspicion_id.is_empty() or not _store.suspicion_states.has(suspicion_id):
		return false
	return _store.suspicion_states[suspicion_id].resolved


func mark_read(suspicion_id: String) -> void:
	if suspicion_id.is_empty() or not _store.suspicion_states.has(suspicion_id):
		return

	var state: SuspicionState = _store.suspicion_states[suspicion_id]
	if state.read:
		return
	state.read = true
	suspicion_updated.emit(suspicion_id)


func mark_resolved(suspicion_id: String, conclusion_clue_id: String) -> bool:
	if suspicion_id.is_empty() or not has_suspicion(suspicion_id) or is_resolved(suspicion_id):
		return false

	var state: SuspicionState = _store.suspicion_states[suspicion_id]
	state.resolved = true
	state.read = true
	state.conclusion_clue_id = conclusion_clue_id
	suspicion_updated.emit(suspicion_id)
	return true


func _sort_by_order(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("order", 0)) < int(b.get("order", 0))
