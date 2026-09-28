extends Control

@onready var start_button = $StartButton
@onready var load_button = $LoadButton
@onready var quit_button = $QuitButton

const GAME_ROOT_SCENE_PATH: String = "res://scenes/game_root.tscn"

func _ready():
	GameManager.enter_main_menu()
	if AudioManager != null and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm("cassandra_memory", 1.5)

	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if load_button:
		load_button.disabled = SaveManager == null or not SaveManager.has_save()
		load_button.pressed.connect(_on_load_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	if SaveManager != null:
		SaveManager.cancel_pending_load()
	GameManager.enter_gameplay()
	GameManager.set_next_boot_mode(GameManager.BOOT_MODE_CH0_PROLOGUE)
	get_tree().change_scene_to_file(GAME_ROOT_SCENE_PATH)


func _on_load_button_pressed() -> void:
	if SaveManager == null or not SaveManager.request_load_game():
		return
	GameManager.enter_gameplay()
	get_tree().change_scene_to_file(GAME_ROOT_SCENE_PATH)

func _on_quit_button_pressed():
	get_tree().quit()
