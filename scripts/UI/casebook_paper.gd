extends Control

var book := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4330
	for i: int in range(850):
		var point := Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		draw_circle(point, rng.randf_range(0.35, 1.2), Color(0.35, 0.28, 0.18, rng.randf_range(0.018, 0.055)))
	draw_rect(Rect2(Vector2(12, 12), size - Vector2(24, 24)), Color(0.43, 0.35, 0.25, 0.26), false, 1)
	draw_rect(Rect2(Vector2(17, 17), size - Vector2(34, 34)), Color(0.43, 0.35, 0.25, 0.12), false, 1)
	if book:
		for i: int in range(18):
			var alpha := 0.05 * (1.0 - float(i) / 18.0)
			draw_line(Vector2(size.x * 0.5 - i, 20), Vector2(size.x * 0.5 - i, size.y - 20), Color(0.15, 0.12, 0.1, alpha), 1)
			draw_line(Vector2(size.x * 0.5 + i, 20), Vector2(size.x * 0.5 + i, size.y - 20), Color(0.15, 0.12, 0.1, alpha), 1)
	var origin := Vector2(size.x - 86, size.y - 86)
	for radius: float in [52.0, 58.0, 72.0]:
		draw_arc(origin, radius, 0, TAU, 96, Color(0.39, 0.36, 0.31, 0.12), 1)
	for i: int in range(16):
		var direction := Vector2.from_angle(TAU * float(i) / 16.0)
		draw_line(origin + direction * 20, origin + direction * (70 if i % 4 == 0 else 55), Color(0.39, 0.36, 0.31, 0.1), 1)

