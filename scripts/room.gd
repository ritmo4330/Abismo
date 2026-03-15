extends Node2D

# 编辑器配置：玩家预制体路径（仅用于独立测试当前场景时）
@export var player_scene: PackedScene = preload("res://scenes/characters/player/player.tscn")
# 编辑器配置：本场景的默认出生点名称
@export var default_spawn_point: String = "InitialSpawn"

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
	var spawn_point = get_node_or_null(default_spawn_point)
	if not spawn_point: return
	
	var player_instance = player_scene.instantiate()
	add_child(player_instance)
	player_instance.global_position = spawn_point.global_position
	
	setup_camera_limits(player_instance)

# 动态获取当前地图的边界，并设置给玩家的摄像机
func setup_camera_limits(player: Node2D):
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		return
		
	var map_rect = Rect2i()
	var found_any = false
	var cell_size = Vector2(16, 16)
	var offset_x = 0.0
	var offset_y = 0.0
	
	var nodes_to_check = [self]
	while nodes_to_check.size() > 0:
		var current_node = nodes_to_check.pop_front()
		if current_node is TileMapLayer or current_node is TileMap:
			var current_rect = current_node.get_used_rect()
			if current_rect.size.x > 0 and current_rect.size.y > 0:
				if not found_any:
					map_rect = current_rect
					offset_x = current_node.global_position.x
					offset_y = current_node.global_position.y
					if current_node.get("tile_set") and current_node.tile_set:
						cell_size = current_node.tile_set.tile_size
					found_any = true
				else:
					map_rect = map_rect.merge(current_rect)
		for child in current_node.get_children():
			nodes_to_check.push_back(child)
			
	if found_any:
		# 计算像素边界
		# 给摄像机设置限制，但允许玩家在地图边缘有一点点余量，避免完全贴边时画面不舒服
		# （注意：必须加上 tilemap 本身的 global_position，否则对于有偏移的子节点地图就会出错！）
		
		var limit_left = offset_x + map_rect.position.x * cell_size.x - 16
		var limit_top = offset_y + map_rect.position.y * cell_size.y - 16
		var limit_right = offset_x + map_rect.end.x * cell_size.x + 16
		var limit_bottom = offset_y + map_rect.end.y * cell_size.y + 16
		
		camera.limit_left = int(limit_left)
		camera.limit_top = int(limit_top)
		camera.limit_right = int(limit_right)
		camera.limit_bottom = int(limit_bottom)
		
