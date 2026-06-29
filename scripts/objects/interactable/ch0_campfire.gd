class_name Ch0Campfire
extends Interactable

const FIND_WARMTH_FLAG: String = "ch0/find_warmth_started"

@export var starts_lit: bool = false
@export var lit_light_energy: float = 0.95
@export var flicker_energy_min: float = 0.68
@export var flicker_energy_max: float = 1.08
@export var flicker_seconds_min: float = 0.08
@export var flicker_seconds_max: float = 0.18

@onready var warm_light: PointLight2D = $WarmLight

var _is_lit: bool = false
var _is_interacting: bool = false
var _flicker_tween: Tween = null


func _ready() -> void:
	super._ready()
	if DataManager != null and not DataManager.world_flag_changed.is_connected(_on_world_flag_changed):
		DataManager.world_flag_changed.connect(_on_world_flag_changed)
	var initial_lit: bool = starts_lit
	if DataManager != null and DataManager.get_world_flag(FIND_WARMTH_FLAG):
		initial_lit = false
	set_lit(initial_lit)
	_refresh_highlight()


func interact(_player: Player) -> void:
	if _is_interacting:
		return
	if DataManager.get_world_flag(FIND_WARMTH_FLAG):
		if ToastManager != null:
			ToastManager.show_notice("火堆已经彻底熄灭，只剩下一点余温。", "info")
		_refresh_highlight()
		return

	_relight_and_extinguish()


func set_lit(is_lit: bool) -> void:
	_is_lit = is_lit
	_notify_room_fire_state()
	if warm_light == null:
		return

	warm_light.enabled = _is_lit
	if _is_lit:
		_start_light_flicker()
	else:
		_stop_light_flicker()
		warm_light.energy = 0.0


func _relight_and_extinguish() -> void:
	_is_interacting = true
	_refresh_highlight()
	set_lit(true)
	if ToastManager != null:
		ToastManager.show_notice("火堆短暂复燃，又被风雪压了下去。", "info", 2.2)

	await get_tree().create_timer(0.9).timeout
	set_lit(false)
	DataManager.set_world_flag(FIND_WARMTH_FLAG, true)
	if ToastManager != null:
		ToastManager.show_notice("获得任务：寻找温暖", "task", 3.0)
	_is_interacting = false
	_refresh_highlight()


func _refresh_highlight() -> void:
	set_highlight_active(not _is_interacting and not DataManager.get_world_flag(FIND_WARMTH_FLAG))


func _start_light_flicker() -> void:
	_stop_light_flicker()
	warm_light.energy = lit_light_energy
	_flicker_tween = create_tween()
	_flicker_tween.set_loops()
	_flicker_tween.tween_property(warm_light, "energy", flicker_energy_max, flicker_seconds_min)
	_flicker_tween.tween_property(warm_light, "energy", flicker_energy_min, flicker_seconds_max)
	_flicker_tween.tween_property(warm_light, "energy", lit_light_energy, flicker_seconds_min)


func _stop_light_flicker() -> void:
	if _flicker_tween != null:
		_flicker_tween.kill()
		_flicker_tween = null


func _on_world_flag_changed(flag_id: String, _value: bool) -> void:
	if flag_id == FIND_WARMTH_FLAG:
		_refresh_highlight()


func _notify_room_fire_state() -> void:
	var current: Node = self
	while current != null:
		if current.has_method("set_campfire_visual_lit"):
			current.set_campfire_visual_lit(_is_lit)
			return
		current = current.get_parent()
