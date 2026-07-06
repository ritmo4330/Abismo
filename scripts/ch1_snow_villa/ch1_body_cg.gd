extends Node2D

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowEntries = preload("res://scripts/flow/flow_entries.gd")

@export var room_id: String = "ch1_body_cg"
@export var default_spawn_point: String = "InitialSpawn"
@export var body_cg_start_seconds: float = 4.0
@export var body_cg_end_start_seconds: float = 7.8
@export var continue_delay_seconds: float = 1.5
@export_file("*.png") var body_cg_path: String = "res://assets/cg/ch1_body_cg.png"

@onready var body_cg: TextureRect = $EndLayer/BodyCg
@onready var placeholder_label: Label = $EndLayer/PlaceholderLabel
@onready var final_black: ColorRect = $EndLayer/FinalBlack
@onready var title_label: Label = $EndLayer/TitleLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_body_cg()
	call_deferred("_start_sequence")


func _start_sequence() -> void:
	_show_black_screen()

	if AudioManager != null:
		AudioManager.stop_bgm()
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("clock_bell")

	await get_tree().create_timer(max(0.0, body_cg_start_seconds), true).timeout
	_show_body_cg()

	var body_cg_visible_seconds: float = max(0.0, body_cg_end_start_seconds - body_cg_start_seconds)
	await get_tree().create_timer(body_cg_visible_seconds, true).timeout
	_show_body_cg_end()

	await get_tree().create_timer(max(0.0, continue_delay_seconds), true).timeout
	if FlowManager != null:
		FlowManager.start_flow(FlowChapters.CH1, FlowEntries.CH1_HALL_FROM_CRIME_SCENE)


func _show_black_screen() -> void:
	body_cg.visible = false
	placeholder_label.visible = false
	final_black.visible = true
	title_label.visible = false


func _show_body_cg() -> void:
	var has_body_cg := body_cg.texture != null
	body_cg.visible = has_body_cg
	placeholder_label.visible = not has_body_cg
	final_black.visible = false
	title_label.visible = false


func _show_body_cg_end() -> void:
	body_cg.visible = false
	placeholder_label.visible = false
	final_black.visible = true
	title_label.visible = false


func _load_body_cg() -> void:
	var texture: Texture2D = load(body_cg_path) as Texture2D
	if texture == null:
		push_warning("Chapter 1 body CG texture not found: %s" % body_cg_path)
		return

	body_cg.texture = texture
