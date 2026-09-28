extends Node

signal save_completed(success: bool, message: String)
signal load_completed(success: bool, message: String)

const SAVE_VERSION: int = 1
const SLOT_NAME: String = "local_save"
const GAME_STATE_FILE: String = "abismo_game_state.txt"

var _pending_load: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func has_save() -> bool:
	return Dialogic != null and Dialogic.has_subsystem("Save") and Dialogic.Save.has_slot(SLOT_NAME)


func save_game() -> Error:
	if SceneManager == null or SceneManager.current_room == null:
		var no_scene_error := ERR_UNCONFIGURED
		save_completed.emit(false, "当前没有可保存的游戏场景")
		return no_scene_error

	var room_scene_path: String = SceneManager.get_current_room_scene_path()
	if room_scene_path.is_empty():
		save_completed.emit(false, "无法识别当前场景")
		return ERR_FILE_BAD_PATH

	var state: Dictionary = {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"room_scene_path": room_scene_path,
		"player_position": SceneManager.get_player_global_position(),
		"data_manager": DataManager.save_runtime_state(),
		"flow_manager": FlowManager.save_runtime_state(),
	}

	var custom_error: Error = Dialogic.Save.save_file(SLOT_NAME, GAME_STATE_FILE, state)
	if custom_error != OK:
		save_completed.emit(false, "本地存档写入失败")
		return custom_error

	var slot_info: Dictionary = {
		"saved_at": state["saved_at"],
		"chapter_id": FlowManager.get_current_chapter_id(),
		"step_id": FlowManager.get_current_step_id(),
	}
	var dialogic_error: Error = Dialogic.Save.save(SLOT_NAME, false, Dialogic.Save.ThumbnailMode.NONE, slot_info)
	var success: bool = dialogic_error == OK
	save_completed.emit(success, "存档完成" if success else "对话状态保存失败")
	return dialogic_error


func request_load_game() -> bool:
	if not has_save():
		load_completed.emit(false, "没有可读取的本地存档")
		return false
	var state_value: Variant = Dialogic.Save.load_file(SLOT_NAME, GAME_STATE_FILE, {})
	if not (state_value is Dictionary) or (state_value as Dictionary).is_empty():
		load_completed.emit(false, "本地存档内容无效")
		return false
	_pending_load = true
	return true


func cancel_pending_load() -> void:
	_pending_load = false


func has_pending_load() -> bool:
	return _pending_load


func restore_pending_game(host_root: Node2D) -> bool:
	if not _pending_load:
		return false
	_pending_load = false

	var state_value: Variant = Dialogic.Save.load_file(SLOT_NAME, GAME_STATE_FILE, {})
	if not (state_value is Dictionary):
		load_completed.emit(false, "本地存档内容无效")
		return false
	var state: Dictionary = state_value as Dictionary
	if state.is_empty():
		load_completed.emit(false, "本地存档内容为空")
		return false

	var data_state: Variant = state.get("data_manager", {})
	if data_state is Dictionary:
		DataManager.load_runtime_state(data_state as Dictionary)
	var flow_state: Variant = state.get("flow_manager", {})
	if flow_state is Dictionary:
		FlowManager.load_runtime_state(flow_state as Dictionary)

	var room_scene_path: String = String(state.get("room_scene_path", ""))
	if room_scene_path.is_empty() or not ResourceLoader.exists(room_scene_path):
		load_completed.emit(false, "存档中的场景已经不存在")
		return false

	GameManager.enter_gameplay()
	SceneManager.initialize(host_root, room_scene_path, "")
	var saved_position: Variant = state.get("player_position", Vector2.ZERO)
	if saved_position is Vector2:
		SceneManager.restore_player_global_position(saved_position)

	var dialogic_error: Error = Dialogic.Save.load(SLOT_NAME)
	if Dialogic.has_subsystem("History"):
		Dialogic.History.load_visited_history()
	# Dialogic variables are restored after the world state, so derived progress
	# flags must be recalculated once more to avoid stale saved booleans.
	if FlowManager != null and FlowManager.has_method("refresh_derived_progress"):
		FlowManager.refresh_derived_progress()
	var success: bool = dialogic_error == OK
	load_completed.emit(success, "读档完成" if success else "对话状态读取失败")
	return success
