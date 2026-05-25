extends Node2D

@export var room_id: String = "demo_end"
@export var default_spawn_point: String = "InitialSpawn"
@export var body_cg_duration: float = 3.0
@export_file("*.png") var body_cg_path: String = "res://assets/cg/demo_body_cg.png"

@onready var body_cg: TextureRect = $EndLayer/BodyCg
@onready var placeholder_label: Label = $EndLayer/PlaceholderLabel
@onready var final_black: ColorRect = $EndLayer/FinalBlack
@onready var title_label: Label = $EndLayer/TitleLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_body_cg()
	call_deferred("_start_sequence")


func _start_sequence() -> void:
	if AudioManager != null:
		AudioManager.stop_bgm()
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("clock_bell")

	var has_body_cg := body_cg.texture != null
	body_cg.visible = has_body_cg
	placeholder_label.visible = not has_body_cg
	final_black.visible = false
	title_label.visible = false

	await get_tree().create_timer(max(0.1, body_cg_duration), true).timeout

	body_cg.visible = false
	placeholder_label.visible = false
	final_black.visible = true
	title_label.visible = true


func _load_body_cg() -> void:
	var file := FileAccess.open(body_cg_path, FileAccess.READ)
	if file == null:
		push_warning("Demo body CG file not found: %s" % body_cg_path)
		return

	var image := Image.new()
	var error := image.load_png_from_buffer(file.get_buffer(file.get_length()))
	if error != OK:
		push_warning("Failed to load demo body CG %s: %s" % [body_cg_path, error])
		return

	body_cg.texture = ImageTexture.create_from_image(image)
