extends Control

# 在这里配置你的第一关场景路径
const FIRST_LEVEL_PATH = "res://scenes/test/test_scene_player.tscn"

@onready var start_button = $MarginContainer/VBoxContainer/Buttons/StartButton
@onready var options_button = $MarginContainer/VBoxContainer/Buttons/OptionsButton
@onready var quit_button = $MarginContainer/VBoxContainer/Buttons/QuitButton

func _ready():

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
	# 加载一个用来包装低分辨率游戏的通用容器场景（我们将其命名为 game_root）
	# （注意：如果你的主场景是别的名字，这里需要改成对应的路径）
	get_tree().change_scene_to_file("res://scenes/game_root.tscn")

func _on_options_button_pressed():
	# 如果有设置界面，可以在这里显示
	print("打开设置界面")

func _on_quit_button_pressed():
	# 退出游戏
	get_tree().quit()
