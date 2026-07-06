extends RefCounted

const FlowTransition = preload("res://scripts/flow/flow_transition.gd")

var chapter_id: String = ""
var entry_transitions: Dictionary = {}
var event_transitions: Dictionary = {}
var step_bgm_configs: Dictionary = {}
var base_npc_locations_by_step: Dictionary = {}
var free_interaction_timelines: Dictionary = {}
var manual_unlocked_steps: Array = []
var initial_search_required_clues: Array = []
var follow_npc_rules_by_step: Dictionary = {}
var debug_step_by_room: Dictionary = {}


func _init(next_chapter_id: String = "") -> void:
	chapter_id = next_chapter_id


func get_entry_transition(entry_id: String) -> RefCounted:
	var transition: Variant = entry_transitions.get(entry_id, null)
	if transition is RefCounted:
		return transition
	return FlowTransition.unhandled()


func get_event_transition(event_id: String) -> RefCounted:
	var transition: Variant = event_transitions.get(event_id, null)
	if transition is RefCounted:
		return transition
	return FlowTransition.unhandled()


func get_bgm_config(step_id: String) -> Dictionary:
	var config: Variant = step_bgm_configs.get(step_id, null)
	if config is Dictionary:
		return config
	return {}


func get_base_npc_locations(step_id: String) -> Dictionary:
	var locations: Variant = base_npc_locations_by_step.get(step_id, null)
	if locations is Dictionary:
		return locations
	return {}


func get_follow_npc_rules(step_id: String) -> Array:
	var rules: Variant = follow_npc_rules_by_step.get(step_id, [])
	if rules is Array:
		return rules
	return []


func resolve_debug_step(room_id: String, fallback_step_id: String) -> String:
	var step_id: String = String(debug_step_by_room.get(room_id, ""))
	if step_id.is_empty():
		return fallback_step_id
	return step_id
