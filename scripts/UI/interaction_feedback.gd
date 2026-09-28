extends Node

const INTERACT_COLOR := Color(0.98, 0.82, 0.35, 0.95)
const CHOICE_COLOR := Color(0.45, 0.84, 1.0, 0.9)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_world_interaction(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	if AudioManager != null:
		AudioManager.play_sfx("ui_interact")

	var pulse := Polygon2D.new()
	pulse.name = "InteractionPulse"
	pulse.top_level = true
	pulse.z_index = 900
	pulse.polygon = PackedVector2Array([
		Vector2(0, -26), Vector2(26, 0), Vector2(0, 26), Vector2(-26, 0)
	])
	pulse.color = INTERACT_COLOR
	pulse.global_position = target.global_position
	target.get_tree().current_scene.add_child(pulse)

	var tween := pulse.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(pulse, "scale", Vector2(2.2, 2.2), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.32)
	tween.chain().tween_callback(pulse.queue_free)


func show_choice_feedback(button: Control) -> void:
	if button == null or not is_instance_valid(button):
		return
	if AudioManager != null:
		AudioManager.play_sfx("ui_choice")

	var original_modulate := button.modulate
	button.modulate = CHOICE_COLOR
	var tween := button.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "modulate", original_modulate, 0.18).set_trans(Tween.TRANS_QUAD)

	var flash := ColorRect.new()
	flash.name = "ChoiceFlash"
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.45, 0.84, 1.0, 0.28)
	button.add_child(flash)
	var flash_tween := flash.create_tween()
	flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	flash_tween.tween_callback(flash.queue_free)


func play_panel_toggle() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("ui_panel")
