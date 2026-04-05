extends Node

signal game_state_changed(previous_state: int, new_state: int)
signal game_pause_changed(is_paused: bool)

enum GameState {
	MAIN_MENU,
	IN_GAME,
	PAUSED,
	DIALOGUE,
}

const USER_PAUSE_TOKEN: String = "user_pause"
const DIALOGUE_PAUSE_TOKEN: String = "dialogue"
const SCENE_TRANSITION_PAUSE_TOKEN: String = "scene_transition"

var current_state: GameState = GameState.MAIN_MENU
var _state_before_dialogue: GameState = GameState.IN_GAME
var _pause_tokens: Dictionary[String, bool] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)


func enter_main_menu() -> void:
	_pause_tokens.clear()
	_set_tree_paused(false)
	_set_state(GameState.MAIN_MENU)


func enter_gameplay() -> void:
	if current_state == GameState.DIALOGUE:
		return
	_set_state(GameState.IN_GAME)


func request_pause(token: String = USER_PAUSE_TOKEN) -> void:
	if token.is_empty():
		return
	_pause_tokens[token] = true
	if token == USER_PAUSE_TOKEN and current_state != GameState.DIALOGUE:
		_set_state(GameState.PAUSED)
	_set_tree_paused(true)


func release_pause(token: String = USER_PAUSE_TOKEN) -> void:
	if token.is_empty():
		return
	_pause_tokens.erase(token)

	if not _has_pause_tokens():
		_set_tree_paused(false)
		if current_state == GameState.PAUSED:
			_set_state(GameState.IN_GAME)
		elif current_state == GameState.DIALOGUE:
			_set_state(_state_before_dialogue)


func toggle_user_pause() -> void:
	if current_state == GameState.DIALOGUE:
		return
	if _pause_tokens.has(USER_PAUSE_TOKEN):
		release_pause(USER_PAUSE_TOKEN)
	else:
		request_pause(USER_PAUSE_TOKEN)


func start_dialogue_state() -> void:
	if current_state != GameState.DIALOGUE:
		_state_before_dialogue = current_state
	_set_state(GameState.DIALOGUE)
	request_pause(DIALOGUE_PAUSE_TOKEN)


func end_dialogue_state() -> void:
	release_pause(DIALOGUE_PAUSE_TOKEN)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_pause_input(event):
		return
	if current_state != GameState.IN_GAME and current_state != GameState.PAUSED:
		return
	get_viewport().set_input_as_handled()
	toggle_user_pause()


func _is_pause_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed:
		return false
	if key_event.echo:
		return false
	return key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE


func _has_pause_tokens() -> bool:
	return _pause_tokens.size() > 0


func _set_tree_paused(is_paused: bool) -> void:
	if get_tree().paused == is_paused:
		return
	get_tree().paused = is_paused
	game_pause_changed.emit(is_paused)


func _set_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	var previous_state: GameState = current_state
	current_state = new_state
	game_state_changed.emit(previous_state, current_state)
