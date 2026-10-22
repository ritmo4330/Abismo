extends "res://scripts/scenes/door.gd"

const RULES = preload("res://scripts/clues/dining_backdoor_rules.gd")
const PANEL = preload("res://scripts/UI/dining_backdoor_panel.gd")
var _panel: CanvasLayer

func interact(player: Player) -> void:
	if not FlowManager.is_free_investigation_active() or _should_block_room_exit(): return
	if RULES.can_enter():
		super.interact(player)
		return
	DataManager.set_flag("clue_investigated/1_dining_2", true)
	DataManager.discover_clue("1_dining_2", "scene", "dining_backdoor")
	if is_instance_valid(_panel): return
	_panel = PANEL.new()
	_panel.name = "DiningBackdoorPanel"
	add_child(_panel)
	_panel.opened.connect(_on_opened)
	_panel.show_lock()

func _on_opened() -> void:
	# Recheck after closing the modal; the four selected handprints alone never
	# change the world. Only the explicit simultaneous-confirm action does.
	if RULES.can_enter():
		_play_open_sfx()
		FlowManager.request_scene(RULES.SCENE, "SpawnFromDining")
