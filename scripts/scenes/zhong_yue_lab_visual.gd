extends Node2D

const ROOM_SIZE: Vector2 = Vector2(1920.0, 1080.0)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# 冷色海底研究所底板与金属网格。
	draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), Color("07131f"))
	draw_rect(Rect2(54, 54, 1812, 972), Color("102638"))
	for x: int in range(80, 1880, 80):
		draw_line(Vector2(x, 80), Vector2(x, 1000), Color(0.12, 0.30, 0.40, 0.34), 2.0)
	for y: int in range(80, 1000, 80):
		draw_line(Vector2(80, y), Vector2(1840, y), Color(0.12, 0.30, 0.40, 0.34), 2.0)

	# 外墙、入口与远端观察窗。
	draw_rect(Rect2(30, 30, 1860, 45), Color("263f51"))
	draw_rect(Rect2(30, 1005, 760, 45), Color("263f51"))
	draw_rect(Rect2(1130, 1005, 760, 45), Color("263f51"))
	draw_rect(Rect2(30, 30, 45, 1020), Color("263f51"))
	draw_rect(Rect2(1845, 30, 45, 1020), Color("263f51"))
	draw_rect(Rect2(690, 105, 540, 135), Color("05101a"))
	for x: int in range(710, 1230, 65):
		draw_line(Vector2(x, 110), Vector2(x, 235), Color(0.18, 0.65, 0.83, 0.45), 3.0)

	# 左侧储物柜与钟岳铭牌区域。
	_draw_console(Rect2(125, 240, 360, 205), Color("17384b"))
	_draw_console(Rect2(125, 505, 360, 245), Color("153447"))
	draw_rect(Rect2(195, 330, 220, 50), Color("b58b43"))
	draw_string(ThemeDB.fallback_font, Vector2(270, 365), "钟岳", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("101820"))

	# 右侧超级计算机与工作清单。
	_draw_console(Rect2(1435, 230, 355, 530), Color("15394d"))
	for row: int in range(4):
		for column: int in range(3):
			var screen_rect := Rect2(1470 + column * 96, 280 + row * 92, 76, 54)
			draw_rect(screen_rect, Color("06141f"))
			draw_line(screen_rect.position + Vector2(8, 36), screen_rect.end - Vector2(8, 12), Color("4cd9e8"), 3.0)
	draw_rect(Rect2(1505, 665, 220, 62), Color("d6cfad"))
	draw_string(ThemeDB.fallback_font, Vector2(1544, 705), "工作清单", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("24323a"))

	# 中央球形容器与“量子力学终极秘密”。
	draw_circle(Vector2(960, 525), 245, Color(0.02, 0.08, 0.14, 0.92))
	draw_arc(Vector2(960, 525), 245, 0.0, TAU, 96, Color("5b829a"), 12.0)
	draw_arc(Vector2(960, 525), 205, 0.0, TAU, 96, Color(0.22, 0.78, 0.92, 0.58), 5.0)
	for radius: float in [150.0, 112.0, 76.0]:
		draw_circle(Vector2(960, 525), radius, Color(0.20, 0.82, 1.0, 0.10 + radius / 900.0))
	draw_circle(Vector2(960, 525), 58, Color("b8f4ff"))
	draw_arc(Vector2(960, 525), 82, 0.0, TAU, 64, Color("68dcef"), 5.0)
	for angle_index: int in range(12):
		var angle: float = TAU * float(angle_index) / 12.0
		var inner := Vector2(960, 525) + Vector2.RIGHT.rotated(angle) * 90.0
		var outer := Vector2(960, 525) + Vector2.RIGHT.rotated(angle + 0.18) * 177.0
		draw_line(inner, outer, Color(0.45, 0.90, 1.0, 0.48), 3.0)

	# 通往储物间的狭窄楼梯。
	draw_rect(Rect2(790, 850, 340, 200), Color("071018"))
	for y: int in range(870, 1040, 28):
		draw_line(Vector2(815, y), Vector2(1105, y), Color("52636c"), 5.0)
	draw_string(ThemeDB.fallback_font, Vector2(835, 825), "返回储物间", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("9eb5c2"))


func _draw_console(rect: Rect2, color: Color) -> void:
	draw_rect(rect, Color("263f51"))
	draw_rect(rect.grow(-12.0), color)
	draw_line(rect.position + Vector2(20, 28), Vector2(rect.end.x - 20, rect.position.y + 28), Color("67c8df"), 4.0)

