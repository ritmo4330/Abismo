extends Node

# 这个单例仅作为“游戏数据存储中心（Data Center / Save Manager）”
# 不再负责场景切换当中的坐标、朝向等物理实体的中转工作

# ============ 宏观游戏数据 ============
var inventory: Dictionary = {}               # 背包
var max_slots: int = 4                       # 背包最大格数
var story_progress: String = ""              # 剧情进度（示例扩展）
var hp: int = 100                            # 血量（这里血量存单例是因为即使重启游戏通常也要继承血量）

# 重置游戏存档状态（比如回到主菜单重新开始新游戏时调用）
func reset_state():
	hp = 100
	inventory.clear()
	story_progress = ""
	EventBus.inventory_changed.emit()

# 添加物品
func add_item(item: ItemData, amount: int = 1) -> bool:
	if inventory.has(item.id):
		# 已有该物品，检查堆叠上限
		var current_amount = inventory[item.id]["amount"]
		if current_amount + amount <= item.max_stack:
			inventory[item.id]["amount"] += amount
		else:
			# 处理溢出或者直接给满
			inventory[item.id]["amount"] = item.max_stack
			
		EventBus.inventory_changed.emit()
		EventBus.item_picked_up.emit(item, amount)
		return true
	else:
		# 没有该物品，检查格子总数（字典的 keys 数量代表占用的格子数）
		if inventory.size() < max_slots:
			inventory[item.id] = {"item": item, "amount": amount}
			EventBus.inventory_changed.emit()
			EventBus.item_picked_up.emit(item, amount)
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
				
			EventBus.inventory_changed.emit()
			return true
	print("物品数量不足或不存在！")
	return false
