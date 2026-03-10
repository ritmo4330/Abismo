extends Node2D

# 编辑器配置：玩家预制体路径
@export var player_scene: PackedScene = preload("res://scenes/characters/player/player.tscn")
# 编辑器配置：本场景的默认出生点名称
@export var default_spawn_point: String = "InitialSpawn"

func _ready():
	# 决定用哪个出生点
	var target_spawn_name = default_spawn_point
	if PlayerState.current_spawn_point_name != "":
		target_spawn_name = PlayerState.current_spawn_point_name
	
	var spawn_point = get_node_or_null(target_spawn_name)
	
	# 检查场景内是否已有活着的玩家（必须排除掉那些正准备被销毁的旧玩家节点）
	var existing_player = get_tree().get_first_node_in_group("player")
	var needs_player = true
	var player_instance = null
	
	if existing_player and not existing_player.is_queued_for_deletion():
		needs_player = false
		player_instance = existing_player
		
	# 检查场景内是否已有玩家，无则实例化
	if needs_player and spawn_point:
		player_instance = player_scene.instantiate()

		# 先添加到场景树，再设置位置，确保玩家位置正确更新
		add_child(player_instance)
		player_instance.global_position = spawn_point.global_position

		PlayerState.current_spawn_point_name = ""  # 重置出生点记录，避免下次错误使用
		
	# 动态配置摄像机边界
	if player_instance:
		setup_camera_limits(player_instance)

# 动态获取当前地图的边界，并设置给玩家的摄像机
func setup_camera_limits(player: Node2D):
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		return
		
	var tilemap = null
	
	# 递归寻找子节点中的第一个 TileMap 或者 TileMapLayer
	var nodes_to_check = [self]
	while nodes_to_check.size() > 0:
		var current_node = nodes_to_check.pop_front()
		if current_node is TileMapLayer or current_node is TileMap:
			tilemap = current_node
			break
		for child in current_node.get_children():
			nodes_to_check.push_back(child)
			
	if tilemap:
		# 获取地图使用的全部矩形区域 (单位是图块格子)
		var map_rect = tilemap.get_used_rect()
		# 获取每个图块的大小 (比如 16x16 或 32x32)
		# 尝试获取 tile_set 的 tile_size
		var cell_size = Vector2(16, 16) # 默认值
		if tilemap.get("tile_set") and tilemap.tile_set:
			cell_size = tilemap.tile_set.tile_size
			
		# 计算像素边界
		# 给摄像机设置限制，但允许玩家在地图边缘有一点点余量，避免完全贴边时画面不舒服
		# （注意：必须加上 tilemap 本身的 global_position，否则对于有偏移的子节点地图就会出错！）
		var offset_x = tilemap.global_position.x
		var offset_y = tilemap.global_position.y
		
		var limit_left = offset_x + map_rect.position.x * cell_size.x - 16
		var limit_top = offset_y + map_rect.position.y * cell_size.y - 16
		var limit_right = offset_x + map_rect.end.x * cell_size.x + 16
		var limit_bottom = offset_y + map_rect.end.y * cell_size.y + 16
		
		camera.limit_left = int(limit_left)
		camera.limit_top = int(limit_top)
		camera.limit_right = int(limit_right)
		camera.limit_bottom = int(limit_bottom)
		
