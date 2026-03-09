extends Area2D

@export_file("*.tcsn") var target_scene: String
# 目标场景中玩家出生点 Marker2D 名称
@export var spawn_point_name: String = "door_spawn"

func _on_body_entered(body):
	if body.is_in_group("player"): # 建议用组，比 name 更稳健
		# 关键：切换前保存玩家当前状态到全局单例
		save_player_state(body)
		# 带淡入淡出切换场景
		Transition.change_scene_with_fade(target_scene)

# 保存玩家状态到全局单例
func save_player_state(player_node):
	# 位置
	PlayerState.global_position = player_node.global_position
	# 移动速度
	PlayerState.move_speed = player_node.move_speed
	# 其他自定义状态按需加
	# PlayerState.inventory = player_node.inventory
	# PlayerState.hp = player_node.hp
