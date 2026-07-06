extends RefCounted

const FlowNpcs = preload("res://scripts/flow/flow_npcs.gd")
const FlowScenes = preload("res://scripts/flow/flow_scenes.gd")

var current_room: Node2D = null


func set_current_room(room: Node2D) -> void:
	current_room = room


func setup_room_actors(
	room: Node2D,
	current_room_id: String,
	spawn_entries: Array,
	free_interaction_timelines: Dictionary
) -> void:
	if room == null:
		return

	current_room = room
	var dynamic_root: Node2D = _get_or_create_dynamic_actors_root(room)
	_clear_dynamic_actors(dynamic_root)
	for spawn_data: Dictionary in spawn_entries:
		spawn_npc(spawn_data, room, current_room_id, free_interaction_timelines)


func spawn_npc(
	spawn_data: Dictionary,
	room: Node2D,
	current_room_id: String,
	free_interaction_timelines: Dictionary
) -> void:
	var npc_id: String = String(spawn_data.get("npc_id", ""))
	if npc_id.is_empty():
		return

	var spawn_name: String = String(spawn_data.get("spawn", ""))
	var spawn_point: Marker2D = _get_npc_spawn_point(room, spawn_name)
	var dynamic_root: Node2D = _get_or_create_dynamic_actors_root(room)
	if spawn_point == null or dynamic_root == null:
		push_warning("Flow actor spawner: missing NPC spawn '%s' in room '%s'." % [spawn_name, current_room_id])
		return

	var existing_npc: Node = dynamic_root.get_node_or_null("NPC_%s" % npc_id)
	if existing_npc != null:
		dynamic_root.remove_child(existing_npc)
		existing_npc.queue_free()

	var npc_scene_path: String = String(spawn_data.get("scene", FlowScenes.NPC))
	var scene: PackedScene = load(npc_scene_path) as PackedScene
	if scene == null:
		push_warning("Flow actor spawner: unable to load NPC scene '%s'." % npc_scene_path)
		return

	var npc: NpcDialogue = scene.instantiate() as NpcDialogue
	if npc == null:
		push_warning("Flow actor spawner: NPC scene root is not NpcDialogue: %s" % npc_scene_path)
		return

	npc.name = "NPC_%s" % npc_id
	npc.npc_id = npc_id
	npc.npc_name = String(FlowNpcs.NAMES.get(npc_id, npc_id))
	_apply_room_npc_settings(npc, room)

	var timeline_override: String = String(spawn_data.get("timeline", ""))
	if timeline_override.is_empty():
		npc.timeline_name = String(free_interaction_timelines.get(npc_id, ""))
	else:
		npc.timeline_name = timeline_override.replace("{npc_id}", npc_id)

	dynamic_root.add_child(npc)
	npc.global_position = spawn_point.global_position


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
