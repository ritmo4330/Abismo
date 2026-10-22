extends Node

const DEFAULT_FIRST_LEVEL_PATH: String = "res://scenes/rooms/hall.tscn"
const DEFAULT_PLAYER_SCENE_PATH: String = "res://scenes/characters/player/player.tscn"
const STATIC_PRESENTATION_MODE: bool = true
const StaticRoomArt = preload("res://scripts/scenes/static_room_art.gd")

var level_container: Node2D = null
var current_player: Node2D = null
var current_room: Node2D = null
var is_transitioning: bool = false

var _host_root: Node2D = null
var _is_initialized: bool = false


func _ready() -> void:
	if not EventBus.scene_change_requested.is_connected(_on_scene_change_requested):
		EventBus.scene_change_requested.connect(_on_scene_change_requested)


func is_initialized() -> bool:
	return _is_initialized


func is_static_presentation_mode() -> bool:
	return STATIC_PRESENTATION_MODE


func get_current_room_scene_path() -> String:
	if current_room == null or not is_instance_valid(current_room):
		return ""
	return current_room.scene_file_path


func get_player_global_position() -> Vector2:
	if current_player == null or not is_instance_valid(current_player):
		return Vector2.ZERO
	return current_player.global_position


func restore_player_global_position(saved_position: Vector2) -> void:
	if current_player == null or not is_instance_valid(current_player):
		return
	current_player.global_position = saved_position


func initialize(host_root: Node2D, first_level_path: String = DEFAULT_FIRST_LEVEL_PATH, first_spawn_point: String = "InitialSpawn") -> void:
	if host_root == null:
		push_error("SceneManager.initialize() host_root is null.")
		return

	_host_root = host_root
	_ensure_level_container()
	_ensure_player()

	var should_bootstrap_room: bool = (not _is_initialized) or level_container.get_child_count() == 0
	_is_initialized = true

	if should_bootstrap_room:
		var loaded_room: Node2D = _load_room(first_level_path, first_spawn_point)
		if loaded_room != null:
			var room_id: String = _resolve_room_id(loaded_room, first_level_path)
			_emit_room_loaded(loaded_room, room_id)
			_emit_room_presented(loaded_room, room_id)


func _on_scene_change_requested(target_path: String, spawn_point_name: String) -> void:
	if not _is_initialized:
		return
	if is_transitioning:
		print("正在过渡中，忽略重复的切换请求：", target_path, spawn_point_name)
		return

	is_transitioning = true
	if GameManager != null and GameManager.has_method("request_pause"):
		GameManager.request_pause(GameManager.SCENE_TRANSITION_PAUSE_TOKEN)
	else:
		get_tree().paused = true

	if Transition != null and Transition.has_method("fade_out"):
		await Transition.fade_out()

	if current_player != null and current_player.get_parent() != null:
		current_player.get_parent().remove_child(current_player)

	for child: Node in level_container.get_children():
		child.queue_free()

	await get_tree().process_frame
	var loaded_room: Node2D = _load_room(target_path, spawn_point_name)
	var loaded_room_id: String = ""
	if loaded_room != null:
		loaded_room_id = _resolve_room_id(loaded_room, target_path)
		_emit_room_loaded(loaded_room, loaded_room_id)

	if Transition != null and Transition.has_method("fade_in"):
		await Transition.fade_in()

	if GameManager != null and GameManager.has_method("release_pause"):
		GameManager.release_pause(GameManager.SCENE_TRANSITION_PAUSE_TOKEN)
	else:
		get_tree().paused = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	is_transitioning = false
	if loaded_room != null:
		_emit_room_presented(loaded_room, loaded_room_id)


func _ensure_level_container() -> void:
	if level_container == null or not is_instance_valid(level_container):
		level_container = Node2D.new()
		level_container.name = "LevelContainer"

	if level_container.get_parent() == _host_root:
		return

	if level_container.get_parent() != null:
		level_container.get_parent().remove_child(level_container)

	_host_root.add_child(level_container)


func _ensure_player() -> void:
	if current_player != null and is_instance_valid(current_player):
		return

	var player_scene: PackedScene = load(DEFAULT_PLAYER_SCENE_PATH)
	if player_scene == null:
		push_error("SceneManager 无法加载玩家场景：" + DEFAULT_PLAYER_SCENE_PATH)
		return

	current_player = player_scene.instantiate() as Node2D
	if current_player == null:
		push_error("SceneManager 玩家实例化失败。")
		return

	current_player.name = "Player"


func _load_room(path: String, spawn_point_name: String) -> Node2D:
	var level_resource: PackedScene = load(path)
	if level_resource == null:
		push_error("无法加载关卡：" + path)
		return null

	var level_instance: Node2D = level_resource.instantiate() as Node2D
	if level_instance == null:
		push_error("关卡实例化失败：" + path)
		return null

	level_instance.process_mode = Node.PROCESS_MODE_PAUSABLE
	level_container.add_child(level_instance)
	current_room = level_instance

	if current_player == null:
		return level_instance

	var spawn_point: Node = null
	if not spawn_point_name.is_empty():
		spawn_point = level_instance.find_child(spawn_point_name, true, false)

	if spawn_point == null and level_instance.get("default_spawn_point"):
		var default_spawn_point: String = String(level_instance.default_spawn_point)
		spawn_point = level_instance.find_child(default_spawn_point, true, false)

	if spawn_point is Node2D:
		current_player.position = (spawn_point as Node2D).global_position

	level_instance.add_child(current_player)
	current_player.visible = true
	current_player.set_process(true)
	current_player.set_physics_process(true)
	if level_instance.has_method("apply_player_room_settings"):
		level_instance.apply_player_room_settings(current_player)
	else:
		current_player.scale = Vector2.ONE

	if spawn_point is Node2D:
		current_player.global_position = (spawn_point as Node2D).global_position
	else:
		push_warning("未能在地图中找到出生点：" + spawn_point_name)

	if STATIC_PRESENTATION_MODE:
		_configure_static_presentation(level_instance)
	elif level_instance.has_method("setup_camera_limits"):
		level_instance.setup_camera_limits(current_player)

	return level_instance


