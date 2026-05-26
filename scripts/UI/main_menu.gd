extends Control

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton

const GAME_ROOT_SCENE_PATH: String = "res://scenes/game_root.tscn"

func _ready():
	GameManager.enter_main_menu()
	if AudioManager != null and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm("cassandra_memory", 1.5)

	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	GameManager.enter_gameplay()
	GameManager.set_next_boot_mode(GameManager.BOOT_MODE_DEMO)
	get_tree().change_scene_to_file(GAME_ROOT_SCENE_PATH)

func _on_quit_button_pressed():
	get_tree().quit()
