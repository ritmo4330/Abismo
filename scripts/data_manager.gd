extends Node

signal clue_updated(clue_id: String)
signal suspicion_updated(suspicion_id: String)
signal affinity_changed(npc_id: String, new_value: int)

var clues: Dictionary[String, Variant] = {}
var suspicions: Dictionary[String, Variant] = {}
var world_flags: Dictionary[String, bool] = {}
var affinity: Dictionary[String, int] = {}


func set_world_flag(flag_id: String, value: bool = true) -> void:
	if flag_id.is_empty():
		return
	world_flags[flag_id] = value


func get_world_flag(flag_id: String) -> bool:
	if flag_id.is_empty():
		return false
	return world_flags.get(flag_id, false)
