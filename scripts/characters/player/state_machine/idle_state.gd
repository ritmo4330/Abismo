extends NodeState

@export var player : Player
@export var animated_sprite_2d : AnimatedSprite2D


func _on_process(_delta : float) -> void:
	pass


func update_idle_animation():
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("idle_back")
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("idle_front")
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("idle_left")
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("idle_right")
	else:
		animated_sprite_2d.play("idle_front")


func _on_physics_process(_delta : float) -> void:
	update_idle_animation()


func _on_next_transitions() -> void:
	GameInputEvents.movement_input()
	# 这里需要调用movement_input()来更新direction变量的值，以便在is_movement_input()中正确判断是否有移动输入

	if GameInputEvents.is_movement_input():
		transition.emit("walk")


func _on_enter() -> void:
	update_idle_animation()


func _on_exit() -> void:
	animated_sprite_2d.stop()
	pass
