extends Area2D

# 可以在右侧属性面板直接拖入做好的 ItemData 资源文件
@export var item_data: ItemData
@export var amount: int = 1

@onready var prompt_ui : AnimatedSprite2D = $PromptUI
var player_in_range: bool = false


func _ready():
	# 碰触与离开检测
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 设置物品的图标
	var sprite_node = get_node("Sprite2D") as Sprite2D
	if sprite_node and item_data.icon:
		sprite_node.texture = item_data.icon
	
	# 设置提示图标的初始状态：默认隐藏，位置调到物品上方
	prompt_ui.position = get_node("Sprite2D").position + Vector2(0, -16)
	prompt_ui.hide()

func _on_body_entered(body: Node2D):
	if body is Player: # 检测玩家靠近
		player_in_range = true
		prompt_ui.show()
		# 如果你用的是 AnimatedSprite2D，可以在这里让它开始播放动画
		if prompt_ui.has_method("play"):
			prompt_ui.play()

func _on_body_exited(body: Node2D):
	if body is Player: # 检测玩家离开
		player_in_range = false
		prompt_ui.hide()
		# 如果你用的是 AnimatedSprite2D，可以在这里让它停止播放
		if prompt_ui.has_method("stop"):
			prompt_ui.stop()

func _input(event):
	# 如果玩家在范围内，并且按下了键盘
	if player_in_range and event is InputEventKey:
		# 判断是否是 F 键被按下 (不包含长按的 echo)
		if event.physical_keycode == KEY_F and event.pressed and not event.echo:
			var added = PlayerState.add_item(item_data, amount)
			print("item %s added" % item_data.name)
			if added:
				queue_free() # 成功放入背包后销毁场景中的物品