func refresh_static_camera() -> void:
	if not STATIC_PRESENTATION_MODE:
		return
	if current_room == null or not is_instance_valid(current_room):
		return
	_configure_static_presentation(current_room)


func configure_static_interactable(item: Interactable) -> void:
	if not STATIC_PRESENTATION_MODE or current_room == null:
		return
	var art: Node = current_room.get_node_or_null("StaticRoomArt")
	if art != null:
		art.call("configure_interactable", item)


func get_static_art_view() -> String:
	if current_room == null:
		return ""
	var art: Node = current_room.get_node_or_null("StaticRoomArt")
	return String(art.get("current_view")) if art != null else ""


func restore_static_art_view(view_id: String) -> void:
	if current_room == null or view_id.is_empty():
		return
	var art: Node = current_room.get_node_or_null("StaticRoomArt")
	if art != null:
		art.call("set_view", view_id)


func _configure_static_presentation(level_instance: Node2D) -> void:
	if level_instance.get_node_or_null("StaticRoomArt") == null:
		var room_id: String = _resolve_room_id(level_instance, level_instance.scene_file_path)
		if not StaticRoomArt.get_config(room_id).is_empty():
			var art := StaticRoomArt.new()
			art.name = "StaticRoomArt"
			level_instance.add_child(art)
			if not art.setup(level_instance, room_id):
				level_instance.remove_child(art)
				art.queue_free()
	if current_player != null and is_instance_valid(current_player):
		current_player.visible = false
		current_player.process_mode = Node.PROCESS_MODE_DISABLED
		current_player.set_process(false)
		current_player.set_physics_process(false)
		var player_body: CollisionObject2D = current_player as CollisionObject2D
		if player_body != null:
			player_body.collision_layer = 0
			player_body.collision_mask = 0
		var interaction_area: Area2D = current_player.get_node_or_null("InteractionArea") as Area2D
		if interaction_area != null:
			interaction_area.monitoring = false
			interaction_area.monitorable = false
		var player_camera: Camera2D = current_player.get_node_or_null("Camera2D") as Camera2D
		if player_camera != null:
			player_camera.enabled = false

	var camera: Camera2D = level_instance.get_node_or_null("StaticPresentationCamera") as Camera2D
	if camera == null:
		camera = Camera2D.new()
		camera.name = "StaticPresentationCamera"
		camera.position_smoothing_enabled = false
		level_instance.add_child(camera)

	var bounds: Rect2 = _resolve_static_bounds(level_instance)
	camera.global_position = level_instance.global_position + bounds.get_center()
	var viewport_size: Vector2 = level_instance.get_viewport_rect().size
	if bounds.size.x > 0.0 and bounds.size.y > 0.0 and viewport_size.x > 0.0 and viewport_size.y > 0.0:
		var fit_zoom: float = minf(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y)
		camera.zoom = Vector2.ONE * maxf(fit_zoom, 0.01)
	camera.enabled = true
	camera.make_current()
	if level_instance.has_method("configure_presentation_camera"):
		level_instance.configure_presentation_camera(camera)


func _resolve_static_bounds(level_instance: Node2D) -> Rect2:
	if level_instance.get_node_or_null("StaticRoomArt") != null:
		return Rect2(Vector2.ZERO, StaticRoomArt.CANVAS)
	var configured_bounds: Variant = level_instance.get("camera_bounds")
	if configured_bounds is Rect2:
		var room_bounds: Rect2 = configured_bounds as Rect2
		if room_bounds.size.x > 0.0 and room_bounds.size.y > 0.0:
			return room_bounds

	var combined: Rect2 = Rect2()
	var found_visual: bool = false
	for node: Node in level_instance.find_children("*", "Sprite2D", true, false):
		var sprite: Sprite2D = node as Sprite2D
		if sprite == null or sprite.texture == null or not sprite.visible:
			continue
		var texture_size: Vector2 = sprite.texture.get_size() * sprite.global_scale.abs()
		var top_left: Vector2 = sprite.global_position
		if sprite.centered:
			top_left -= texture_size * 0.5
		var sprite_rect := Rect2(top_left - level_instance.global_position, texture_size)
		combined = sprite_rect if not found_visual else combined.merge(sprite_rect)
		found_visual = true
	if found_visual:
		return combined
	return Rect2(Vector2.ZERO, level_instance.get_viewport_rect().size)


func _emit_room_loaded(room: Node2D, room_id: String) -> void:
	EventBus.room_loaded.emit(room, room_id)


func _emit_room_presented(room: Node2D, room_id: String) -> void:
	EventBus.room_presented.emit(room, room_id)


func _resolve_room_id(room: Node2D, source_path: String) -> String:
	if room != null:
		var configured_room_id: Variant = room.get("room_id")
		if configured_room_id != null and not String(configured_room_id).is_empty():
			return String(configured_room_id)
		if not room.name.is_empty():
			return String(room.name).to_snake_case()

	if not source_path.is_empty() and source_path.get_extension() == "tscn":
		return source_path.get_file().get_basename()
	return ""
