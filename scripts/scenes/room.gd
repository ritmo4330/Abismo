extends Node2D

# 编辑器配置：玩家预制体路径（仅用于独立测试当前场景时）
@export var player_scene: PackedScene = preload("res://scenes/characters/player/player.tscn")
# 编辑器配置：本场景的默认出生点名称
@export var default_spawn_point: String = "InitialSpawn"
@export var room_id: String = ""
@export var camera_bounds: Rect2 = Rect2()
@export var player_spawn_scale: Vector2 = Vector2.ONE
@export var npc_spawn_scale: Vector2 = Vector2.ZERO

func _ready():
	# =====================
	# 重构：让 GameRoot 统一管理玩家生命周期。
	# 我们在此处加入检查，如果当前根节点是 GameRoot，房间本身就不要再创建玩家了！
	# 但如果你在编辑器里按了 F6 (单独运行这一个房间的场景用于除错/测试)，它依然会自动帮你刷个玩家出来。
	# =====================
	var is_managed_by_root = (get_tree().current_scene.name == "GameRoot")
	
	if not is_managed_by_root:
		# 独立运行该场景测试时执行的逻辑：依然会自己生成假玩家方便测试
		_spawn_test_player()

func _spawn_test_player():
	var spawn_point_name: String = default_spawn_point
	if FlowManager != null and FlowManager.has_method("consume_pending_standalone_spawn_point"):
		spawn_point_name = FlowManager.consume_pending_standalone_spawn_point(default_spawn_point)

	var spawn_point = find_child(spawn_point_name, true, false)
	if not spawn_point: return
	
	var player_instance = player_scene.instantiate()
	add_child(player_instance)
	apply_player_room_settings(player_instance)
	player_instance.global_position = spawn_point.global_position
	
	setup_camera_limits(player_instance)
	call_deferred("_play_pending_standalone_timeline")


func _play_pending_standalone_timeline() -> void:
	if FlowManager != null and FlowManager.has_method("play_pending_auto_timeline"):
		FlowManager.play_pending_auto_timeline()


func get_dynamic_actors_root() -> Node2D:
	return find_child("DynamicActors", true, false) as Node2D


func apply_player_room_settings(player: Node2D) -> void:
	if player == null:
		return
	player.scale = Vector2.ONE
	if player.has_method("apply_room_scale"):
		player.apply_room_scale(player_spawn_scale)
	else:
		player.scale = player_spawn_scale


func get_npc_spawn_point(spawn_point_name: String) -> Marker2D:
	var root: Node = find_child("NPCSpawnPoints", true, false)
	if root == null:
		return null
	return root.find_child(spawn_point_name, true, false) as Marker2D


func get_dynamic_clues_root() -> Node2D:
	return find_child("DynamicClues", true, false) as Node2D


func get_clue_spawn_point(spawn_point_name: String) -> Marker2D:
	var root: Node = find_child("ClueSpawnPoints", true, false)
	if root == null:
		return null
	return root.find_child(spawn_point_name, true, false) as Marker2D

# 动态获取当前地图的边界，并设置给玩家的摄像机
func setup_camera_limits(player: Node2D):
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		return
	camera.zoom = Vector2.ONE

	if camera_bounds.size.x > 0.0 and camera_bounds.size.y > 0.0:
		_apply_camera_limits(camera, Rect2(global_position + camera_bounds.position, camera_bounds.size))
		return
		
	var map_pixel_rect = Rect2()
	var found_any = false
	
	var nodes_to_check = [self]
	while nodes_to_check.size() > 0:
		var current_node = nodes_to_check.pop_front()
		if current_node is TileMapLayer or current_node is TileMap:
			var current_rect = current_node.get_used_rect()
			if current_rect.size.x > 0 and current_rect.size.y > 0:
				var cell_size = Vector2(16, 16)
				if current_node.get("tile_set") and current_node.tile_set:
					cell_size = current_node.tile_set.tile_size
				
				# 必须先转换为统一的全局像素坐标，再做 merge
				# 否则不同 layer 拥有不同的 cell_size 或 offset 时会导致边界爆炸
				var px = current_node.global_position.x + current_rect.position.x * cell_size.x
				var py = current_node.global_position.y + current_rect.position.y * cell_size.y
				var pw = current_rect.size.x * cell_size.x
				var ph = current_rect.size.y * cell_size.y
				var layer_pixel_rect = Rect2(px, py, pw, ph)
				
				if not found_any:
					map_pixel_rect = layer_pixel_rect
					found_any = true
				else:
					map_pixel_rect = map_pixel_rect.merge(layer_pixel_rect)
					
		for child in current_node.get_children():
			nodes_to_check.push_back(child)
			
	if found_any:
		_apply_camera_limits(camera, map_pixel_rect)


func _apply_camera_limits(camera: Camera2D, map_pixel_rect: Rect2) -> void:
	var limit_left = map_pixel_rect.position.x - 16
	var limit_top = map_pixel_rect.position.y - 16
	var limit_right = map_pixel_rect.end.x + 16
	var limit_bottom = map_pixel_rect.end.y + 16

	# 获取相机的实际可视物理尺寸
	var viewport_size = get_viewport_rect().size / camera.zoom

	var map_width = limit_right - limit_left
	var map_height = limit_bottom - limit_top

	# 如果地图宽度小于相机可视宽度，将其居中
	if map_width < viewport_size.x:
		var diff = (viewport_size.x - map_width) / 2.0
		limit_left -= diff
		limit_right += diff

	# 如果地图高度小于相机可视高度，将其居中
	if map_height < viewport_size.y:
		var diff = (viewport_size.y - map_height) / 2.0
		limit_top -= diff
		limit_bottom += diff

	camera.limit_left = int(round(limit_left))
	camera.limit_top = int(round(limit_top))
	camera.limit_right = int(round(limit_right))
	camera.limit_bottom = int(round(limit_bottom))
