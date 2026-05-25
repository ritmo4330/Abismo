extends Node

const PLACEMENT_RESOURCE_ROOT: String = "res://assets/objects/clue_placements"
const PLACEMENT_RESOURCE_EXTENSION: String = "tres"
const DEFAULT_CLUE_ITEM_SCENE_PATH: String = "res://scenes/objects/clue_item.tscn"

var placements_by_room_id: Dictionary[String, Array] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_all_placements()

	if not EventBus.room_loaded.is_connected(_on_room_loaded):
		EventBus.room_loaded.connect(_on_room_loaded)


func register_placement(placement: CluePlacementData) -> void:
	if placement == null:
		return
	if placement.placement_id.is_empty():
		push_warning("CluePlacementManager.register_placement(): placement_id is empty.")
		return
	if placement.clue_id.is_empty():
		push_warning("CluePlacementManager.register_placement(): clue_id is empty for '%s'." % placement.placement_id)
		return
	if placement.room_id.is_empty():
		push_warning("CluePlacementManager.register_placement(): room_id is empty for '%s'." % placement.placement_id)
		return
	if placement.spawn_name.is_empty():
		push_warning("CluePlacementManager.register_placement(): spawn_name is empty for '%s'." % placement.placement_id)
		return

	if not placements_by_room_id.has(placement.room_id):
		placements_by_room_id[placement.room_id] = []
	placements_by_room_id[placement.room_id].append(placement)


func setup_room_clues(room: Node2D, room_id: String) -> void:
	if room == null:
		return

	var dynamic_root: Node2D = _get_or_create_dynamic_clues_root(room)
	_clear_dynamic_clues(dynamic_root)

	var placements: Array = placements_by_room_id.get(room_id, [])
	for placement_value: Variant in placements:
		if not (placement_value is CluePlacementData):
			continue
		var placement: CluePlacementData = placement_value as CluePlacementData
		if not _is_placement_available(placement, room_id):
			continue
		_spawn_clue_item(placement, room)


func _on_room_loaded(room: Node2D, room_id: String) -> void:
	setup_room_clues(room, room_id)


func _register_all_placements() -> void:
	placements_by_room_id.clear()
	_register_placements_in_directory(PLACEMENT_RESOURCE_ROOT)


func _register_placements_in_directory(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_warning("CluePlacementManager: unable to open placement directory '%s'." % directory_path)
		return

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while not entry_name.is_empty():
		if entry_name.begins_with("."):
			entry_name = directory.get_next()
			continue

		var resource_name: String = _normalize_exported_resource_name(entry_name)
		var entry_path: String = directory_path.path_join(resource_name)
		if directory.current_is_dir():
			_register_placements_in_directory(entry_path)
		elif resource_name.get_extension().to_lower() == PLACEMENT_RESOURCE_EXTENSION:
			_try_register_placement_resource(entry_path)

		entry_name = directory.get_next()
	directory.list_dir_end()


func _try_register_placement_resource(resource_path: String) -> void:
	var resource: Resource = load(resource_path)
	if resource == null:
		push_warning("CluePlacementManager: failed to load placement resource '%s'." % resource_path)
		return
	if not (resource is CluePlacementData):
		return

	register_placement(resource as CluePlacementData)


func _normalize_exported_resource_name(entry_name: String) -> String:
	if entry_name.ends_with(".remap"):
		return entry_name.trim_suffix(".remap")
	return entry_name


func _is_placement_available(placement: CluePlacementData, room_id: String) -> bool:
	if placement.room_id != room_id:
		return false

	if not placement.available_steps.is_empty():
		if FlowManager == null:
			return false
		if not placement.available_steps.has(FlowManager.current_step_id):
			return false

	for flag_id: String in placement.required_flags:
		if not DataManager.get_world_flag(flag_id):
			return false

	for flag_id: String in placement.blocked_flags:
		if DataManager.get_world_flag(flag_id):
			return false

	if placement.hide_after_discovered and DataManager.has_clue(placement.clue_id):
		return false

	return true


func _spawn_clue_item(placement: CluePlacementData, room: Node2D) -> void:
	var spawn_point: Marker2D = _get_clue_spawn_point(room, placement.spawn_name)
	var dynamic_root: Node2D = _get_or_create_dynamic_clues_root(room)
	if spawn_point == null or dynamic_root == null:
		push_warning("CluePlacementManager: missing clue spawn '%s' in room '%s'." % [placement.spawn_name, placement.room_id])
		return

	var scene_path: String = placement.scene_path
	if scene_path.is_empty():
		scene_path = DEFAULT_CLUE_ITEM_SCENE_PATH

	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_warning("CluePlacementManager: unable to load clue scene '%s'." % scene_path)
		return

	var clue_item: ClueItem = scene.instantiate() as ClueItem
	if clue_item == null:
		push_warning("CluePlacementManager: clue scene root is not ClueItem: %s" % scene_path)
		return

	clue_item.name = "Clue_%s" % placement.placement_id
	clue_item.clue_id = placement.clue_id
	clue_item.clue_def = _get_clue_def(placement.clue_id)
	clue_item.interact_id = _resolve_interact_id(placement)
	clue_item.source_id = _resolve_source_id(placement)

	dynamic_root.add_child(clue_item)
	clue_item.global_position = spawn_point.global_position


func _get_clue_def(clue_id: String) -> ClueData:
	if clue_id.is_empty():
		return null
	var clue_def_variant: Variant = DataManager.clue_defs.get(clue_id, null)
	if clue_def_variant is ClueData:
		return clue_def_variant as ClueData
	push_warning("CluePlacementManager: clue id '%s' has no registered ClueData." % clue_id)
	return null


func _resolve_interact_id(placement: CluePlacementData) -> String:
	if not placement.interact_id.is_empty():
		return placement.interact_id
	return placement.placement_id


func _resolve_source_id(placement: CluePlacementData) -> String:
	if not placement.source_id.is_empty():
		return placement.source_id
	return placement.placement_id


func _get_or_create_dynamic_clues_root(room: Node2D) -> Node2D:
	var dynamic_root: Node2D = null
	if room.has_method("get_dynamic_clues_root"):
		dynamic_root = room.get_dynamic_clues_root()
	else:
		dynamic_root = room.find_child("DynamicClues", true, false) as Node2D

	if dynamic_root != null:
		return dynamic_root

	dynamic_root = Node2D.new()
	dynamic_root.name = "DynamicClues"
	dynamic_root.y_sort_enabled = true
	room.add_child(dynamic_root)
	return dynamic_root


func _clear_dynamic_clues(dynamic_root: Node2D) -> void:
	if dynamic_root == null:
		return
	for child: Node in dynamic_root.get_children():
		dynamic_root.remove_child(child)
		child.queue_free()


func _get_clue_spawn_point(room: Node2D, spawn_name: String) -> Marker2D:
	if room == null or spawn_name.is_empty():
		return null
	if room.has_method("get_clue_spawn_point"):
		return room.get_clue_spawn_point(spawn_name)
	return room.find_child(spawn_name, true, false) as Marker2D
