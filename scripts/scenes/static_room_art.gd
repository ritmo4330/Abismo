extends Node2D

signal view_changed

const MANIFEST_PATH := "res://assets/art/static_scenes/manifest.json"
const CANVAS := Vector2(1920, 1080)
const SOURCE = preload("res://scripts/clues/source_investigation.gd")
static var _manifest: Dictionary = {}

var room: Node2D = null
var config: Dictionary = {}
var current_view: String = ""
var background: Sprite2D = null
var _textures: Dictionary = {}
# Never use Object keys: freed Nodes change their key hash and can make a
# Dictionary iterator cycle forever after the flow rebuilds dynamic clues.
var _hotspots: Dictionary[int, Rect2] = {}
var _hovered: Interactable = null
var _dream_material: ShaderMaterial


static func get_config(room_id: String) -> Dictionary:
	if _manifest.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if parsed is Dictionary:
			_manifest = parsed
	return _manifest.get("rooms", {}).get(room_id, {})


func setup(target_room: Node2D, room_id: String) -> bool:
	room = target_room
	config = get_config(room_id)
	if config.is_empty():
		return false
	var texture: Texture2D = _load_texture(_resolve_asset())
	if texture == null:
		return false
	var old_map: CanvasItem = room.find_child("MapLayer", true, false) as CanvasItem
	if old_map != null:
		old_map.hide()
	for node: Node in room.find_children("*", "CanvasItem", true, false):
		var script: Script = node.get_script()
		if node is Sprite2D or node is Polygon2D or node is Line2D or node is TileMapLayer or node is CanvasModulate:
			(node as CanvasItem).hide()
		elif script != null and (script.resource_path.ends_with("_visual.gd") or script.resource_path.ends_with("stairs_visual.gd")):
			# Legacy procedural scenery otherwise draws walls/black strips over
			# the new static painting. Keep interaction nodes themselves alive.
			(node as CanvasItem).hide()
		elif node is Light2D:
			(node as Light2D).enabled = false
	for node: Node in room.find_children("*", "StaticBody2D", true, false):
		(node as StaticBody2D).input_pickable = false
	background = Sprite2D.new()
	background.name = "InvestigationBackground"
	background.centered = false
	background.z_index = -1000
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_dream_material = ShaderMaterial.new()
	_dream_material.shader = preload("res://assets/UI/dream_background.gdshader")
	background.material = _dream_material
	_sync_dream_filter()
	add_child(background)
	_apply_texture(texture)
	current_view = "villa" if not SOURCE.views(room_id, String(config.get("asset", ""))).is_empty() else (room_id if config.has("views") else "")
	EventBus.room_loaded.connect(_on_room_loaded)
	DataManager.clue_updated.connect(_on_clue_state_changed)
	return true


func _resolve_asset() -> String:
	if String(room.get("room_id")) == "ch1_crime_scene_lin_room" and FlowManager.get_current_step_id() == "ch1_2_crime_scene":
		return "hall"
	for variant: Dictionary in config.get("variants", []):
		var clue: String = String(variant.get("clue", ""))
		var steps: Array = variant.get("steps", [])
		if (not clue.is_empty() and DataManager.has_clue(clue)) or steps.has(FlowManager.get_current_step_id()):
			return String(variant.asset)
	return String(config.get("asset", ""))

func _sync_dream_filter() -> void:
	if _dream_material != null:
		_dream_material.set_shader_parameter("dream_strength", 1.0 if FlowManager.get_current_chapter_id() in ["ch2_deepening", "ch3_transcend"] else 0.0)

func _process(_delta: float) -> void:
	_sync_dream_filter()


func _on_clue_state_changed(_clue_id: String) -> void:
	if not get_views().is_empty() or background == null:
		return
	var texture: Texture2D = _load_texture(_resolve_asset())
	if texture != null:
		_apply_texture(texture)


