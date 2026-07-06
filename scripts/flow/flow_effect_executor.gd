extends RefCounted

const FlowEffect = preload("res://scripts/flow/flow_effect.gd")

var _owner: Node = null


func setup(owner: Node) -> void:
	_owner = owner


func execute_many(effects: Array[RefCounted]) -> void:
	for effect: RefCounted in effects:
		execute(effect)


func execute(effect: RefCounted) -> void:
	if effect == null or _owner == null:
		return

	match effect.type:
		FlowEffect.Type.RESET_RUNTIME_STATE:
			if DataManager != null and DataManager.has_method("reset_runtime_state"):
				DataManager.reset_runtime_state()
		FlowEffect.Type.CLEAR_PENDING_AFTER_DIALOGUE:
			_owner.clear_pending_after_dialogue()
		FlowEffect.Type.SET_STATE:
			_owner.apply_flow_state(effect.chapter_id, effect.step_id, effect.room_id, effect.private_chat_target)
		FlowEffect.Type.SET_STEP:
			_owner.advance_to_step(effect.step_id)
		FlowEffect.Type.SET_PENDING_AUTO_TIMELINE:
			_owner.set_pending_auto_timeline(effect.timeline_name)
		FlowEffect.Type.STOP_BGM:
			_owner.stop_bgm()
		FlowEffect.Type.SET_CHARACTER_NAME_STATE:
			_owner.apply_character_name_state(effect.character_name_state)
		FlowEffect.Type.SET_NPC_LOCATION:
			_owner.set_npc_location(
				_resolve_effect_text(effect.npc_id),
				_resolve_effect_text(effect.room_id),
				_resolve_effect_text(effect.spawn_name),
				_resolve_effect_text(effect.timeline_name),
				_resolve_effect_text(effect.scene_path)
			)
		FlowEffect.Type.REQUEST_SCENE:
			_owner.request_scene(
				_resolve_effect_text(effect.scene_path),
				_resolve_effect_text(effect.spawn_point),
				_resolve_effect_text(effect.timeline_name)
			)
		FlowEffect.Type.REQUEST_DIALOGUE:
			EventBus.dialogue_requested.emit(_resolve_effect_text(effect.timeline_name))
		FlowEffect.Type.SET_DIALOGIC_VAR:
			_owner.set_dialogic_var(effect.dialogic_path, effect.dialogic_value)
		FlowEffect.Type.SET_PRIVATE_CHAT_TARGET:
			_owner.set_private_chat_target(effect.private_chat_target)
		FlowEffect.Type.SET_PRIVATE_CHAT_TARGET_FROM_DIALOGIC:
			_owner.set_private_chat_target(String(_owner.get_dialogic_var(effect.dialogic_path, "")))
		FlowEffect.Type.ENTER_PRIVATE_CHAT:
			_owner.enter_private_chat()
		FlowEffect.Type.REQUEST_SCENE_IF_DIALOGIC_BOOL:
			if bool(_owner.get_dialogic_var(effect.dialogic_path, false)) == effect.expected_bool:
				_owner.request_scene(
					_resolve_effect_text(effect.scene_path),
					_resolve_effect_text(effect.spawn_point),
					_resolve_effect_text(effect.timeline_name)
				)
		FlowEffect.Type.SHOW_TOAST:
			if ToastManager != null:
				ToastManager.show_notice(effect.title, effect.kind, effect.seconds)
		FlowEffect.Type.SET_CAMPFIRE_LIT:
			_owner.set_current_ch0_campfire_lit(effect.is_lit)
		FlowEffect.Type.ADD_SUSPICION_IF_MISSING:
			if DataManager != null and not DataManager.has_suspicion(effect.suspicion_id):
				DataManager.discover_suspicion(effect.suspicion_id, effect.source, effect.step_id)
		FlowEffect.Type.REQUEST_LOCKED_SUSPICION:
			EventBus.locked_suspicion_requested.emit(effect.suspicion_id, effect.after_timeline)
		FlowEffect.Type.REFRESH_INITIAL_SEARCH:
			_owner.refresh_initial_search_finished()
		_:
			push_warning("FlowEffectExecutor: unhandled effect type '%s'." % str(effect.type))


func _resolve_effect_text(value: String) -> String:
	return value.replace("{private_chat_target}", _owner.get_private_chat_target())
