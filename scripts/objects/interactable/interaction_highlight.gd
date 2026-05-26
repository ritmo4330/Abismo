class_name InteractionHighlight
extends Node2D

@export var min_alpha: float = 0.25
@export var max_alpha: float = 0.85
@export var pulse_scale: float = 1.08
@export var pulse_seconds: float = 0.55

@onready var glow: Sprite2D = $Glow

var base_scale: Vector2 = Vector2.ONE
var _pulse_tween: Tween = null


func _ready() -> void:
	base_scale = scale
	set_active(visible)


func set_base_scale(value: Vector2) -> void:
	base_scale = value
	if visible:
		scale = base_scale


func set_tint(color: Color) -> void:
	if glow != null:
		glow.modulate = color


func set_active(is_active: bool) -> void:
	visible = is_active
	if is_active:
		_start_pulse()
	else:
		_stop_pulse()


func _start_pulse() -> void:
	_stop_pulse()
	modulate.a = min_alpha
	scale = base_scale

	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE)
	_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "modulate:a", max_alpha, pulse_seconds)
	_pulse_tween.parallel().tween_property(self, "scale", base_scale * pulse_scale, pulse_seconds)
	_pulse_tween.tween_property(self, "modulate:a", min_alpha, pulse_seconds)
	_pulse_tween.parallel().tween_property(self, "scale", base_scale, pulse_seconds)


func _stop_pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	modulate.a = min_alpha
	scale = base_scale
