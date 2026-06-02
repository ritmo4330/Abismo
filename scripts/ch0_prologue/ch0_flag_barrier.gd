extends StaticBody2D
class_name Ch0FlagBarrier

@export var required_flag: String = ""
@export var blocked_notice: String = ""

var _notice_cooldown: float = 0.0


func _ready() -> void:
	var notice_area: Area2D = find_child("NoticeArea", true, false) as Area2D
	if notice_area != null and not notice_area.body_entered.is_connected(_on_notice_area_body_entered):
		notice_area.body_entered.connect(_on_notice_area_body_entered)


func _process(delta: float) -> void:
	if not required_flag.is_empty() and DataManager.get_world_flag(required_flag):
		queue_free()
		return

	if _notice_cooldown > 0.0:
		_notice_cooldown = maxf(0.0, _notice_cooldown - delta)


func show_blocked_notice() -> void:
	if blocked_notice.is_empty() or _notice_cooldown > 0.0:
		return
	if ToastManager != null and ToastManager.has_method("show_notice"):
		ToastManager.show_notice(blocked_notice, "warning")
	_notice_cooldown = 1.5


func _on_notice_area_body_entered(body: Node2D) -> void:
	if body != null and body.is_in_group("player"):
		show_blocked_notice()
