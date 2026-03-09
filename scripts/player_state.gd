extends Node

# 玩家核心状态（可直接扩展）
var global_position: Vector2 = Vector2.ZERO  # 玩家位置
var move_speed: float = 200.0               # 移动速度
var hp: int = 100                            # 血量（示例扩展）
var inventory: Array = []                   # 背包（示例扩展）
var story_progress: String = ""             # 剧情进度（示例扩展）

# 重置玩家状态（可选调用）
func reset_state():
	global_position = Vector2.ZERO
	move_speed = 200.0
	hp = 100
	inventory.clear()
	story_progress = ""
