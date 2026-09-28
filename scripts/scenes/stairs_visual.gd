class_name StairsVisual
extends Node2D

@export var stair_size: Vector2 = Vector2(238, 138)
@export_range(3, 10, 1) var step_count: int = 7


func _ready() -> void:
	z_index = -12
	queue_redraw()


func _draw() -> void:
	var half_width := stair_size.x * 0.5
	var half_height := stair_size.y * 0.5
	var top_width := half_width * 0.72
	var shape := PackedVector2Array([
		Vector2(-top_width, -half_height),
		Vector2(top_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height),
	])
	draw_colored_polygon(shape, Color(0.16, 0.18, 0.19, 1))

	for step_index in range(step_count + 1):
		var ratio := float(step_index) / float(step_count)
		var y := lerpf(-half_height, half_height, ratio)
		var current_half_width := lerpf(top_width, half_width, ratio)
		var shade := lerpf(0.42, 0.23, ratio)
		draw_line(
			Vector2(-current_half_width, y),
			Vector2(current_half_width, y),
			Color(shade, shade + 0.015, shade + 0.02, 1),
			5.0,
			true
		)

	draw_line(Vector2(-top_width, -half_height), Vector2(-half_width, half_height), Color(0.08, 0.085, 0.09, 1), 8.0, true)
	draw_line(Vector2(top_width, -half_height), Vector2(half_width, half_height), Color(0.08, 0.085, 0.09, 1), 8.0, true)