func _load_texture(asset_id: String) -> Texture2D:
	if _textures.has(asset_id):
		return _textures[asset_id] as Texture2D
	var path: String = "res://assets/art/static_scenes/%s-v1.png" % asset_id
	if not ResourceLoader.exists(path):
		return null
	var texture: Texture2D = load(path) as Texture2D
	_textures[asset_id] = texture
	return texture


func _apply_texture(texture: Texture2D) -> void:
	background.texture = texture
	background.scale = CANVAS / texture.get_size()


func _on_room_loaded(loaded_room: Node2D, _room_id: String) -> void:
	if loaded_room != room:
		return
	for node: Node in room.find_children("*", "Area2D", true, false):
		if node is Interactable:
			configure_interactable(node as Interactable)


func configure_interactable(item: Interactable) -> void:
	if item is NpcDialogue:
		(item as NpcDialogue).visual.hide()
		item.input_pickable = false
		return
	var data: Array = []
	if item is ClueItem:
		var clue_id: String = (item as ClueItem).clue_id
		data = config.get("hotspots", {}).get(clue_id, [])
		if item.has_meta("source_hotspot"):
			var source_rect: Rect2 = item.get_meta("source_hotspot")
			data = [source_rect.position.x, source_rect.position.y, source_rect.size.x, source_rect.size.y]
		var view_id: String = String(config.get("clue_views", {}).get(clue_id, config.get("asset", "")))
		if config.has("views"):
			item.visible = view_id == current_view
			item.input_pickable = item.visible
		elif not SOURCE.views(String(room.get("room_id")), _resolve_asset()).is_empty():
			item.visible = String(item.get_meta("source_space", "villa")) == current_view
			item.input_pickable = item.visible
	elif config.get("objects", {}).has(String(item.name)):
		data = config["objects"][String(item.name)]
	elif item is Door or item is Passage:
		if String(item.name) == "ChuWuJian" and config.has("views"):
			item.set_meta("static_art_view", "storeroom")
			data = [0.25, 0.36, 0.11, 0.46]
		elif _door_destination(item) == room.scene_file_path.get_file().get_basename() and String(item.get("flow_signal_name") if item is Door else "").is_empty():
			item.hide()
			item.input_pickable = false
			_hotspots.erase(item.get_instance_id())
			return
		else:
			data = _door_rect(item)
		item.visible = current_view in ["", "villa"] or current_view == String(config.get("asset", ""))
		item.input_pickable = item.visible
	if data.size() != 4:
		return
	# AVG clicks are resolved once, before physics picking. Nested objects and
	# later-round clues must not depend on Area2D creation order.
	item.input_pickable = false
	item.scale = Vector2.ONE
	item.global_position = room.global_position + Vector2(float(data[0]), float(data[1])) * CANVAS
	item.z_index = 20 if item is ClueItem else 10
	var size := Vector2(maxf(float(data[2]) * CANVAS.x, 44), maxf(float(data[3]) * CANVAS.y, 44))
	var instance_id: int = item.get_instance_id()
	_hotspots[instance_id] = Rect2(item.global_position - size * 0.5, size)
	var unregister := _unregister_hotspot.bind(instance_id)
	if not item.tree_exiting.is_connected(unregister):
		item.tree_exiting.connect(unregister, CONNECT_ONE_SHOT)
	item.highlight_offset = Vector2.ZERO
	item.highlight_scale = Vector2(0.65, 0.65)
	item.prompt_offset = Vector2.ZERO
	for child: Node in item.get_children():
		if child is CollisionShape2D:
			var collision: CollisionShape2D = child as CollisionShape2D
			var shape := RectangleShape2D.new()
			shape.size = Vector2(maxf(float(data[2]) * CANVAS.x, 44), maxf(float(data[3]) * CANVAS.y, 44))
			collision.position = Vector2.ZERO
			collision.shape = shape
	if item.has_method("_refresh_highlight"):
		item.call("_refresh_highlight")


