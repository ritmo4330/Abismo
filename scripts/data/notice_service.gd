class_name NoticeService
extends RefCounted

const ContentRegistry = preload("res://scripts/data/content_registry.gd")

signal notice_requested(message: String, notice_type: String)

var _registry: ContentRegistry


func setup(registry: ContentRegistry) -> void:
	_registry = registry


func on_clue_discovered(clue_id: String) -> void:
	notice_requested.emit("发现新线索：%s" % _get_clue_title(clue_id), "clue")


func on_suspicion_discovered(suspicion_id: String) -> void:
	notice_requested.emit("发现新疑点：%s" % _get_suspicion_title(suspicion_id), "suspicion")


func on_deep_clues_unlocked(parent_clue_id: String, child_clue_ids: PackedStringArray) -> void:
	var titles: Array[String] = []
	for child_id: String in child_clue_ids:
		titles.append(_get_clue_title(child_id))

	if titles.is_empty():
		titles.append(_get_clue_title(parent_clue_id))

	notice_requested.emit("发现深入线索%d条：%s" % [titles.size(), "、".join(titles)], "deep_clue")


func _get_clue_title(clue_id: String) -> String:
	var clue_def: ClueData = _registry.get_clue_def(clue_id)
	if clue_def == null or clue_def.title.is_empty():
		return clue_id
	return clue_def.title


func _get_suspicion_title(suspicion_id: String) -> String:
	var suspicion_def: SuspicionData = _registry.get_suspicion_def(suspicion_id)
	if suspicion_def == null or suspicion_def.title.is_empty():
		return suspicion_id
	return suspicion_def.title
