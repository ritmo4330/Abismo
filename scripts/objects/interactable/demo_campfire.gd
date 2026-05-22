class_name DemoCampfire
extends Interactable

const FIND_WARMTH_FLAG: String = "demo/find_warmth_started"

@export var starts_lit: bool = false

@onready var flame: Polygon2D = $Visual/Flame
@onready var embers: Polygon2D = $Visual/Embers

var _is_lit: bool = false
var _is_interacting: bool = false


func _ready() -> void:
	super._ready()
	set_lit(starts_lit)


func interact(_player: Player) -> void:
	if _is_interacting:
		return
	if DataManager.get_world_flag(FIND_WARMTH_FLAG):
		if ToastManager != null:
			ToastManager.show_notice("火堆已经彻底熄灭，只剩下一点余温。", "info")
		return

	_relight_and_extinguish()


func set_lit(is_lit: bool) -> void:
	_is_lit = is_lit
	if flame != null:
		flame.visible = _is_lit
	if embers != null:
		embers.color = Color(0.9, 0.18, 0.06, 0.95) if _is_lit else Color(0.18, 0.08, 0.05, 0.9)


func _relight_and_extinguish() -> void:
	_is_interacting = true
	set_lit(true)
	if ToastManager != null:
		ToastManager.show_notice("火堆短暂复燃，又被风雪压了下去。", "info", 2.2)

	await get_tree().create_timer(0.9).timeout
	set_lit(false)
	DataManager.set_world_flag(FIND_WARMTH_FLAG, true)
	if ToastManager != null:
		ToastManager.show_notice("获得任务：寻找温暖", "task", 3.0)
	_is_interacting = false
