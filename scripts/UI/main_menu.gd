extends Control

@onready var start_button = $StartButton
@onready var options_button = $OptionsButton
@onready var quit_button = $QuitButton

const TEST_SCENE_PATH: String = "res://scenes/test/test_scene_player.tscn"

func _ready():
	GameManager.enter_main_menu()

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
	# 加载一个用来包装低分辨率游戏的通用容器场景（我们将其命名为 game_root）
	# （注意：如果你的主场景是别的名字，这里需要改成对应的路径）
	get_tree().change_scene_to_file("res://scenes/game_root.tscn")

func _on_options_button_pressed():
	GameManager.enter_gameplay()
	get_tree().change_scene_to_file(TEST_SCENE_PATH)

func _on_quit_button_pressed():
	# 退出游戏
	get_tree().quit()
