extends CharacterBody2D

@export var npc_name: String = "村民"
@export var dialogue_lines: Array[String] = [
	"你好，年轻的旅人。",
	"今天天气真不错。",
    "祝你好运！"
]
@export var avatar: Texture2D # 可选的 NPC 头像

@onready var interact_area: Area2D = $InteractArea
@onready var prompt_ui: AnimatedSprite2D = $PromptUI # 如果你用Label或其他节点也可以

var player_in_range: bool = false
var current_dialogue_index: int = 0
var is_talking: bool = false

func _ready() -> void:
	# 设置当前节点在游戏暂停时仍保持运行，以确保在对话期间能接收输入事件
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 连接互动区域的信号
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)
	
	# 初始化提示UI位置与状态
	if prompt_ui:
		prompt_ui.hide()

func _on_interact_area_body_entered(body: Node2D) -> void:
	if body is Player: # 假设你的玩家类名为 Player
		player_in_range = true
		if prompt_ui and not is_talking:
			prompt_ui.show()

func _on_interact_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		is_talking = false # 离开时重置对话状态
		current_dialogue_index = 0
		if prompt_ui:
			prompt_ui.hide()

func _input(event: InputEvent) -> void:
	if player_in_range and event is InputEventKey:
		# 监听F键（需要和拾取物品快捷键保持一致，或者在Input Map中配置 "interact" 动作）
		if event.physical_keycode == KEY_F and event.pressed and not event.echo:
			interact_with_npc()

func interact_with_npc() -> void:
	if not is_talking:
		start_dialogue()
	else:
		next_dialogue_line()

func start_dialogue() -> void:
	is_talking = true
	current_dialogue_index = 0
	
	# 作为推理AVG游戏，推荐在触发对话时暂停游戏（阻止玩家移动及其他物理时间更新）
	get_tree().paused = true
	
	if prompt_ui:
		prompt_ui.hide() # 对话时隐藏按键提示
	
	print("--- 开始与 " + npc_name + " 的对话 ---")
	show_dialogue()

func next_dialogue_line() -> void:
	current_dialogue_index += 1
	if current_dialogue_index < dialogue_lines.size():
		show_dialogue()
	else:
		end_dialogue()

func show_dialogue() -> void:
	# TODO: 这里之后可以替换为调用你的 Dialogue UI 界面，比如 DialogueManager.show_text(...)
	print(npc_name + ": " + dialogue_lines[current_dialogue_index])
	var current_text = dialogue_lines[current_dialogue_index]
	# 假设你的 NPC 有一个 export var avatar: Texture2D 可以传头像，没有的话传 null
	DialogueManager.show_dialogue(npc_name, current_text, avatar)

func end_dialogue() -> void:
	is_talking = false
	current_dialogue_index = 0
	
	# 对话结束，恢复游戏进程
	get_tree().paused = false

	# 让对话框自己隐藏
	DialogueManager.hide_dialogue()
	
	print("--- 对话结束 ---")
	
	# 如果玩家还在范围内，重新显示按键提示
	if player_in_range and prompt_ui:
		prompt_ui.show()
