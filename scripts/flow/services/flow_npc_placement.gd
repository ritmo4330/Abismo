extends RefCounted

const FlowIds = preload("res://scripts/flow/flow_ids.gd")
const Ch0FlowConfig = preload("res://scripts/flow/configs/ch0_flow_config.gd")
const Ch1FlowConfig = preload("res://scripts/flow/configs/ch1_flow_config.gd")

var current_room: Node2D = null

var _npc_locations: Dictionary = {}


func set_current_room(room: Node2D) -> void:
	current_room = room


func reset_npc_locations_for_step(step_id: String) -> void:
	_npc_locations.clear()

	var base_locations: Dictionary = _get_base_npc_locations_for_step(step_id)
	for npc_id in base_locations.keys():
		var location_value: Variant = base_locations[npc_id]
		if not (location_value is Dictionary):
			continue
		_npc_locations[String(npc_id)] = (location_value as Dictionary).duplicate(true)


func set_npc_location(
	npc_id: String,
	room_id: String,
	spawn_name: String,
	timeline_name: String,
	scene_path: String,
	current_room_id: String,
	current_chapter_id: String,
	current_step_id: String,
	private_chat_target: String
) -> void:
	if npc_id.is_empty():
		return
	if room_id.is_empty() or spawn_name.is_empty():
		_npc_locations.erase(npc_id)
		_remove_spawned_npc(_resolve_npc_id(npc_id, private_chat_target))
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
	_refresh_spawned_npc(npc_id, location, current_room_id, current_chapter_id, current_step_id, private_chat_target)


func setup_room_actors(
	room: Node2D,
	current_room_id: String,
	current_chapter_id: String,
	current_step_id: String,
	private_chat_target: String
) -> void:
	if room == null:
		return

	var dynamic_root: Node2D = _get_or_create_dynamic_actors_root(room)
	_clear_dynamic_actors(dynamic_root)

	var spawn_entries: Array = _get_spawn_entries_for_room(current_room_id, current_chapter_id, current_step_id)
	for spawn_data: Dictionary in spawn_entries:
		spawn_npc(spawn_data, room, current_room_id, current_chapter_id, private_chat_target)


func refresh_current_room_actors(
	current_room_id: String,
	current_chapter_id: String,
	current_step_id: String,
	private_chat_target: String
) -> void:
	if current_room == null or current_room_id.is_empty():
		return
	setup_room_actors(current_room, current_room_id, current_chapter_id, current_step_id, private_chat_target)


func spawn_npc(
	spawn_data: Dictionary,
	room: Node2D,
	current_room_id: String,
	current_chapter_id: String,
	private_chat_target: String
) -> void:
	var npc_id: String = _resolve_npc_id(String(spawn_data.get("npc_id", "")), private_chat_target)
	if npc_id.is_empty():
		return

	var spawn_name: String = String(spawn_data.get("spawn", ""))
	var spawn_point: Marker2D = _get_npc_spawn_point(room, spawn_name)
	var dynamic_root: Node2D = _get_or_create_dynamic_actors_root(room)
	if spawn_point == null or dynamic_root == null:
		push_warning("FlowManager: missing NPC spawn '%s' in room '%s'." % [spawn_name, current_room_id])
		return

	var existing_npc: Node = dynamic_root.get_node_or_null("NPC_%s" % npc_id)
	if existing_npc != null:
		dynamic_root.remove_child(existing_npc)
		existing_npc.queue_free()

	var npc_scene_path: String = String(spawn_data.get("scene", FlowIds.NPC_SCENE_PATH))
	var scene: PackedScene = load(npc_scene_path) as PackedScene
	if scene == null:
		push_warning("FlowManager: unable to load NPC scene '%s'." % npc_scene_path)
		return

	var npc: NpcDialogue = scene.instantiate() as NpcDialogue
	if npc == null:
		push_warning("FlowManager: NPC scene root is not NpcDialogue: %s" % npc_scene_path)
		return

	npc.name = "NPC_%s" % npc_id
	npc.npc_id = npc_id
	npc.npc_name = String(FlowIds.NPC_NAMES.get(npc_id, npc_id))
	_apply_room_npc_settings(npc, room)
	var timeline_override: String = String(spawn_data.get("timeline", ""))
	if timeline_override.is_empty():
		apply_free_timeline(npc, current_chapter_id)
	else:
		npc.timeline_name = timeline_override.replace("{npc_id}", npc_id)

	dynamic_root.add_child(npc)
	npc.global_position = spawn_point.global_position


func apply_free_timeline(npc: NpcDialogue, current_chapter_id: String) -> void:
	if npc == null:
		return

	var chapter_routes: Dictionary = Ch1FlowConfig.FREE_INTERACTION_TIMELINES.get(current_chapter_id, {})
	if not chapter_routes.has(npc.npc_id):
		return
	npc.timeline_name = String(chapter_routes[npc.npc_id])


