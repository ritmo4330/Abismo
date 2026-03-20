extends Node

# 游戏事件总线：所有跨组件、跨系统的通信都在这里注册信号
# 这样不仅解耦，而且极大减少各个脚本里为了寻找节点而产生的硬编码

# 场景/房间系统
signal change_room_requested(target_scene_path: String, spawn_point_name: String)

# ============ 物品 & 背包系统 ============
# 当物品被成功拾取时触发（UI可以监听这个信号来在屏幕上弹出提示，比如“获得：苹果 x1”）
signal item_picked_up(item: Resource, amount: int)

# 当背包内容发生任何变化时触发（背包UI界面用来刷新自己的显示格子）
signal inventory_changed()

# 你可以随着游戏开发，在这里不断追加新的信号，比如：
# signal player_health_changed(new_health: int)
# signal dialogue_started(dialogue_id: String)
