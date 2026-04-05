extends Node

# 游戏事件总线：所有跨组件、跨系统的通信都在这里注册信号
# 这样不仅解耦，而且极大减少各个脚本里为了寻找节点而产生的硬编码

# 场景/房间系统
signal scene_change_requested(target_scene_path: String, spawn_point_name: String)

# 对话系统
# 兼容旧格式：String timeline_name
# 预留新格式：Dictionary { npc_id, entry_id } / { timeline_name }
signal dialogue_requested(request: Variant)

# 线索系统
# 线索交互详情请求：由 ClueItem 发出，供后续 ClueUI 交互详情模式消费
signal clue_interaction_details_requested(payload: Dictionary)

# 你可以随着游戏开发，在这里不断追加新的信号，比如：
# signal player_health_changed(new_health: int)
# signal dialogue_started(dialogue_id: String)
