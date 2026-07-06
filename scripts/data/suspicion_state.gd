class_name SuspicionState
extends RefCounted

var discovered: bool = false
var discover_order: int = 0
var read: bool = false
var resolved: bool = false
var first_source_type: String = ""
var first_source_id: String = ""
var conclusion_clue_id: String = ""


static func create_discovered(source_type: String, source_id: String, order: int):
	var state = new()
	state.discovered = true
	state.discover_order = order
	state.first_source_type = source_type
	state.first_source_id = source_id
	return state


static func from_dict(data: Dictionary):
	var state = new()
	state.discovered = bool(data.get("discovered", false))
	state.discover_order = int(data.get("discover_order", 0))
	state.read = bool(data.get("read", false))
	state.resolved = bool(data.get("resolved", false))
	state.first_source_type = String(data.get("first_source_type", ""))
	state.first_source_id = String(data.get("first_source_id", ""))
	state.conclusion_clue_id = String(data.get("conclusion_clue_id", ""))
	return state


func duplicate_state():
	var state = new()
	state.discovered = discovered
	state.discover_order = discover_order
	state.read = read
	state.resolved = resolved
	state.first_source_type = first_source_type
	state.first_source_id = first_source_id
	state.conclusion_clue_id = conclusion_clue_id
	return state


func to_dict() -> Dictionary:
	return {
		"discovered": discovered,
		"discover_order": discover_order,
		"read": read,
		"resolved": resolved,
		"first_source_type": first_source_type,
		"first_source_id": first_source_id,
		"conclusion_clue_id": conclusion_clue_id,
	}
