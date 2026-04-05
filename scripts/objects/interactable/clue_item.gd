class_name ClueItem
extends Interactable

@export var clue_id: String = ""
@export var clue_def: ClueData
@export var child_clue_defs: Array[ClueData] = []
@export var source_id: String = ""


func _ready() -> void:
	super._ready()
	_register_clue_defs()


func interact(_player: Player) -> void:
	var target_clue_id: String = _resolve_clue_id()
	if target_clue_id.is_empty():
		push_warning("ClueItem has no clue id configured.")
		return

	var investigate_flag: String = _build_investigate_flag(target_clue_id)
	var has_investigated_once: bool = DataManager.get_world_flag(investigate_flag)
	if not has_investigated_once:
		DataManager.set_world_flag(investigate_flag, true)

	DataManager.add_clue(target_clue_id, "scene", _resolve_source_id(target_clue_id))

	var child_ids: Array[String] = DataManager.get_child_clue_ids(target_clue_id)
	if child_ids.is_empty():
		_emit_single_detail(target_clue_id)
		return

	if not has_investigated_once:
		_emit_single_detail(target_clue_id)
		return

	if not DataManager.is_deep_unlocked(target_clue_id):
		DataManager.mark_deep_unlocked(target_clue_id)

	_emit_hierarchical_detail(target_clue_id, child_ids)


func _register_clue_defs() -> void:
	if clue_def != null:
		DataManager.register_clue_def(clue_def)
	for child_def: ClueData in child_clue_defs:
		if child_def == null:
			continue
		DataManager.register_clue_def(child_def)


func _resolve_clue_id() -> String:
	if not clue_id.is_empty():
		return clue_id
	if clue_def != null and not clue_def.id.is_empty():
		return clue_def.id
	if not interact_id.is_empty():
		return interact_id
	return ""


func _resolve_source_id(target_clue_id: String) -> String:
	if not source_id.is_empty():
		return source_id
	if not interact_id.is_empty():
		return interact_id
	if not target_clue_id.is_empty():
		return target_clue_id
	return name


func _build_investigate_flag(target_clue_id: String) -> String:
	return "clue_investigated/%s" % target_clue_id


func _emit_single_detail(target_clue_id: String) -> void:
	var payload: Dictionary = {
		"mode": "interaction",
		"display_type": "single",
		"parent_clue_id": target_clue_id,
		"clue_ids": [target_clue_id],
	}
	EventBus.clue_interaction_details_requested.emit(payload)


func _emit_hierarchical_detail(parent_clue_id: String, child_ids: Array[String]) -> void:
	var clue_ids: Array[String] = [parent_clue_id]
	for child_id: String in child_ids:
		clue_ids.append(child_id)

	var payload: Dictionary = {
		"mode": "interaction",
		"display_type": "hierarchical",
		"parent_clue_id": parent_clue_id,
		"child_clue_ids": child_ids.duplicate(),
		"clue_ids": clue_ids,
	}
	EventBus.clue_interaction_details_requested.emit(payload)
