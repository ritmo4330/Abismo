extends Node2D

@export var spawn_point_name: String = "door_spawn"
@export var player_scene: PackedScene


func _ready():
	# 场景中已有玩家则跳过，没有则实例化并还原状态
	if not get_tree().get_first_node_in_group("player"):
		var player = player_scene.instantiate()
		add_child(player)
		# 还原位置&属性
		player.load_player_state()
	#var spawn_point = get_node_or_null("door_entry")
	#if spawn_point:
		## 实例化玩家并放到出生点
		#var player = player_scene.instantiate()
		#add_child(player)
		#player.global_position = spawn_point.global_position
