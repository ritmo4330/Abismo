extends Node2D

const FlowEvents = preload("res://scripts/flow/flow_events.gd")
const CG_TEXTURE = preload("res://assets/cg/zhong_yue_lab_placeholder.png")

@export var room_id: String = "lab_cg"
@export var default_spawn_point: String = "InitialSpawn"
@export var hold_seconds: float = 4.5

var _finished: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var cg := TextureRect.new()
	cg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cg.texture = CG_TEXTURE
	cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cg.modulate = Color(1, 1, 1, 0)
	layer.add_child(cg)
	call_deferred("_play", cg)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_finish()


func _play(cg: TextureRect) -> void:
	if SceneManager != null and SceneManager.current_player != null:
		SceneManager.current_player.visible = false
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(cg, "modulate:a", 1.0, 1.1)
	tween.tween_interval(hold_seconds)
	tween.tween_property(cg, "modulate:a", 0.0, 0.9)
	tween.tween_callback(_finish)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	EventBus.flow_signal_requested.emit(FlowEvents.LAB_CG_FINISHED)
