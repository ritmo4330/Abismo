extends Node2D

# 你实际要启动的游玩关卡
const FIRST_LEVEL_PATH = "res://scenes/rooms/hall.tscn"
const PLAYER_SCENE_PATH = "res://scenes/characters/player/player.tscn"

var level_container: Node2D
var current_player: Node2D
var is_transitioning: bool = false

func _ready():
	# 创建一个专门用于容纳房间场景的容器，将其与 Player 节点分离开
	# 这样在切换房间时清理旧房间，不会误删玩家
	level_container = Node2D.new()
	level_container.name = "LevelContainer"
	add_child(level_container)
	
	# 初始化：实例化玩家（全局唯一），常驻于内存中
	var player_scene = load(PLAYER_SCENE_PATH)
	if player_scene:
		current_player = player_scene.instantiate()
		current_player.name = "Player"
		
		# =====================
		# 方案切换修正：在使用 Camera Zoom 方案时，
		# 我们如果能拿到玩家里面的 Camera2D，自动帮它设置放大倍数（1920/480 = 4, 1080/270 = 4）
		# 这样就模拟了原本 480x270 的低分辨率视野
		# =====================
		var camera = current_player.get_node_or_null("Camera2D")
		#if camera:
			#camera.zoom = Vector2(4.0, 4.0)
		
		# 先不将其 addTo_Child(放到任何节点下)，让下面的 _load_room 去主动将它放入关卡中
		
	# 监听 EventBus 传来的切换场景请求
	EventBus.change_room_requested.connect(_on_change_room_requested)
	
	# 游戏启动时，加载第一个关卡（使用默认出生点或空字符串由 Room 决定）
	_load_room(FIRST_LEVEL_PATH, "InitialSpawn")

# 当门或其他逻辑触发切换请求时执行
func _on_change_room_requested(target_path: String, spawn_point_name: String):
	if is_transitioning:
		print("正在过渡中，忽略重复的切换请求：", target_path, spawn_point_name)
		return # 防抖：如果正在过渡中，直接忽略所有的重复触发请求
		
	is_transitioning = true
	# 1. 暂停游戏逻辑，防止玩家在过场动画期间乱跑、受击
	get_tree().paused = true
	
	# 2. 调用过度动画（黑幕）
	await Transition.fade_out()
	
	# 3. 将常驻玩家节点从场景树暂时摘除，以免被下面的全部销毁操作误杀（关键步骤！）
	if current_player and current_player.get_parent():
		current_player.get_parent().remove_child(current_player)
	
	# 4. 删除旧的房间场景
	for child in level_container.get_children():
		child.queue_free()
		
	# 确保内存和树中的旧节点被彻底清除
	await get_tree().process_frame
	
	# 5. 加载新房间，并放置玩家
	_load_room(target_path, spawn_point_name)
	
	# 6. 等待新场景就绪，褪去黑幕
	await Transition.fade_in()
	
	# 7. 恢复游戏游玩
	get_tree().paused = false
	
	# 8. 等待两个物理帧，让刚出生就重叠在Door上的碰撞事件被触发并被本函数的防抖(is_transitioning)吞掉
	# 防止玩家从房间A传送房间B时，因为正巧处于B的门上又立刻被传回A
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	is_transitioning = false

# 核心加载逻辑提取为独立函数
func _load_room(path: String, spawn_point_name: String):
	var level_resource = load(path)
	if not level_resource:
		push_error("无法加载关卡：", path)
		return
		
	var level_instance = level_resource.instantiate()
	# 强制游戏本身（子节点环境）受暂停影响
	level_instance.process_mode = Node.PROCESS_MODE_PAUSABLE
	level_container.add_child(level_instance)
	
	# 将常驻玩家放置到新生点
	if current_player:
		# 重新作为子节点挂载到新的房间地图下，这样 Y-Sort 渲染和碰撞判定都能完美在同一个层级进行
		level_instance.add_child(current_player)
		
		# 我们优先尝试去新房间寻找目标名称的出生点
		var spawn_point = level_instance.get_node_or_null(spawn_point_name)
		
		# 找不到指定名称（或未传递），尝试寻找缺省出生的点
		if not spawn_point and level_instance.get("default_spawn_point"):
			spawn_point = level_instance.get_node_or_null(level_instance.default_spawn_point)
			
		if spawn_point:
			current_player.global_position = spawn_point.global_position
		else:
			push_warning("未能在地图中找到出生点：", spawn_point_name)
			
		# 让新场景动态配置该玩家身上的摄像机边界
		if level_instance.has_method("setup_camera_limits"):
			level_instance.setup_camera_limits(current_player)
