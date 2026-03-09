extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect
@export var fade_speed: float = 2.0  # 淡入淡出速度

# 淡出（屏幕变黑）
func fade_out():
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	while fade_rect.modulate.a < 1.0:
		fade_rect.modulate.a += fade_speed * get_process_delta_time()
		await get_tree().process_frame

# 淡入（屏幕变透明）
func fade_in():
	fade_rect.modulate.a = 1.0
	while fade_rect.modulate.a > 0.0:
		fade_rect.modulate.a -= fade_speed * get_process_delta_time()
		await get_tree().process_frame
	fade_rect.visible = false

# 核心：带过渡切换场景
func change_scene_with_fade(target_scene_path: String):
	await fade_out()                  # 先淡出
	get_tree().change_scene_to_file(target_scene_path)  # 切场景
	await fade_in()                   # 再淡入
