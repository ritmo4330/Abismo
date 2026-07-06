extends RefCounted

enum Type {
	SET_STEP,
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
var payload: Dictionary = {}


func _init(command_type: Type, command_payload: Dictionary = {}) -> void:
	type = command_type
	payload = command_payload


static func set_step(step_id: String) -> RefCounted:
	return new(Type.SET_STEP, {"step_id": step_id})


static func set_npc_location(
	npc_id: String,
	room_id: String,
	spawn_name: String,
	timeline_name: String = "",
	scene_path: String = ""
) -> RefCounted:
	return new(Type.SET_NPC_LOCATION, {
		"npc_id": npc_id,
		"room_id": room_id,
		"spawn_name": spawn_name,
		"timeline_name": timeline_name,
		"scene_path": scene_path,
	})


static func clear_npc_location(npc_id: String) -> RefCounted:
	return set_npc_location(npc_id, "", "")


static func request_scene(scene_path: String, spawn_point: String, auto_timeline: String = "") -> RefCounted:
	return new(Type.REQUEST_SCENE, {
		"scene_path": scene_path,
		"spawn_point": spawn_point,
		"auto_timeline": auto_timeline,
	})


static func request_dialogue(timeline_name: String) -> RefCounted:
	return new(Type.REQUEST_DIALOGUE, {"timeline_name": timeline_name})


static func set_dialogic_var(path: String, value: Variant) -> RefCounted:
	return new(Type.SET_DIALOGIC_VAR, {"path": path, "value": value})


static func set_private_chat_target(value: String) -> RefCounted:
	return new(Type.SET_PRIVATE_CHAT_TARGET, {"value": value})


static func set_private_chat_target_from_dialogic(path: String) -> RefCounted:
	return new(Type.SET_PRIVATE_CHAT_TARGET_FROM_DIALOGIC, {"path": path})


static func enter_private_chat() -> RefCounted:
	return new(Type.ENTER_PRIVATE_CHAT)


static func request_scene_if_dialogic_bool(
	path: String,
	expected: bool,
	scene_path: String,
	spawn_point: String,
	auto_timeline: String = ""
) -> RefCounted:
	return new(Type.REQUEST_SCENE_IF_DIALOGIC_BOOL, {
		"path": path,
		"expected": expected,
		"scene_path": scene_path,
		"spawn_point": spawn_point,
		"auto_timeline": auto_timeline,
	})


static func show_toast(title: String, kind: String, seconds: float) -> RefCounted:
	return new(Type.SHOW_TOAST, {"title": title, "kind": kind, "seconds": seconds})


static func set_campfire_lit(is_lit: bool) -> RefCounted:
	return new(Type.SET_CAMPFIRE_LIT, {"is_lit": is_lit})


static func add_suspicion_if_missing(suspicion_id: String, source: String, step_id: String) -> RefCounted:
	return new(Type.ADD_SUSPICION_IF_MISSING, {
		"suspicion_id": suspicion_id,
		"source": source,
		"step_id": step_id,
	})


static func request_locked_suspicion(suspicion_id: String, after_timeline: String) -> RefCounted:
	return new(Type.REQUEST_LOCKED_SUSPICION, {
		"suspicion_id": suspicion_id,
		"after_timeline": after_timeline,
	})


static func refresh_initial_search() -> RefCounted:
	return new(Type.REFRESH_INITIAL_SEARCH)
