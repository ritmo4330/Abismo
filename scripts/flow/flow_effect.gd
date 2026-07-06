extends RefCounted

enum Type {
	RESET_RUNTIME_STATE,
	CLEAR_PENDING_AFTER_DIALOGUE,
	SET_STATE,
	SET_STEP,
	SET_PENDING_AUTO_TIMELINE,
	STOP_BGM,
	SET_CHARACTER_NAME_STATE,
	SET_NPC_LOCATION,
	REQUEST_SCENE,
	REQUEST_DIALOGUE,
	SET_DIALOGIC_VAR,
	SET_PRIVATE_CHAT_TARGET,
	SET_PRIVATE_CHAT_TARGET_FROM_DIALOGIC,
	ENTER_PRIVATE_CHAT,
	REQUEST_SCENE_IF_DIALOGIC_BOOL,
	SHOW_TOAST,
	SET_CAMPFIRE_LIT,
	ADD_SUSPICION_IF_MISSING,
	REQUEST_LOCKED_SUSPICION,
	REFRESH_INITIAL_SEARCH,
}

var type: Type
var chapter_id: String = ""
var step_id: String = ""
var room_id: String = ""
var private_chat_target: String = ""
var npc_id: String = ""
var spawn_name: String = ""
var timeline_name: String = ""
var scene_path: String = ""
var spawn_point: String = ""
var dialogic_path: String = ""
var dialogic_value: Variant = null
var expected_bool: bool = true
var title: String = ""
var kind: String = ""
var seconds: float = 0.0
var is_lit: bool = false
var suspicion_id: String = ""
var source: String = ""
var after_timeline: String = ""
var character_name_state: String = ""


func _init(effect_type: Type) -> void:
	type = effect_type


static func reset_runtime_state() -> RefCounted:
	return new(Type.RESET_RUNTIME_STATE)


static func clear_pending_after_dialogue() -> RefCounted:
	return new(Type.CLEAR_PENDING_AFTER_DIALOGUE)


static func set_state(
	next_chapter_id: String,
	next_step_id: String,
	next_room_id: String = "",
	next_private_chat_target: String = ""
) -> RefCounted:
	var effect: RefCounted = new(Type.SET_STATE)
	effect.chapter_id = next_chapter_id
	effect.step_id = next_step_id
	effect.room_id = next_room_id
	effect.private_chat_target = next_private_chat_target
	return effect


static func set_step(next_step_id: String) -> RefCounted:
	var effect: RefCounted = new(Type.SET_STEP)
	effect.step_id = next_step_id
	return effect


static func set_pending_auto_timeline(next_timeline_name: String) -> RefCounted:
	var effect: RefCounted = new(Type.SET_PENDING_AUTO_TIMELINE)
	effect.timeline_name = next_timeline_name
	return effect


static func stop_bgm() -> RefCounted:
	return new(Type.STOP_BGM)


static func set_character_name_state(name_state: String) -> RefCounted:
	var effect: RefCounted = new(Type.SET_CHARACTER_NAME_STATE)
	effect.character_name_state = name_state
	return effect


static func set_npc_location(
	next_npc_id: String,
	next_room_id: String,
	next_spawn_name: String,
	next_timeline_name: String = "",
	next_scene_path: String = ""
) -> RefCounted:
	var effect: RefCounted = new(Type.SET_NPC_LOCATION)
	effect.npc_id = next_npc_id
	effect.room_id = next_room_id
	effect.spawn_name = next_spawn_name
	effect.timeline_name = next_timeline_name
	effect.scene_path = next_scene_path
	return effect


static func clear_npc_location(next_npc_id: String) -> RefCounted:
	return set_npc_location(next_npc_id, "", "")


static func request_scene(next_scene_path: String, next_spawn_point: String, next_auto_timeline: String = "") -> RefCounted:
	var effect: RefCounted = new(Type.REQUEST_SCENE)
	effect.scene_path = next_scene_path
	effect.spawn_point = next_spawn_point
	effect.timeline_name = next_auto_timeline
	return effect


static func request_dialogue(next_timeline_name: String) -> RefCounted:
	var effect: RefCounted = new(Type.REQUEST_DIALOGUE)
	effect.timeline_name = next_timeline_name
	return effect


static func set_dialogic_var(path: String, value: Variant) -> RefCounted:
	var effect: RefCounted = new(Type.SET_DIALOGIC_VAR)
	effect.dialogic_path = path
	effect.dialogic_value = value
	return effect


static func set_private_chat_target(value: String) -> RefCounted:
	var effect: RefCounted = new(Type.SET_PRIVATE_CHAT_TARGET)
	effect.private_chat_target = value
	return effect


static func set_private_chat_target_from_dialogic(path: String) -> RefCounted:
	var effect: RefCounted = new(Type.SET_PRIVATE_CHAT_TARGET_FROM_DIALOGIC)
	effect.dialogic_path = path
	return effect


static func enter_private_chat() -> RefCounted:
	return new(Type.ENTER_PRIVATE_CHAT)


static func request_scene_if_dialogic_bool(
	path: String,
	expected: bool,
	next_scene_path: String,
	next_spawn_point: String,
	next_auto_timeline: String = ""
) -> RefCounted:
	var effect: RefCounted = new(Type.REQUEST_SCENE_IF_DIALOGIC_BOOL)
	effect.dialogic_path = path
	effect.expected_bool = expected
	effect.scene_path = next_scene_path
	effect.spawn_point = next_spawn_point
	effect.timeline_name = next_auto_timeline
	return effect


static func show_toast(next_title: String, next_kind: String, next_seconds: float) -> RefCounted:
	var effect: RefCounted = new(Type.SHOW_TOAST)
	effect.title = next_title
	effect.kind = next_kind
	effect.seconds = next_seconds
	return effect


static func set_campfire_lit(next_is_lit: bool) -> RefCounted:
	var effect: RefCounted = new(Type.SET_CAMPFIRE_LIT)
	effect.is_lit = next_is_lit
	return effect


static func add_suspicion_if_missing(next_suspicion_id: String, next_source: String, next_step_id: String) -> RefCounted:
	var effect: RefCounted = new(Type.ADD_SUSPICION_IF_MISSING)
	effect.suspicion_id = next_suspicion_id
	effect.source = next_source
	effect.step_id = next_step_id
	return effect


static func request_locked_suspicion(next_suspicion_id: String, next_after_timeline: String) -> RefCounted:
	var effect: RefCounted = new(Type.REQUEST_LOCKED_SUSPICION)
	effect.suspicion_id = next_suspicion_id
	effect.after_timeline = next_after_timeline
	return effect


static func refresh_initial_search() -> RefCounted:
	return new(Type.REFRESH_INITIAL_SEARCH)
