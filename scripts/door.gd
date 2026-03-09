extends Area2D

# 编辑器可配置：目标场景路径
@export_file("*.tscn") var target_scene_path: String
# 编辑器可配置：目标场景的出生点名称
@export var target_spawn_point: String

func _on_body_entered(body):
	# 检测是否是玩家（建议给玩家节点加 "player" 组）
	print("door triggered")
	if body.is_in_group("player"):
		print("player triggered")
		# 1. 保存玩家当前状态
		body.save_current_state()
		# 2. 记录目标场景的出生点（可选，如需多出生点可扩展）
		#PlayerState.spawn_point_name = target_spawn_point
		# 3. 带淡入淡出切换场景
		Transition.change_scene_with_fade(target_scene_path)

# ========== 信号连接提示 ==========
# 选中门节点 → 右侧信号面板 → 找到 body_entered → 连接到本脚本的 _on_body_entered
