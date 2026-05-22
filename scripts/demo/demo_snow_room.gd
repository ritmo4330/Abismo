extends "res://scripts/scenes/room.gd"

@onready var blizzard_flash: ColorRect = find_child("BlizzardFlash", true, false) as ColorRect


func _ready() -> void:
	super._ready()
	if blizzard_flash != null:
		blizzard_flash.visible = false
		blizzard_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE


func play_blizzard_flash() -> void:
	if blizzard_flash == null:
		return

	blizzard_flash.visible = true
	blizzard_flash.modulate = Color(1, 1, 1, 0.0)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(blizzard_flash, "modulate", Color(1, 1, 1, 0.55), 0.12)
	tween.tween_property(blizzard_flash, "modulate", Color(1, 1, 1, 0.0), 0.45)
	tween.tween_callback(func() -> void:
		if blizzard_flash != null:
			blizzard_flash.visible = false
	)