func _door_rect(item: Interactable) -> Array:
	return config.get("doors", {}).get(_door_destination(item), config.get("exit", []))


func _door_destination(item: Interactable) -> String:
	var path_value: Variant = item.get("target_scene_path")
	var destination: String = ""
	if path_value != null and not String(path_value).is_empty():
		var path: String = String(path_value)
		if path.begins_with("uid://"):
			path = ResourceUID.get_id_path(ResourceUID.text_to_id(path))
		destination = path.get_file().get_basename()
	return destination


func get_views() -> Dictionary:
	var source_views := SOURCE.views(String(room.get("room_id")), _resolve_asset())
	return source_views if not source_views.is_empty() else config.get("views", {})


func set_view(view_id: String) -> bool:
	var views: Dictionary = get_views()
	if not views.has(view_id):
		return false
	var texture: Texture2D = _load_texture(String(views[view_id].get("asset", "")))
	if texture == null:
		return false
	current_view = view_id
	_clear_hover()
	_apply_texture(texture)
	_on_room_loaded(room, "")
	view_changed.emit()
	if view_id == "subconscious":
		var room_id := String(room.get("room_id"))
		var flag := "subconscious_entered/" + room_id
		if not DataManager.has_flag(flag):
			DataManager.set_flag(flag, true)
			EventBus.dialogue_requested.emit("2_3_enter_" + room_id.trim_prefix("room_"))
	return true


func get_view_name() -> String:
	return String(get_views().get(current_view, {}).get("name", ""))


func _unregister_hotspot(instance_id: int) -> void:
	_hotspots.erase(instance_id)
	if is_instance_valid(_hovered) and _hovered.get_instance_id() == instance_id:
		_clear_hover()


func get_hotspot_items() -> Array[Interactable]:
	var items: Array[Interactable] = []
	for instance_id: int in _hotspots.keys():
		var item := instance_from_id(instance_id) as Interactable
		if item == null or item.is_queued_for_deletion():
			_hotspots.erase(instance_id)
		else:
			items.append(item)
	return items


func pick_hotspot(world_position: Vector2) -> Interactable:
	var best: Interactable = null
	var best_priority: float = -INF
	for item: Interactable in get_hotspot_items():
		if item.is_queued_for_deletion() or not item.is_visible_in_tree():
			continue
		var rect: Rect2 = _hotspots[item.get_instance_id()]
		if not rect.has_point(world_position):
			continue
		var priority: float = 1000000.0 / maxf(rect.get_area(), 1.0)
		if item is ClueItem:
			priority += 100.0
			if not DataManager.has_clue((item as ClueItem).clue_id):
				priority += 1000.0
		if priority > best_priority:
			best_priority = priority
			best = item
	return best


func _unhandled_input(event: InputEvent) -> void:
	if not FlowManager.is_free_investigation_active():
		_clear_hover()
		return
	if not (event is InputEventMouseMotion or event is InputEventMouseButton):
		return
	var item: Interactable = pick_hotspot(get_canvas_transform().affine_inverse() * event.position)
	if event is InputEventMouseMotion:
		if item != _hovered:
			_clear_hover()
			_hovered = item
			if item != null:
				item.set_highlight_active(true)
				Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	elif (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and item != null:
		get_viewport().set_input_as_handled()
		_clear_hover()
		InteractionFeedback.show_world_interaction(item)
		var view_id: String = String(item.get_meta("static_art_view", ""))
		if not view_id.is_empty():
			if not FlowManager.is_current_room_exit_blocked():
				set_view(view_id)
		else:
			item.interact(SceneManager.current_player as Player)


func _clear_hover() -> void:
	if is_instance_valid(_hovered):
		if _hovered.has_method("_refresh_highlight"):
			_hovered.call("_refresh_highlight")
		else:
			_hovered.set_highlight_active(false)
	_hovered = null
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _exit_tree() -> void:
	_clear_hover()
