extends Area2D

# 编辑器可配置：目标场景路径
@export_file("*.tscn") var target_scene_path: String
# 编辑器可配置：目标场景的出生点名称
@export var target_spawn_point: String

func _on_body_entered(body):
	# 检测是否是玩家（建议给玩家节点加 "player" 组）
	if body.is_in_group("player"):
		# 极简职责：通过事件总线发出切换房间请求，高度解耦
		# 不再依赖 PlayerState 充当传话筒，也不需要负责手动保存玩家节点状态（由GameRoot托管）
		if target_scene_path != "":
			EventBus.change_room_requested.emit(target_scene_path, target_spawn_point)
		else:
			push_error("Door 未配置目标场景路径 target_scene_path!")

# ========== 信号连接提示 ==========
# 选中门节点 → 右侧信号面板 → 找到 body_entered → 连接到本脚本的 _on_body_entered
