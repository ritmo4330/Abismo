extends RefCounted

const FlowNpcs = preload("res://scripts/flow/flow_npcs.gd")

var _npc_locations: Dictionary = {}


func reset_for_step(base_locations: Dictionary) -> void:
	_npc_locations.clear()
	for npc_id: Variant in base_locations.keys():
		var location_value: Variant = base_locations[npc_id]
		if location_value is Dictionary:
			_npc_locations[String(npc_id)] = (location_value as Dictionary).duplicate(true)


func set_location(
	npc_id: String,
	room_id: String,
	spawn_name: String,
	timeline_name: String = "",
	scene_path: String = ""
) -> void:
	if npc_id.is_empty():
		return
	if room_id.is_empty() or spawn_name.is_empty():
		_npc_locations.erase(npc_id)
		return

	var location: Dictionary = {
		"room_id": room_id,
		"spawn": spawn_name,
	}
	if not timeline_name.is_empty():
		location["timeline"] = timeline_name
	if not scene_path.is_empty():
		location["scene"] = scene_path
	_npc_locations[npc_id] = location


func get_spawn_entries_for_room(
	room_id: String,
	chapter_definition: RefCounted,
	current_step_id: String,
	private_chat_target: String
) -> Array:
	var spawn_entries: Array = []
	var npc_ids_in_room: Dictionary = {}
	for npc_id: Variant in _npc_locations.keys():
		var location_value: Variant = _npc_locations[npc_id]
		if not (location_value is Dictionary):
			continue

		var location: Dictionary = location_value as Dictionary
		if String(location.get("room_id", "")) != room_id:
			continue

		var resolved_npc_id: String = _resolve_npc_id(String(npc_id), private_chat_target)
		if resolved_npc_id.is_empty():
			continue

		npc_ids_in_room[resolved_npc_id] = true
		var spawn_data: Dictionary = location.duplicate(true)
		spawn_data["npc_id"] = resolved_npc_id
		spawn_entries.append(spawn_data)

	if chapter_definition != null:
		_append_following_npc_entries(spawn_entries, npc_ids_in_room, room_id, chapter_definition, current_step_id)
	return spawn_entries


func _append_following_npc_entries(
	spawn_entries: Array,
	npc_ids_in_room: Dictionary,
	room_id: String,
	chapter_definition: RefCounted,
	current_step_id: String
) -> void:
	for rule_value: Variant in chapter_definition.get_follow_npc_rules(current_step_id):
		if not (rule_value is Dictionary):
			continue

		var rule: Dictionary = rule_value as Dictionary
		var npc_id: String = String(rule.get("npc_id", ""))
		if npc_id.is_empty() or npc_ids_in_room.has(npc_id):
			continue

		var rooms: Array = rule.get("rooms", [])
		if not rooms.has(room_id):
			continue

		spawn_entries.append({
			"npc_id": npc_id,
			"room_id": room_id,
			"spawn": String(rule.get("spawn", "")),
			"timeline": String(rule.get("timeline", "")),
			"scene": String(rule.get("scene", "")),
		})


func _resolve_npc_id(raw_npc_id: String, private_chat_target: String) -> String:
	if raw_npc_id == FlowNpcs.PRIVATE_CHAT_TARGET_TOKEN:
		return private_chat_target
	return raw_npc_id
