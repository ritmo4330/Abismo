class_name ClueData
extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export var chapter_id: String = ""
@export var room_id: String = ""

@export var category_path: Array[String] = []
@export var tags: Array[String] = []

@export_enum("scene_evidence", "testimony", "conclusion", "lore")
var clue_type: String = "scene_evidence"

@export var is_conclusion: bool = false
@export var highlight_visible: bool = true

@export var parent_clue_id: String = ""
@export var child_clue_ids: Array[String] = []
