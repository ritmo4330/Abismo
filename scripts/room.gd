extends Node2D

# 编辑器配置：玩家预制体路径
@export var player_scene: PackedScene = preload("res://scenes/characters/player/player.tscn")
# 编辑器配置：本场景的默认出生点名称
@export var default_spawn_point: String = "DoorSpawn"

func _ready():
	var spawn_point = get_node_or_null(default_spawn_point)
	# 检查场景内是否已有玩家，无则实例化
	if not get_tree().get_first_node_in_group("player") and spawn_point:
		var player = player_scene.instantiate()
		add_child(player)
		# 给玩家绑定出生点名称
		player.spawn_point_name = default_spawn_point
		player.global_position = spawn_point.global_position
		# 手动触发状态还原（确保位置正确）
		player.load_player_state()
