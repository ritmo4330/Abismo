extends Node

# 游戏事件总线：所有跨组件、跨系统的通信都在这里注册信号
# 这样不仅解耦，而且极大减少各个脚本里为了寻找节点而产生的硬编码

# 场景/房间系统
signal scene_change_requested(target_scene_path: String, spawn_point_name: String)

# 对话系统
# 兼容旧格式：String timeline_name
# 预留新格式：Dictionary { npc_id, entry_id } / { timeline_name }
signal dialogue_requested(request: Variant)
signal dialogue_finished(timeline_name: String)
signal flow_signal_requested(signal_name: String)

# 流程/房间编排
signal room_loaded(room: Node2D, room_id: String)

# 线索系统
# 线索交互详情请求：由 ClueItem 发出，供后续 ClueUI 交互详情模式消费
signal clue_interaction_details_requested(payload: Dictionary)
# 推理界面请求线索栏进入选择模式，ClueUI 完成选择后回传选择结果
signal clue_selection_requested(context: Dictionary)
signal clue_selected_for_reasoning(context: Dictionary, clue_id: String)

# 系统 UI 面板互斥显示：同一时间只保留一个手册/弹出界面
signal ui_panel_focus_requested(panel_id: String)

# 你可以随着游戏开发，在这里不断追加新的信号，比如：
# signal player_health_changed(new_health: int)
# signal dialogue_started(dialogue_id: String)
