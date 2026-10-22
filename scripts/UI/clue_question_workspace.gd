extends RefCounted

const STYLE = preload("res://scripts/UI/casebook_style.gd")
var host: Node
var selector: OptionButton
var question_body: RichTextLabel
var enter_button: Button
var _ids: Array[String] = []
var _selected_question := ""
var _clue := ""

func build(owner_panel: Node) -> void:
	host = owner_panel
	var left: VBoxContainer = host.catalog_tree.get_parent()
	var right: VBoxContainer = host.detail_title.get_parent()
	var title := STYLE.label("线索", 30, true)
	left.add_child(title)
	left.move_child(title, 0)
	host.detail_title.add_theme_font_size_override("font_size", 30)
	host.detail_body.add_theme_font_size_override("normal_font_size", 28)
	# One manual, two explicit pages: this page is only the clue catalogue and
	# its detail. Do not repeat the complete reasoning workspace alongside it.
	selector = OptionButton.new()
	selector.name = "RelatedQuestionSelector"
	selector.item_selected.connect(_on_question_selected)
	right.add_child(selector)
	selector.hide()
	question_body = RichTextLabel.new()
	question_body.name = "InteractionQuestionBody"
	right.add_child(question_body)
	question_body.hide()
	enter_button = STYLE.button("查看本轮推理", _enter_reasoning, 27)
	enter_button.name = "EnterReasoning"
	enter_button.custom_minimum_size.y = 56
	STYLE.style_ribbon(enter_button)
	right.add_child(enter_button)

func refresh() -> void:
	if selector == null: return
	_ids.clear()
	selector.clear()
	var manual: Node = host.get_tree().current_scene.get_node_or_null("SuspicionPanel")
	for id: String in DataManager.get_discovered_suspicion_ids("discover"):
		if not preload("res://scripts/UI/casebook_cases.gd").visible_now(id) and (manual == null or id != String(manual._locked_suspicion_id)): continue
		if manual != null and manual._is_locked_and_unresolved() and id != String(manual._locked_suspicion_id): continue
		var definition: Resource = DataManager.get_suspicion_def(id)
		if definition == null: continue
		_ids.append(id)
		selector.add_item(("✓  " if DataManager.is_suspicion_resolved(id) else "") + String(definition.title))
		if id == _selected_question: selector.select(_ids.size() - 1)
	if not _ids.has(_selected_question):
		_selected_question = "" if _ids.is_empty() else _ids[0]
	if not _selected_question.is_empty(): selector.select(_ids.find(_selected_question))
	selector.disabled = _ids.is_empty()
	_update_question()

func show_clue(id: String) -> void:
	_clue = id
	refresh()

func _on_question_selected(index: int) -> void:
	if index < 0 or index >= _ids.size(): return
	_selected_question = _ids[index]
	_update_question()

func _update_question() -> void:
	var definition: Resource = DataManager.get_suspicion_def(_selected_question) if not _selected_question.is_empty() else null
	question_body.text = String(definition.description) if definition != null else "暂无已收录的问题。"
	var pending_story := not String(host._interaction_payload.get("followup_timeline", "")).is_empty()
	enter_button.visible = String(host._mode) != "selection"
	enter_button.disabled = definition == null or pending_story
	enter_button.text = "查看" + preload("res://scripts/UI/casebook_cases.gd").reasoning_title()

func _enter_reasoning() -> void:
	if enter_button.disabled or _selected_question.is_empty(): return
	var manual: Node = host.get_tree().current_scene.get_node_or_null("SuspicionPanel")
	if manual == null or not manual._can_open_panel(): return
	if manual._is_locked_and_unresolved() and _selected_question != String(manual._locked_suspicion_id): return
	host._close_panel()
	manual._selected_suspicion_id = _selected_question
	if manual._is_locked_session_active(): manual._open_locked_panel()
	else: manual._open_archive_panel()
	if manual._workspace != null and not _clue.is_empty() and DataManager.has_clue(_clue):
		manual._workspace.selected_clue = _clue
		manual._workspace.refresh()
