extends Node

# 玩家核心状态（可直接扩展）
var global_position: Vector2 = Vector2.ZERO  # 玩家位置
var move_speed: float = 200.0               # 移动速度
var player_direction: Vector2 = Vector2.DOWN        # 玩家朝向
var current_spawn_point_name: String = "" # 用于记录玩家应该在哪出生
var inventory: Dictionary = {}                      # 背包
var max_slots: int = 4                       # 背包最大格数
var story_progress: String = ""             # 剧情进度（示例扩展）
var hp: int = 100                            # 血量（示例扩展）

# 重置玩家状态（可选调用）
func reset_state():
	global_position = Vector2.ZERO
	move_speed = 200.0
	player_direction = Vector2.DOWN
	current_spawn_point_name = ""
	hp = 100
	inventory.clear()
	story_progress = ""


# 添加物品
func add_item(item: ItemData, amount: int = 1) -> bool:
	if inventory.has(item.id):
		# 已有该物品，检查堆叠上限
		var current_amount = inventory[item.id]["amount"]
		if current_amount + amount <= item.max_stack:
			inventory[item.id]["amount"] += amount
			return true
		else:
			# 处理溢出或者直接给满
			inventory[item.id]["amount"] = item.max_stack
			return true
	else:
		# 没有该物品，检查格子总数（字典的 keys 数量代表占用的格子数）
		if inventory.size() < max_slots:
			inventory[item.id] = {"item": item, "amount": amount}
			return true
		else:
			print("背包已满！")
			return false

# 移除物品
func remove_item(item_id: String, amount: int = 1) -> bool:
	if inventory.has(item_id):
		if inventory[item_id]["amount"] >= amount:
			inventory[item_id]["amount"] -= amount
			# 数量归零，从字典删除该键值对
			if inventory[item_id]["amount"] <= 0:
				inventory.erase(item_id)
			return true
	print("物品数量不足或不存在！")
	return false
