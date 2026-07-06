extends RefCounted

const FlowCommand = preload("res://scripts/flow/flow_command.gd")
const FlowIds = preload("res://scripts/flow/flow_ids.gd")

var _owner: Node = null


func setup(owner: Node) -> void:
	_owner = owner


func execute_many(commands: Array[RefCounted]) -> void:
	for command: RefCounted in commands:
		execute(command)


func execute(command: RefCounted) -> void:
	if command == null or _owner == null:
		return

	var payload: Dictionary = command.payload
	match command.type:
		FlowCommand.Type.SET_STEP:
			_owner.set_step(String(payload.get("step_id", "")))
		FlowCommand.Type.SET_NPC_LOCATION:
			_owner.set_npc_location(
				_resolve_command_text(String(payload.get("npc_id", ""))),
				_resolve_command_text(String(payload.get("room_id", ""))),
				_resolve_command_text(String(payload.get("spawn_name", ""))),
				_resolve_command_text(String(payload.get("timeline_name", ""))),
				_resolve_command_text(String(payload.get("scene_path", "")))
			)
		FlowCommand.Type.REQUEST_SCENE:
			_owner.request_scene_change(
				_resolve_command_text(String(payload.get("scene_path", ""))),
				_resolve_command_text(String(payload.get("spawn_point", ""))),
				_resolve_command_text(String(payload.get("auto_timeline", "")))
			)
		FlowCommand.Type.REQUEST_DIALOGUE:
			EventBus.dialogue_requested.emit(_resolve_command_text(String(payload.get("timeline_name", ""))))
		FlowCommand.Type.SET_DIALOGIC_VAR:
			_owner.set_dialogic_var(String(payload.get("path", "")), payload.get("value", null))
		FlowCommand.Type.SET_PRIVATE_CHAT_TARGET:
			_owner.set_private_chat_target(String(payload.get("value", "")))
		FlowCommand.Type.SET_PRIVATE_CHAT_TARGET_FROM_DIALOGIC:
			_owner.set_private_chat_target(String(_owner.get_dialogic_var(String(payload.get("path", "")), "")))
		FlowCommand.Type.ENTER_PRIVATE_CHAT:
			_owner.enter_private_chat()
		FlowCommand.Type.REQUEST_SCENE_IF_DIALOGIC_BOOL:
			if bool(_owner.get_dialogic_var(String(payload.get("path", "")), false)) == bool(payload.get("expected", true)):
				_owner.request_scene_change(
					_resolve_command_text(String(payload.get("scene_path", ""))),
					_resolve_command_text(String(payload.get("spawn_point", ""))),
					_resolve_command_text(String(payload.get("auto_timeline", "")))
				)
		FlowCommand.Type.SHOW_TOAST:
			if ToastManager != null:
				ToastManager.show_notice(
					String(payload.get("title", "")),
					String(payload.get("kind", "notice")),
					float(payload.get("seconds", 2.5))
				)
		FlowCommand.Type.SET_CAMPFIRE_LIT:
			_owner.set_current_ch0_campfire_lit(bool(payload.get("is_lit", false)))
		FlowCommand.Type.ADD_SUSPICION_IF_MISSING:
			var suspicion_id: String = String(payload.get("suspicion_id", ""))
			if DataManager != null and not DataManager.has_suspicion(suspicion_id):
				DataManager.add_suspicion(
					suspicion_id,
					String(payload.get("source", "flow")),
					String(payload.get("step_id", _owner.get_current_step_id()))
				)
		FlowCommand.Type.REQUEST_LOCKED_SUSPICION:
			EventBus.locked_suspicion_requested.emit(
				String(payload.get("suspicion_id", "")),
				String(payload.get("after_timeline", ""))
			)
		FlowCommand.Type.REFRESH_INITIAL_SEARCH:
			_owner.refresh_initial_search_finished()
		_:
			push_warning("FlowCommandExecutor: unhandled command type '%s'." % str(command.type))


func _resolve_command_text(value: String) -> String:
	return value.replace("{private_chat_target}", _owner.get_private_chat_target())
