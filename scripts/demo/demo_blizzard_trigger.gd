class_name DemoBlizzardTrigger
extends Area2D

@export var notice_text: String = "暴风雪刮过。"
@export var notice_type: String = "warning"
@export var one_shot: bool = true

var _has_triggered: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if one_shot and _has_triggered:
		return
	if not body.is_in_group("player"):
		return

	_has_triggered = true
	var room: Node = _find_room_with_blizzard_flash()
	if room != null and room.has_method("play_blizzard_flash"):
		room.play_blizzard_flash()
	if ToastManager != null and ToastManager.has_method("show_notice"):
		ToastManager.show_notice(notice_text, notice_type)


func _find_room_with_blizzard_flash() -> Node:
	var current: Node = self
	while current != null:
		if current.has_method("play_blizzard_flash"):
			return current
		current = current.get_parent()
	return null
