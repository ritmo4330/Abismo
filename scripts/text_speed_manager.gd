extends Node

signal speed_mode_changed(mode_index: int, display_name: String)

const SETTING_NAME: StringName = &"abismo_text_speed_mode"
const MODE_NAMES: Array[String] = ["标准", "快速", "极速"]
const MODE_MULTIPLIERS: Array[float] = [1.0, 1.0 / 6.0, 1.0 / 15.0]
const HOLD_ACCELERATION_MULTIPLIER: float = 0.06
const HOLD_SKIP_INTERVAL: float = 0.06

var _mode_index: int = 0
var _hold_acceleration: bool = false
var _hold_skip_cooldown: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if Dialogic != null and Dialogic.has_subsystem("Settings"):
		_mode_index = clampi(int(Dialogic.Settings.get_setting(SETTING_NAME, 0)), 0, MODE_NAMES.size() - 1)
	_apply_speed()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if key_event.keycode != KEY_CTRL and key_event.physical_keycode != KEY_CTRL:
		return
	if _hold_acceleration == key_event.pressed:
		return
	_hold_acceleration = key_event.pressed
	_hold_skip_cooldown = 0.0
	_apply_speed()


func _process(delta: float) -> void:
	if not _hold_acceleration:
		return
	if Dialogic == null or Dialogic.current_timeline == null or Dialogic.paused:
		return
	if Dialogic.current_state == DialogicGameHandler.States.AWAITING_CHOICE:
		return

	_hold_skip_cooldown -= delta
	if _hold_skip_cooldown > 0.0:
		return
	_hold_skip_cooldown = HOLD_SKIP_INTERVAL

	match Dialogic.current_state:
		DialogicGameHandler.States.REVEALING_TEXT:
			if Dialogic.has_subsystem("Text"):
				Dialogic.Text.skip_text_reveal()
		DialogicGameHandler.States.IDLE, DialogicGameHandler.States.WAITING:
			if Dialogic.has_subsystem("Inputs"):
				Dialogic.Inputs.handle_input()


func cycle_speed_mode() -> void:
	set_speed_mode((_mode_index + 1) % MODE_NAMES.size())


func set_speed_mode(mode_index: int) -> void:
	_mode_index = clampi(mode_index, 0, MODE_NAMES.size() - 1)
	if Dialogic != null and Dialogic.has_subsystem("Settings"):
		Dialogic.Settings.set(SETTING_NAME, _mode_index)
	_apply_speed()
	speed_mode_changed.emit(_mode_index, get_speed_mode_name())


func get_speed_mode_name() -> String:
	return MODE_NAMES[_mode_index]


func get_speed_button_text() -> String:
	return "文本速度：%s" % get_speed_mode_name()


func _apply_speed() -> void:
	if Dialogic == null or not Dialogic.has_subsystem("Text"):
		return
	var multiplier: float = MODE_MULTIPLIERS[_mode_index]
	if _hold_acceleration:
		multiplier *= HOLD_ACCELERATION_MULTIPLIER
	Dialogic.Text.update_text_speed(-1.0, false, 1.0, multiplier)
