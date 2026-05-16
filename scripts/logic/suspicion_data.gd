class_name SuspicionData
extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export var chapter_id: String = ""
@export var category_path: PackedStringArray = PackedStringArray()
@export var tags: PackedStringArray = PackedStringArray()

@export var required_clue_ids: PackedStringArray = PackedStringArray()

@export_enum("exact", "contains")
var match_mode: String = "exact"

@export var conclusion_clue_id: String = ""
