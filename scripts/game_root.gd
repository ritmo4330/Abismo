extends Control

# 你实际要启动的游玩关卡
const FIRST_LEVEL_PATH = "res://scenes/rooms/room_song_lin_xi.tscn"

@onready var game_viewport = $SubViewportContainer/SubViewport

func _ready():
	# 关键修复：允许 SubViewportContainer 在暂停时继续接收和下发输入事件
	$SubViewportContainer.process_mode = Node.PROCESS_MODE_ALWAYS
	game_viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 动态把游戏场景加载到这个专门用于约束低分辨率的 SubViewport 中
	var level_resource = load(FIRST_LEVEL_PATH)
	if level_resource:
		var level_instance = level_resource.instantiate()
		# 强制游戏本身（子节点环境）受暂停影响（否则它会继承上级的 ALWAYS 导致整个游戏无法暂停）
		level_instance.process_mode = Node.PROCESS_MODE_PAUSABLE
		game_viewport.add_child(level_instance)
