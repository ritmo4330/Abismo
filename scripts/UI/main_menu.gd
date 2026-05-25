extends Control

@onready var start_button = $StartButton
@onready var options_button = $OptionsButton
@onready var quit_button = $QuitButton

const GAME_ROOT_SCENE_PATH: String = "res://scenes/game_root.tscn"

func _ready():
	GameManager.enter_main_menu()
	if AudioManager != null and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm("cassandra_memory", 1.5)
	if options_button:
		options_button.text = "旧流程"

	# 绑定按钮按下的信号
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
		
	# 如果是 Web 平台，通常不需要退出按钮
	if OS.has_feature("web"):
		quit_button.hide()

func _on_start_button_pressed():
	GameManager.enter_gameplay()
	GameManager.set_next_boot_mode(GameManager.BOOT_MODE_DEMO)
	get_tree().change_scene_to_file(GAME_ROOT_SCENE_PATH)

func _on_options_button_pressed():
	GameManager.enter_gameplay()
	GameManager.set_next_boot_mode(GameManager.BOOT_MODE_CH1_LEGACY)
	get_tree().change_scene_to_file(GAME_ROOT_SCENE_PATH)

func _on_quit_button_pressed():
	# 退出游戏
	get_tree().quit()
