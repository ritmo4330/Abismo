extends CanvasLayer

const PANEL_ID: String = "pause_panel"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/UI/main_menu.tscn"

@onready var resume_button: Button = $PanelRoot/CenterContainer/PanelFrame/MarginContainer/ButtonVBox/ResumeButton
@onready var quit_to_title_button: Button = $PanelRoot/CenterContainer/PanelFrame/MarginContainer/ButtonVBox/QuitToTitleButton
@onready var quit_game_button: Button = $PanelRoot/CenterContainer/PanelFrame/MarginContainer/ButtonVBox/QuitGameButton

var _is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	hide()

	if not resume_button.pressed.is_connected(_on_resume_button_pressed):
		resume_button.pressed.connect(_on_resume_button_pressed)
	if not quit_to_title_button.pressed.is_connected(_on_quit_to_title_button_pressed):
		quit_to_title_button.pressed.connect(_on_quit_to_title_button_pressed)
	if not quit_game_button.pressed.is_connected(_on_quit_game_button_pressed):
		quit_game_button.pressed.connect(_on_quit_game_button_pressed)

	if GameManager != null and not GameManager.game_state_changed.is_connected(_on_game_state_changed):
		GameManager.game_state_changed.connect(_on_game_state_changed)
	if EventBus != null and not EventBus.ui_panel_focus_requested.is_connected(_on_ui_panel_focus_requested):
		EventBus.ui_panel_focus_requested.connect(_on_ui_panel_focus_requested)

	if GameManager != null and int(GameManager.current_state) == int(GameManager.GameState.PAUSED):
		_open_panel()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if not _is_close_input(event):
		return

	_resume_game()
	get_viewport().set_input_as_handled()


func _on_resume_button_pressed() -> void:
	_resume_game()


func _on_quit_to_title_button_pressed() -> void:
	if GameManager != null and GameManager.has_method("enter_main_menu"):
		GameManager.enter_main_menu()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_quit_game_button_pressed() -> void:
	get_tree().quit()


func _on_game_state_changed(_previous_state: int, new_state: int) -> void:
	if new_state == int(GameManager.GameState.PAUSED):
		_open_panel()
		return
	_close_panel(false)


func _on_ui_panel_focus_requested(panel_id: String) -> void:
	if panel_id == PANEL_ID:
		return
	_close_panel(true)


func _resume_game() -> void:
	_close_panel(true)


func _open_panel() -> void:
	if _is_open:
		return

	if EventBus != null:
		EventBus.ui_panel_focus_requested.emit(PANEL_ID)
	_is_open = true
	show()
	resume_button.grab_focus()


func _close_panel(should_release_pause: bool) -> void:
	if not _is_open:
		return

	_is_open = false
	hide()

	if should_release_pause and GameManager != null and GameManager.has_method("release_pause"):
		GameManager.release_pause(GameManager.USER_PAUSE_TOKEN)


func _is_close_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed:
		return false
	if key_event.echo:
		return false
	return key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE
