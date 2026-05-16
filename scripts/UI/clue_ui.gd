extends CanvasLayer

const PANEL_SIZE: Vector2 = Vector2(1280.0, 800.0)
const PANEL_ID: String = "clue_panel"
const PANEL_PAUSE_TOKEN: String = "clue_panel"
const MODE_ARCHIVE: String = "archive"
const MODE_INTERACTION: String = "interaction"
const MODE_SELECTION: String = "selection"
const ARCHIVE_SORT_DEFAULT: int = 0
const ARCHIVE_SORT_DISCOVER: int = 1

const CHAPTER_ORDER: Dictionary = {
	"1": 0,
	"2": 1,
	"3": 2,
}

const CH2_ROOM_ORDER: Dictionary = {
	"mu": 0,
	"zhou": 1,
	"lin": 2,
	"wu": 3,
	"zhong": 4,
	"mei": 5,
	"storeroom": 6,
	"dining": 7,
	"study": 8,
	"hall": 9,
	"kitchen": 10,
	"pantry": 11,
}

const CH3_ROOM_ORDER: Dictionary = {
	"mu": 0,
	"zhou": 1,
	"lin": 2,
	"wu": 3,
	"zhong": 4,
	"mei": 5,
}

const CH4_ROOM_ORDER: Dictionary = {
	"mei": 0,
	"abismo": 1,
	"zhou": 2,
	"zhongyue": 3,
	"study_darkroom": 4,
	"flower_sea": 5,
}

const BODY_SEARCH_PERSON_ORDER: Dictionary = {
	"mu": 0,
	"zhou": 1,
	"lin": 2,
	"wu": 3,
	"zhong": 4,
}

@onready var panel_root: Control = $PanelRoot
@onready var panel_frame: PanelContainer = $PanelRoot/PanelFrame
@onready var mode_label: Label = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/HeaderBar/ModeLabel
@onready var close_button: Button = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/HeaderBar/CloseButton
@onready var search_line_edit: LineEdit = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/LeftPane/LeftVBox/SearchRow/SearchLineEdit
@onready var sort_option_button: OptionButton = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/LeftPane/LeftVBox/SearchRow/SortOptionButton
@onready var catalog_tree: Tree = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/LeftPane/LeftVBox/CatalogTree
@onready var detail_title: Label = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/DetailTitle
@onready var detail_body: RichTextLabel = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/DetailBody
@onready var select_clue_button: Button = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/SelectClueButton

var _is_open: bool = false
var _mode: String = MODE_ARCHIVE
var _interaction_payload: Dictionary = {}
var _selection_context: Dictionary = {}
var _suppress_tree_selected_callback: bool = false
var _archive_refresh_queued: bool = false
var _interaction_refresh_queued: bool = false
var _archive_selected_clue_id: String = ""
var _archive_sort_mode: int = ARCHIVE_SORT_DEFAULT


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	hide()

	catalog_tree.hide_root = true
	catalog_tree.columns = 1
	sort_option_button.clear()
	sort_option_button.add_item("默认")
	sort_option_button.add_item("按发现时间")
	sort_option_button.select(ARCHIVE_SORT_DEFAULT)
	select_clue_button.hide()

	if not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)
	if not search_line_edit.text_changed.is_connected(_on_search_text_changed):
		search_line_edit.text_changed.connect(_on_search_text_changed)
	if not sort_option_button.item_selected.is_connected(_on_sort_option_button_item_selected):
		sort_option_button.item_selected.connect(_on_sort_option_button_item_selected)
	if not catalog_tree.item_selected.is_connected(_on_catalog_tree_item_selected):
		catalog_tree.item_selected.connect(_on_catalog_tree_item_selected)
	if not select_clue_button.pressed.is_connected(_on_select_clue_button_pressed):
		select_clue_button.pressed.connect(_on_select_clue_button_pressed)

	if get_viewport() != null and not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	if DataManager != null and not DataManager.clue_updated.is_connected(_on_clue_updated):
		DataManager.clue_updated.connect(_on_clue_updated)
	if EventBus != null and not EventBus.clue_interaction_details_requested.is_connected(_on_clue_interaction_details_requested):
		EventBus.clue_interaction_details_requested.connect(_on_clue_interaction_details_requested)
	if EventBus != null and not EventBus.clue_selection_requested.is_connected(_on_clue_selection_requested):
		EventBus.clue_selection_requested.connect(_on_clue_selection_requested)
	if EventBus != null and not EventBus.ui_panel_focus_requested.is_connected(_on_ui_panel_focus_requested):
		EventBus.ui_panel_focus_requested.connect(_on_ui_panel_focus_requested)

	_on_viewport_size_changed()
	_render_empty_state("暂无可显示的线索。")


func _input(event: InputEvent) -> void:
	if _is_toggle_input(event):
		if _is_open:
			_close_panel()
		else:
			_open_archive_panel()
		get_viewport().set_input_as_handled()
		return

	if not _is_open:
		return

	if _is_close_input(event):
		_close_panel()
		get_viewport().set_input_as_handled()


func _on_close_button_pressed() -> void:
	_close_panel()


func _on_search_text_changed(_new_text: String) -> void:
	if not _is_archive_like_mode():
		return
	_refresh_archive_tree()


func _on_sort_option_button_item_selected(index: int) -> void:
	_archive_sort_mode = index
	if not _is_archive_like_mode():
		return
	_refresh_archive_tree()


func _on_catalog_tree_item_selected() -> void:
	if _suppress_tree_selected_callback:
		return

	var item: TreeItem = catalog_tree.get_selected()
	if item == null:
		return

	var clue_id_variant: Variant = item.get_metadata(0)
	if not (clue_id_variant is String):
		return

	var clue_id: String = String(clue_id_variant)
	if clue_id.is_empty():
		return
	if _is_archive_like_mode():
		_archive_selected_clue_id = clue_id

	_show_clue_detail(clue_id, true)


func _on_clue_updated(_clue_id: String) -> void:
	if not _is_open:
		return

	if _is_archive_like_mode():
		_queue_archive_refresh()
		return

	_queue_interaction_refresh()


func _queue_archive_refresh() -> void:
	if _archive_refresh_queued:
		return
	_archive_refresh_queued = true
	call_deferred("_deferred_refresh_archive_tree")


func _deferred_refresh_archive_tree() -> void:
	_archive_refresh_queued = false
	if not _is_open:
		return
	if _mode != MODE_ARCHIVE:
		if _mode != MODE_SELECTION:
			return
	_refresh_archive_tree()


func _on_select_clue_button_pressed() -> void:
	if _mode != MODE_SELECTION:
		return
	if _archive_selected_clue_id.is_empty():
		return
	EventBus.clue_selected_for_reasoning.emit(_selection_context.duplicate(true), _archive_selected_clue_id)
	_close_panel()


func _queue_interaction_refresh() -> void:
	if _interaction_refresh_queued:
		return
	_interaction_refresh_queued = true
	call_deferred("_deferred_refresh_interaction_tree")


func _deferred_refresh_interaction_tree() -> void:
	_interaction_refresh_queued = false
	if not _is_open:
		return
	if _mode != MODE_INTERACTION:
		return
	_refresh_interaction_tree()


func _on_clue_interaction_details_requested(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	_open_interaction_panel(payload)


func _on_clue_selection_requested(context: Dictionary) -> void:
	_open_selection_panel(context)


func _on_ui_panel_focus_requested(panel_id: String) -> void:
	if panel_id == PANEL_ID:
		return
	_close_panel()


func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var scale_ratio: float = min(viewport_size.x / PANEL_SIZE.x, viewport_size.y / PANEL_SIZE.y)
	scale_ratio = min(scale_ratio, 1.0)

	panel_frame.size = PANEL_SIZE
	panel_frame.scale = Vector2(scale_ratio, scale_ratio)

	var scaled_size: Vector2 = PANEL_SIZE * scale_ratio
	panel_frame.position = (viewport_size - scaled_size) * 0.5


func _open_archive_panel() -> void:
	if not _can_open_panel():
		return

	_mode = MODE_ARCHIVE
	_interaction_payload = {}
	_selection_context = {}
	_open_panel()
	_update_mode_widgets()
	_refresh_archive_tree()


func _open_interaction_panel(payload: Dictionary) -> void:
	if not _can_open_panel():
		return

	_mode = MODE_INTERACTION
	_interaction_payload = payload.duplicate(true)
	_selection_context = {}
	_open_panel()
	_update_mode_widgets()
	_refresh_interaction_tree()


func _open_selection_panel(context: Dictionary) -> void:
	if not _can_open_panel():
		return

	_mode = MODE_SELECTION
	_interaction_payload = {}
	_selection_context = context.duplicate(true)
	_open_panel()
	_update_mode_widgets()
	_refresh_archive_tree()


func _open_panel() -> void:
	if not _is_open:
		EventBus.ui_panel_focus_requested.emit(PANEL_ID)
		_is_open = true
		show()
		if GameManager != null and GameManager.has_method("request_pause"):
			GameManager.request_pause(PANEL_PAUSE_TOKEN)


func _close_panel() -> void:
	if not _is_open:
		return

	_is_open = false
	hide()
	if GameManager != null and GameManager.has_method("release_pause"):
		GameManager.release_pause(PANEL_PAUSE_TOKEN)


func _can_open_panel() -> bool:
	if SceneManager != null and SceneManager.is_transitioning:
		return false
	if GameManager == null:
		return true
	if int(GameManager.current_state) == int(GameManager.GameState.DIALOGUE):
		return false
	return true


func _update_mode_widgets() -> void:
	if _mode == MODE_ARCHIVE:
		mode_label.text = "模式：线索手册"
		search_line_edit.editable = true
		search_line_edit.placeholder_text = "搜索线索标题、内容、标签"
		select_clue_button.hide()
		return

	if _mode == MODE_SELECTION:
		mode_label.text = "模式：选择线索"
		search_line_edit.editable = true
		search_line_edit.placeholder_text = "搜索线索标题、内容、标签"
		select_clue_button.show()
		select_clue_button.disabled = true
		return

	mode_label.text = "模式：交互详情"
	search_line_edit.editable = false
	search_line_edit.text = ""
	search_line_edit.placeholder_text = "交互详情模式下禁用搜索"
	select_clue_button.hide()


func _refresh_archive_tree() -> void:
	catalog_tree.clear()
	var root: TreeItem = catalog_tree.create_item()
	if root == null:
		_render_empty_state("线索目录刷新失败，请重试。")
		return

	var category_items: Dictionary[String, TreeItem] = {}
	var first_clue_item: TreeItem = null
	var clue_items_by_id: Dictionary[String, TreeItem] = {}
	var filter_text: String = search_line_edit.text.strip_edges().to_lower()
	var discovered_ids: Array[String] = _get_archive_sorted_discovered_ids()
	var discovered_set: Dictionary[String, bool] = {}
	for clue_id: String in discovered_ids:
		discovered_set[clue_id] = true

	var top_level_ids: Array[String] = []
	var child_ids_by_parent: Dictionary = {}
	for clue_id: String in discovered_ids:
		var clue_def: ClueData = _get_clue_def(clue_id)
		if clue_def == null:
			continue

		var parent_clue_id: String = clue_def.parent_clue_id
		if not parent_clue_id.is_empty() and discovered_set.has(parent_clue_id):
			if not child_ids_by_parent.has(parent_clue_id):
				child_ids_by_parent[parent_clue_id] = []
			var child_list: Array[String] = _variant_to_string_array(child_ids_by_parent[parent_clue_id])
			child_list.append(clue_id)
			child_ids_by_parent[parent_clue_id] = child_list
			continue

		top_level_ids.append(clue_id)

	for parent_id: String in child_ids_by_parent.keys():
		var child_ids_sorted: Array[String] = _sort_clue_ids_for_archive(_variant_to_string_array(child_ids_by_parent[parent_id]))
		child_ids_by_parent[parent_id] = child_ids_sorted

	for clue_id: String in top_level_ids:
		var clue_def: ClueData = _get_clue_def(clue_id)
		if clue_def == null:
			continue

		var parent_match: bool = _is_clue_matching_filter(clue_id, clue_def, filter_text)
		var visible_child_ids: Array[String] = []
		var child_ids: Array[String] = _variant_to_string_array(child_ids_by_parent.get(clue_id, []))
		for child_id: String in child_ids:
			var child_def: ClueData = _get_clue_def(child_id)
			if child_def == null:
				continue
			if _is_clue_matching_filter(child_id, child_def, filter_text):
				visible_child_ids.append(child_id)

		if not parent_match and visible_child_ids.is_empty():
			continue

		var parent_item: TreeItem = root
		var path_key: String = ""
		var category_path: PackedStringArray = _get_archive_category_path(clue_def)
		for segment_raw: String in category_path:
			var segment: String = segment_raw.strip_edges()
			if segment.is_empty():
				continue

			if path_key.is_empty():
				path_key = segment
			else:
				path_key = "%s/%s" % [path_key, segment]

			if not category_items.has(path_key):
				var category_item: TreeItem = catalog_tree.create_item(parent_item)
				if category_item == null:
					continue
				category_item.set_text(0, segment)
				category_item.set_selectable(0, false)
				category_items[path_key] = category_item

			var next_parent: TreeItem = category_items.get(path_key, null)
			if next_parent == null:
				next_parent = root
			parent_item = next_parent

		var clue_item: TreeItem = catalog_tree.create_item(parent_item)
		if clue_item == null:
			continue
		clue_item.set_metadata(0, clue_id)
		clue_item.set_text(0, _build_clue_tree_title(clue_id, clue_def))
		clue_items_by_id[clue_id] = clue_item
		if first_clue_item == null:
			first_clue_item = clue_item

		for child_id: String in visible_child_ids:
			var child_def: ClueData = _get_clue_def(child_id)
			if child_def == null:
				continue
			var child_item: TreeItem = catalog_tree.create_item(clue_item)
			if child_item == null:
				continue
			child_item.set_metadata(0, child_id)
			child_item.set_text(0, _build_clue_tree_title(child_id, child_def))
			clue_items_by_id[child_id] = child_item
			if first_clue_item == null:
				first_clue_item = child_item

	if first_clue_item == null:
		_render_empty_state("未找到符合条件的线索。")
		return

	var selected_item: TreeItem = null
	if not _archive_selected_clue_id.is_empty() and clue_items_by_id.has(_archive_selected_clue_id):
		selected_item = clue_items_by_id[_archive_selected_clue_id]
	else:
		selected_item = first_clue_item

	if selected_item == null:
		_render_empty_state("未找到符合条件的线索。")
		return

	var selected_clue_id_variant: Variant = selected_item.get_metadata(0)
	if selected_clue_id_variant is String:
		_archive_selected_clue_id = String(selected_clue_id_variant)

	_suppress_tree_selected_callback = true
	catalog_tree.set_selected(selected_item, 0)
	_suppress_tree_selected_callback = false
	_show_clue_detail(_archive_selected_clue_id, false)


func _refresh_interaction_tree() -> void:
	catalog_tree.clear()
	var root: TreeItem = catalog_tree.create_item()
	var first_clue_item: TreeItem = null

	var display_type: String = String(_interaction_payload.get("display_type", "single"))
	if display_type == "hierarchical":
		var parent_clue_id: String = String(_interaction_payload.get("parent_clue_id", ""))
		if not parent_clue_id.is_empty():
			var parent_item: TreeItem = catalog_tree.create_item(root)
			parent_item.set_metadata(0, parent_clue_id)
			parent_item.set_text(0, _build_clue_tree_title(parent_clue_id, _get_clue_def(parent_clue_id)))
			first_clue_item = parent_item

			var child_ids_variant: Variant = _interaction_payload.get("child_clue_ids", [])
			if child_ids_variant is Array:
				var child_ids: Array = child_ids_variant
				for child_id_variant: Variant in child_ids:
					var child_id: String = String(child_id_variant)
					if child_id.is_empty():
						continue
					var child_item: TreeItem = catalog_tree.create_item(parent_item)
					child_item.set_metadata(0, child_id)
					child_item.set_text(0, _build_clue_tree_title(child_id, _get_clue_def(child_id)))

		if first_clue_item == null:
			var fallback_ids: Array[String] = _extract_payload_clue_ids(_interaction_payload)
			for fallback_id: String in fallback_ids:
				if fallback_id.is_empty():
					continue
				var fallback_item: TreeItem = catalog_tree.create_item(root)
				fallback_item.set_metadata(0, fallback_id)
				fallback_item.set_text(0, _build_clue_tree_title(fallback_id, _get_clue_def(fallback_id)))
				if first_clue_item == null:
					first_clue_item = fallback_item
	else:
		var clue_ids: Array[String] = _extract_payload_clue_ids(_interaction_payload)
		for clue_id: String in clue_ids:
			if clue_id.is_empty():
				continue
			var clue_item: TreeItem = catalog_tree.create_item(root)
			clue_item.set_metadata(0, clue_id)
			clue_item.set_text(0, _build_clue_tree_title(clue_id, _get_clue_def(clue_id)))
			if first_clue_item == null:
				first_clue_item = clue_item

	if first_clue_item == null:
		_render_empty_state("当前交互没有可展示的线索。")
		return

	_suppress_tree_selected_callback = true
	catalog_tree.set_selected(first_clue_item, 0)
	_suppress_tree_selected_callback = false
	_show_clue_detail(String(first_clue_item.get_metadata(0)), false)


func _extract_payload_clue_ids(payload: Dictionary) -> Array[String]:
	var clue_ids: Array[String] = []
	var clue_ids_variant: Variant = payload.get("clue_ids", [])
	if clue_ids_variant is Array:
		var raw_ids: Array = clue_ids_variant
		for raw_id: Variant in raw_ids:
			var clue_id: String = String(raw_id)
			if clue_id.is_empty():
				continue
			clue_ids.append(clue_id)

	if clue_ids.is_empty():
		var fallback_parent: String = String(payload.get("parent_clue_id", ""))
		if not fallback_parent.is_empty():
			clue_ids.append(fallback_parent)

	return clue_ids


func _show_clue_detail(clue_id: String, mark_read: bool = false) -> void:
	var clue_def: ClueData = _get_clue_def(clue_id)
	if clue_def == null:
		detail_title.text = clue_id
		detail_body.text = "未找到该线索的数据定义。"
		return

	var title: String = clue_def.title
	if title.is_empty():
		title = clue_id
	detail_title.text = title

	var section_lines: PackedStringArray = PackedStringArray()
	if not clue_def.chapter_id.is_empty() or not clue_def.room_id.is_empty():
		section_lines.append("章节：%s    房间：%s" % [clue_def.chapter_id, clue_def.room_id])
	if not clue_def.tags.is_empty():
		section_lines.append("标签：%s" % ", ".join(clue_def.tags))
	if clue_def.is_conclusion:
		section_lines.append("类型：结论线索")

	var body: String = clue_def.description
	if body.is_empty():
		body = "（暂无线索描述）"

	if section_lines.is_empty():
		detail_body.text = body
	else:
		detail_body.text = "%s\n\n%s" % ["\n".join(section_lines), body]

	if _mode == MODE_SELECTION:
		select_clue_button.disabled = false

	if _is_archive_like_mode() and mark_read:
		DataManager.mark_clue_read(clue_id)


func _render_empty_state(message: String) -> void:
	detail_title.text = "线索详情"
	detail_body.text = message
	select_clue_button.disabled = true


func _build_clue_tree_title(clue_id: String, clue_def: ClueData) -> String:
	var title: String = clue_id
	if clue_def != null and not clue_def.title.is_empty():
		title = clue_def.title

	var state: Dictionary = DataManager.get_clue_state(clue_id)
	if bool(state.get("read", false)):
		return title
	return "● %s" % title


func _get_normalized_category_path(clue_def: ClueData) -> PackedStringArray:
	if clue_def == null:
		return PackedStringArray(["未分类"])
	if clue_def.category_path.is_empty():
		return PackedStringArray(["未分类"])
	return clue_def.category_path


func _get_archive_category_path(clue_def: ClueData) -> PackedStringArray:
	var path: PackedStringArray = _get_normalized_category_path(clue_def).duplicate()
	if not path.is_empty() and path[path.size() - 1] == "深入调查":
		path.remove_at(path.size() - 1)
	if path.is_empty():
		return PackedStringArray(["未分类"])
	return path


func _get_archive_sorted_discovered_ids() -> Array[String]:
	var ids: Array[String] = []
	for clue_id: String in DataManager.get_discovered_clues():
		ids.append(clue_id)
	return _sort_clue_ids_for_archive(ids)


func _sort_clue_ids_for_archive(clue_ids: Array[String]) -> Array[String]:
	var sorted_ids: Array[String] = clue_ids.duplicate()
	if _archive_sort_mode == ARCHIVE_SORT_DISCOVER:
		sorted_ids.sort_custom(_sort_clue_ids_by_discover_order)
		return sorted_ids

	sorted_ids.sort_custom(_sort_clue_ids_by_default_order)
	return sorted_ids


func _sort_clue_ids_by_discover_order(a: String, b: String) -> bool:
	return _get_discover_order(a) < _get_discover_order(b)


func _sort_clue_ids_by_default_order(a: String, b: String) -> bool:
	var key_a: Array = _build_default_order_key(a)
	var key_b: Array = _build_default_order_key(b)
	return _is_order_key_less(key_a, key_b)


func _variant_to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not (value is Array):
		return result

	var source: Array = value
	for element: Variant in source:
		result.append(String(element))
	return result


func _is_order_key_less(left: Array, right: Array) -> bool:
	var compare_count: int = min(left.size(), right.size())
	for i: int in compare_count:
		if left[i] == right[i]:
			continue
		return left[i] < right[i]
	return left.size() < right.size()


func _build_default_order_key(clue_id: String) -> Array:
	var clue_def: ClueData = _get_clue_def(clue_id)
	if clue_def == null:
		return [999, 999, 999, 999, clue_id]

	var chapter_id: String = clue_def.chapter_id
	var chapter_rank: int = int(CHAPTER_ORDER.get(chapter_id, 999))
	var room_id: String = clue_def.room_id
	var room_rank: int = _get_room_rank(chapter_id, room_id)

	if _is_body_search_parent_clue(clue_id):
		room_rank = 900 + int(BODY_SEARCH_PERSON_ORDER.get(room_id, 999))

	var primary_index: int = _extract_primary_index(clue_id)
	var secondary_index: int = _extract_secondary_index(clue_id)
	return [chapter_rank, room_rank, primary_index, secondary_index, clue_id]


func _get_room_rank(chapter_id: String, room_id: String) -> int:
	if chapter_id == "2":
		return int(CH2_ROOM_ORDER.get(room_id, 999))
	if chapter_id == "3":
		return int(CH3_ROOM_ORDER.get(room_id, 999))
	if chapter_id == "4":
		return int(CH4_ROOM_ORDER.get(room_id, 999))
	return 999


func _extract_primary_index(clue_id: String) -> int:
	var parts: PackedStringArray = clue_id.split("_", false)
	if parts.size() < 3:
		return 999
	return _safe_to_int(parts[2], 999)


func _extract_secondary_index(clue_id: String) -> int:
	var parts: PackedStringArray = clue_id.split("_", false)
	if parts.size() < 4:
		return -1
	return _safe_to_int(parts[3], 999)


func _safe_to_int(value: String, fallback: int) -> int:
	if value.is_valid_int():
		return int(value)
	return fallback


func _is_body_search_parent_clue(clue_id: String) -> bool:
	var clue_def: ClueData = _get_clue_def(clue_id)
	if clue_def == null:
		return false
	if not clue_def.parent_clue_id.is_empty():
		return false
	var parts: PackedStringArray = clue_id.split("_", false)
	if parts.size() < 3:
		return false
	return parts[2] == "0"


func _get_discover_order(clue_id: String) -> int:
	var state: Dictionary = DataManager.get_clue_state(clue_id)
	return int(state.get("discover_order", 999999))


func _is_clue_matching_filter(clue_id: String, clue_def: ClueData, filter_text: String) -> bool:
	if filter_text.is_empty():
		return true

	var title: String = clue_id.to_lower()
	var description: String = ""
	var tags_text: String = ""
	var category_text: String = ""

	if clue_def != null:
		title = clue_def.title.to_lower()
		description = clue_def.description.to_lower()
		tags_text = ",".join(clue_def.tags).to_lower()
		category_text = "/".join(clue_def.category_path).to_lower()

	return title.contains(filter_text) \
		or description.contains(filter_text) \
		or tags_text.contains(filter_text) \
		or category_text.contains(filter_text)


func _get_clue_def(clue_id: String) -> ClueData:
	if clue_id.is_empty():
		return null
	if DataManager == null:
		return null
	if not DataManager.clue_defs.has(clue_id):
		return null

	var clue_def_variant: Variant = DataManager.clue_defs.get(clue_id, null)
	if clue_def_variant is ClueData:
		return clue_def_variant as ClueData
	return null


func _is_archive_like_mode() -> bool:
	return _mode == MODE_ARCHIVE or _mode == MODE_SELECTION


func _is_toggle_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed:
		return false
	if key_event.echo:
		return false
	if key_event.keycode != KEY_C and key_event.physical_keycode != KEY_C:
		return false
	if key_event.alt_pressed or key_event.ctrl_pressed or key_event.meta_pressed:
		return false
	return true


func _is_close_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed:
		return false
	if key_event.echo:
		return false
	return key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE
