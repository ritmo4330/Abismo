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
	
	# 检查场景内是否已有玩家，无则实例化
	if not get_tree().get_first_node_in_group("player") and spawn_point:
		var player = player_scene.instantiate()

		# 先添加到场景树，再设置位置，确保玩家位置正确更新
		add_child(player)
		player.global_position = spawn_point.global_position

		PlayerState.current_spawn_point_name = ""  # 重置出生点记录，避免下次错误使用
		
