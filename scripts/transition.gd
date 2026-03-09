extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect
@export var fade_duration: float = 0.5

func _ready():
	# 【重要新增】：将 Transition 节点设为永远运行模式。
	# 这样即使游戏暂停（get_tree().paused = true），我们的淡出动画也不会被卡住
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not fade_rect:
		print("警告：未找到 FadeRect 节点，请检查 Transition 场景的节点结构！")
	else:
		# 初始化：确保游戏开始时，黑幕是隐藏和完全透明的
		fade_rect.modulate.a = 0.0
		fade_rect.visible = false
		# 防止黑幕在平时的透明状态下阻挡玩家的鼠标点击事件
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

# 淡出（屏幕变黑）
func fade_out():
	# 如果场景之前挡住了鼠标，在过渡期间你也可以设置为 MOUSE_FILTER_STOP 来禁止玩家乱点
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	
	# 创建一个 Tween 对象
	var tween = create_tween()
	# 将 fade_rect 的 modulate:a 属性，用 fade_duration 秒的时间，过渡到 1.0 (完全不透明)
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	
	# 等待 Tween 动画播放完毕
	await tween.finished

# 淡入（屏幕变透明）
func fade_in():
	var tween = create_tween()
	# 将 fade_rect 的 modulate:a 属性，用 fade_duration 秒的时间，过渡到 0.0 (完全透明)
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	
	await tween.finished
	fade_rect.visible = false

# 核心：带过渡切换场景
func change_scene_with_fade(target_scene_path: String):
	get_tree().paused = true  # 暂停游戏逻辑，防止玩家在过渡期间乱动

	await fade_out()                  # 先淡出（屏幕变黑）
	get_tree().change_scene_to_file(target_scene_path)  # 切新场景
	await fade_in()                   # 再淡入（屏幕恢复画面）

	get_tree().paused = false  # 恢复游戏逻辑
