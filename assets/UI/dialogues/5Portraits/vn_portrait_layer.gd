@tool
extends DialogicLayoutLayer

@export var portrait_size_mode: DialogicNode_PortraitContainer.SizeModes = DialogicNode_PortraitContainer.SizeModes.FIT_SCALE_HEIGHT

var _layout_refresh_queued: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	if Dialogic != null and Dialogic.has_subsystem("Portraits"):
		if not Dialogic.Portraits.character_joined.is_connected(_on_character_joined):
			Dialogic.Portraits.character_joined.connect(_on_character_joined)
	if Dialogic != null and Dialogic.has_subsystem("Text"):
		if not Dialogic.Text.speaker_updated.is_connected(_on_speaker_updated):
			Dialogic.Text.speaker_updated.connect(_on_speaker_updated)
	_queue_layout_refresh()
	call_deferred("_restore_lane_visibility")


func _exit_tree() -> void:
	if Engine.is_editor_hint() or Dialogic == null:
		return
	if Dialogic.has_subsystem("Portraits") and Dialogic.Portraits.character_joined.is_connected(_on_character_joined):
		Dialogic.Portraits.character_joined.disconnect(_on_character_joined)
	if Dialogic.has_subsystem("Text") and Dialogic.Text.speaker_updated.is_connected(_on_speaker_updated):
		Dialogic.Text.speaker_updated.disconnect(_on_speaker_updated)


func _apply_export_overrides() -> void:
	for child: DialogicNode_PortraitContainer in %Portraits.get_children():
		child.size_mode = portrait_size_mode
		child.update_portrait_transforms()


func _on_character_joined(info: Dictionary) -> void:
	var character: DialogicCharacter = info.get("character", null) as DialogicCharacter
	if character != null:
		_show_character_in_its_lane(character)


func _on_speaker_updated(character: DialogicCharacter) -> void:
	if character != null:
		_show_character_in_its_lane(character)


func _show_character_in_its_lane(character: DialogicCharacter) -> void:
	if Dialogic == null or not Dialogic.has_subsystem("Portraits"):
		return
	if not Dialogic.Portraits.is_character_joined(character):
		return
	var portraits: Dictionary = Dialogic.current_state_info.get("portraits", {})
	var character_id: String = character.get_identifier()
	var current_info: Dictionary = portraits.get(character_id, {})
	var current_node: Node = current_info.get("node", null) as Node
	if current_node == null:
		return
	var lane: String = _canonical_lane(String(current_info.get("position_id", "")))
	for other_id: Variant in portraits.keys():
		var other_info: Dictionary = portraits[other_id]
		var other_node: Node = other_info.get("node", null) as Node
		if other_node == null:
			continue
		if _canonical_lane(String(other_info.get("position_id", ""))) == lane:
			other_node.visible = String(other_id) == character_id
	current_node.visible = true


func _restore_lane_visibility() -> void:
	if Dialogic == null:
		return
	var speaker_id: String = String(Dialogic.current_state_info.get("speaker", ""))
	var portraits: Dictionary = Dialogic.current_state_info.get("portraits", {})
	if not speaker_id.is_empty() and portraits.has(speaker_id):
		var speaker_character: DialogicCharacter = DialogicResourceUtil.get_character_resource(speaker_id)
		if speaker_character != null:
			_show_character_in_its_lane(speaker_character)
			return
	var visible_lane_nodes: Dictionary = {}
	for character_id: Variant in portraits.keys():
		var info: Dictionary = portraits[character_id]
		var node: Node = info.get("node", null) as Node
		if node == null:
			continue
		var lane: String = _canonical_lane(String(info.get("position_id", "")))
		if visible_lane_nodes.has(lane):
			(visible_lane_nodes[lane] as Node).visible = false
		visible_lane_nodes[lane] = node
		node.visible = true


func _canonical_lane(position_id: String) -> String:
	match position_id:
		"leftmost", "far_left", "0":
			return "leftmost"
		"left", "1":
			return "left"
		"center", "middle", "2":
			return "center"
		"right", "center_right", "3":
			return "right"
		"rightmost", "far_right", "4", "5":
			return "rightmost"
	return position_id


func _on_viewport_size_changed() -> void:
	_queue_layout_refresh()


func _queue_layout_refresh() -> void:
	if _layout_refresh_queued:
		return
	_layout_refresh_queued = true
	call_deferred("_refresh_portrait_layout")


func _refresh_portrait_layout() -> void:
	await get_tree().process_frame
	_layout_refresh_queued = false
	for child: DialogicNode_PortraitContainer in %Portraits.get_children():
		child.size_mode = portrait_size_mode
		child.update_portrait_transforms()
