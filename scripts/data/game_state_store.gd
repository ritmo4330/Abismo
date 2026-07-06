class_name GameStateStore
extends RefCounted

const ClueState = preload("res://scripts/data/clue_state.gd")
const SuspicionState = preload("res://scripts/data/suspicion_state.gd")

const SAVE_VERSION: int = 1

var clue_states: Dictionary[String, ClueState] = {}
var suspicion_states: Dictionary[String, SuspicionState] = {}
var world_flags: Dictionary[String, bool] = {}
var affinity: Dictionary[String, int] = {}
var clue_discover_counter: int = 0
var suspicion_discover_counter: int = 0


func reset() -> void:
	clue_states.clear()
	suspicion_states.clear()
	world_flags.clear()
	affinity.clear()
	clue_discover_counter = 0
	suspicion_discover_counter = 0


func next_clue_discover_order() -> int:
	clue_discover_counter += 1
	return clue_discover_counter


func next_suspicion_discover_order() -> int:
	suspicion_discover_counter += 1
	return suspicion_discover_counter


func to_dict() -> Dictionary:
	var saved_clues: Dictionary = {}
	for clue_id: String in clue_states.keys():
		saved_clues[clue_id] = clue_states[clue_id].to_dict()

	var saved_suspicions: Dictionary = {}
	for suspicion_id: String in suspicion_states.keys():
		saved_suspicions[suspicion_id] = suspicion_states[suspicion_id].to_dict()

	return {
		"version": SAVE_VERSION,
		"clue_states": saved_clues,
		"suspicion_states": saved_suspicions,
		"world_flags": world_flags.duplicate(true),
		"affinity": affinity.duplicate(true),
		"clue_discover_counter": clue_discover_counter,
		"suspicion_discover_counter": suspicion_discover_counter,
	}


func from_dict(data: Dictionary) -> void:
	reset()

	var raw_clues: Dictionary = data.get("clue_states", {})
	for clue_id_value: Variant in raw_clues.keys():
		var clue_id: String = String(clue_id_value)
		var raw_state: Variant = raw_clues[clue_id_value]
		if raw_state is Dictionary:
			clue_states[clue_id] = ClueState.from_dict(raw_state as Dictionary)

	var raw_suspicions: Dictionary = data.get("suspicion_states", data.get("suspicions", {}))
	for suspicion_id_value: Variant in raw_suspicions.keys():
		var suspicion_id: String = String(suspicion_id_value)
		var raw_state: Variant = raw_suspicions[suspicion_id_value]
		if raw_state is Dictionary:
			suspicion_states[suspicion_id] = SuspicionState.from_dict(raw_state as Dictionary)

	var raw_world_flags: Dictionary = data.get("world_flags", {})
	for flag_id_value: Variant in raw_world_flags.keys():
		world_flags[String(flag_id_value)] = bool(raw_world_flags[flag_id_value])

	var raw_affinity: Dictionary = data.get("affinity", {})
	for npc_id_value: Variant in raw_affinity.keys():
		affinity[String(npc_id_value)] = int(raw_affinity[npc_id_value])

	clue_discover_counter = int(data.get("clue_discover_counter", _max_clue_discover_order()))
	suspicion_discover_counter = int(data.get("suspicion_discover_counter", _max_suspicion_discover_order()))


func _max_clue_discover_order() -> int:
	var result: int = 0
	for state: ClueState in clue_states.values():
		result = max(result, state.discover_order)
	return result


func _max_suspicion_discover_order() -> int:
	var result: int = 0
	for state: SuspicionState in suspicion_states.values():
		result = max(result, state.discover_order)
	return result
