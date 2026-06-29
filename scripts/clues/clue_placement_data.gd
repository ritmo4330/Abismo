class_name CluePlacementData
extends Resource

@export var placement_id: String = ""
@export var clue_id: String = ""

@export var chapter_id: String = ""
@export var room_id: String = ""
@export var spawn_name: String = ""

@export var available_steps: PackedStringArray = PackedStringArray()
@export var required_flags: PackedStringArray = PackedStringArray()
@export var blocked_flags: PackedStringArray = PackedStringArray()

@export var hide_after_discovered: bool = false
@export var interact_id: String = ""
@export var source_id: String = ""
@export var prompt_offset: Vector2 = Vector2.ZERO

@export var scene_path: String = "res://scenes/objects/clue_item.tscn"