func _refresh_spawned_npc(
	npc_id: String,
	location: Dictionary,
	current_room_id: String,
	current_chapter_id: String,
	current_step_id: String,
	private_chat_target: String
) -> void:
	if current_room == null or current_room_id.is_empty():
		return

	var resolved_npc_id: String = _resolve_npc_id(npc_id, private_chat_target)
	if resolved_npc_id.is_empty():
		return

	_remove_spawned_npc(resolved_npc_id)
	if String(location.get("room_id", "")) != current_room_id:
		return

	var spawn_data: Dictionary = location.duplicate(true)
	spawn_data["npc_id"] = resolved_npc_id
	spawn_npc(spawn_data, current_room, current_room_id, current_chapter_id, private_chat_target)


func _remove_spawned_npc(npc_id: String) -> void:
	if current_room == null or npc_id.is_empty():
		return

	var dynamic_root: Node2D = _get_or_create_dynamic_actors_root(current_room)
	if dynamic_root == null:
		return

	var node_name: String = "NPC_%s" % npc_id
	var npc_node: Node = dynamic_root.get_node_or_null(node_name)
	if npc_node == null:
		return

	dynamic_root.remove_child(npc_node)
	npc_node.queue_free()


func _get_base_npc_locations_for_step(step_id: String) -> Dictionary:
	var config_tables: Array = [
		Ch0FlowConfig.BASE_NPC_LOCATIONS_BY_STEP,
		Ch1FlowConfig.BASE_NPC_LOCATIONS_BY_STEP,
	]
	for config_table: Dictionary in config_tables:
		var base_locations: Variant = config_table.get(step_id, null)
		if base_locations is Dictionary:
			return base_locations
	return {}


func _get_spawn_entries_for_room(room_id: String, current_chapter_id: String, current_step_id: String) -> Array:
	var spawn_entries: Array = []
	var has_butler_in_room: bool = false
	for npc_id in _npc_locations.keys():
		var location_value: Variant = _npc_locations[npc_id]
		if not (location_value is Dictionary):
			continue

		var location: Dictionary = location_value as Dictionary
		if String(location.get("room_id", "")) != room_id:
			continue

		if String(npc_id) == "butler":
			has_butler_in_room = true
		var spawn_data: Dictionary = location.duplicate(true)
		spawn_data["npc_id"] = String(npc_id)
		spawn_entries.append(spawn_data)
	if _should_spawn_following_butler(room_id, current_chapter_id, current_step_id) and not has_butler_in_room:
		spawn_entries.append({
			"npc_id": "butler",
			"room_id": room_id,
			"spawn": "Butler",
		})
	return spawn_entries


func _should_spawn_following_butler(room_id: String, current_chapter_id: String, current_step_id: String) -> bool:
	if current_chapter_id != FlowIds.CHAPTER_CH1:
		return false
	if current_step_id != FlowIds.STEP_CH1_FIRST_SEARCH:
		return false
	return Ch1FlowConfig.FIRST_SEARCH_BUTLER_FOLLOW_ROOMS.has(room_id)


func _resolve_npc_id(raw_npc_id: String, private_chat_target: String) -> String:
	if raw_npc_id == "{private_chat_target}":
		return private_chat_target
	return raw_npc_id


func _get_or_create_dynamic_actors_root(room: Node2D) -> Node2D:
	var dynamic_root: Node2D = null
	if room.has_method("get_dynamic_actors_root"):
		dynamic_root = room.get_dynamic_actors_root()
	else:
		dynamic_root = room.find_child("DynamicActors", true, false) as Node2D

	if dynamic_root != null:
		return dynamic_root

	dynamic_root = Node2D.new()
	dynamic_root.name = "DynamicActors"
	dynamic_root.y_sort_enabled = true
	room.add_child(dynamic_root)
	return dynamic_root


func _clear_dynamic_actors(dynamic_root: Node2D) -> void:
	if dynamic_root == null:
		return
	for child: Node in dynamic_root.get_children():
		dynamic_root.remove_child(child)
		child.queue_free()


func _get_npc_spawn_point(room: Node2D, spawn_name: String) -> Marker2D:
	if room == null or spawn_name.is_empty():
		return null
	if room.has_method("get_npc_spawn_point"):
		return room.get_npc_spawn_point(spawn_name)
	return room.find_child(spawn_name, true, false) as Marker2D


func _apply_room_npc_settings(npc: NpcDialogue, room: Node2D) -> void:
	if npc == null or room == null:
		return
	var room_npc_scale: Variant = room.get("npc_spawn_scale")
	if room_npc_scale is Vector2 and not (room_npc_scale as Vector2).is_zero_approx():
		npc.scale = room_npc_scale
