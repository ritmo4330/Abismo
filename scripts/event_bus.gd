extends Node

# 游戏事件总线：所有跨组件、跨系统的通信都在这里注册信号
# 这样不仅解耦，而且极大减少各个脚本里为了寻找节点而产生的硬编码

# 场景/房间系统
signal change_room_requested(target_scene_path: String, spawn_point_name: String)

# 你可以随着游戏开发，在这里不断追加新的信号，比如：
# signal player_health_changed(new_health: int)
# signal item_picked_up(item: Resource)
# signal dialogue_started(dialogue_id: String)
