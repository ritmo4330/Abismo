extends Node

const DEFAULT_FIRST_LEVEL_PATH: String = "res://scenes/rooms/hall.tscn"
const DEFAULT_PLAYER_SCENE_PATH: String = "res://scenes/characters/player/player.tscn"

var level_container: Node2D = null
var current_player: Node2D = null
var is_transitioning: bool = false

var _host_root: Node2D = null
var _is_initialized: bool = false


func _ready() -> void:
	if not EventBus.change_room_requested.is_connected(_on_change_room_requested):
		EventBus.change_room_requested.connect(_on_change_room_requested)
	if not EventBus.scene_change_requested.is_connected(_on_change_room_requested):
		EventBus.scene_change_requested.connect(_on_change_room_requested)


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
		_load_room(first_level_path, first_spawn_point)


func _on_change_room_requested(target_path: String, spawn_point_name: String) -> void:
	if not _is_initialized:
		return
	if is_transitioning:
		print("正在过渡中，忽略重复的切换请求：", target_path, spawn_point_name)
		return

	is_transitioning = true
	get_tree().paused = true

	if Transition != null and Transition.has_method("fade_out"):
		await Transition.fade_out()

	if current_player != null and current_player.get_parent() != null:
		current_player.get_parent().remove_child(current_player)

	for child: Node in level_container.get_children():
		child.queue_free()

	await get_tree().process_frame
	_load_room(target_path, spawn_point_name)

	if Transition != null and Transition.has_method("fade_in"):
		await Transition.fade_in()

	get_tree().paused = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	is_transitioning = false


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


func _load_room(path: String, spawn_point_name: String) -> void:
	var level_resource: PackedScene = load(path)
	if level_resource == null:
		push_error("无法加载关卡：" + path)
		return

	var level_instance: Node2D = level_resource.instantiate() as Node2D
	if level_instance == null:
		push_error("关卡实例化失败：" + path)
		return

	level_instance.process_mode = Node.PROCESS_MODE_PAUSABLE
	level_container.add_child(level_instance)

	if current_player == null:
		return

	level_instance.add_child(current_player)

	var spawn_point: Node = null
	if not spawn_point_name.is_empty():
		spawn_point = level_instance.find_child(spawn_point_name, true, false)

	if spawn_point == null and level_instance.get("default_spawn_point"):
		var default_spawn_point: String = String(level_instance.default_spawn_point)
		spawn_point = level_instance.find_child(default_spawn_point, true, false)

	if spawn_point is Node2D:
		current_player.global_position = (spawn_point as Node2D).global_position
	else:
		push_warning("未能在地图中找到出生点：" + spawn_point_name)

	if level_instance.has_method("setup_camera_limits"):
		level_instance.setup_camera_limits(current_player)
