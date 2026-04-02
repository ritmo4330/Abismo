extends CharacterBody2D

@export var npc_name: String = "村民"
@export var timeline_name: String = "" # 对应 Dialogic 2 中的 Timeline 名称

@onready var interact_area: Area2D = $InteractArea
@onready var prompt_ui: AnimatedSprite2D = $PromptUI # 如果你用Label或其他节点也可以

var player_in_range: bool = false

func _ready() -> void:
	# 设置当前节点在游戏暂停时仍保持运行
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 连接互动区域的信号
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)
	
	# 初始化提示UI位置与状态
	if prompt_ui:
		prompt_ui.hide()
		prompt_ui.stop()
		
	# 监听 Dialogic 时间线结束信号，以恢复交互提示状态
	Dialogic.timeline_ended.connect(_on_timeline_ended)

func _on_interact_area_body_entered(body: Node2D) -> void:
	# 如果你原来使用的是 body is Player，请修改回 body is Player
	# 推荐给Player节点添加 "player" 分组，这样更安全
	if body.name == "Player" or body.is_in_group("player"): 
		player_in_range = true
		# 当没有进行对话时才显示提示
		if prompt_ui and Dialogic.current_timeline == null:
			prompt_ui.show()
			prompt_ui.play()

func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"): 
		player_in_range = false
		if prompt_ui:
			prompt_ui.hide()
			prompt_ui.stop()

func _input(event: InputEvent) -> void:
	if player_in_range and event is InputEventKey:
		# 监听F键（需要和拾取物品快捷键保持一致，或者在Input Map中配置 "interact" 动作）
		if event.physical_keycode == KEY_F and event.pressed and not event.echo:
			interact_with_npc()

func interact_with_npc() -> void:
	# 如果时间线未配置，或者当前 Dialogic 正在播放对话，则不触发
	if timeline_name.is_empty() or Dialogic.current_timeline != null:
		return
		
	# 对话时隐藏按键提示
	if prompt_ui:
		prompt_ui.hide()
		prompt_ui.stop()
	
	# 暂停游戏，防止玩家随意移动
	get_tree().paused = true
	
	# ⭐ 确保 Dialogic 的系统单例和新生成的 UI 在游戏暂停时仍处于运行状态
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
	var layout = Dialogic.start(timeline_name)
	if layout:
		layout.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_timeline_ended() -> void:
	# 恢复游戏时间
	get_tree().paused = false
	
	# 对话结束时，如果玩家还在范围内且没有播放其他对话，重新显示按键提示
	if player_in_range and prompt_ui and Dialogic.current_timeline == null:
		prompt_ui.show()
		prompt_ui.play()
