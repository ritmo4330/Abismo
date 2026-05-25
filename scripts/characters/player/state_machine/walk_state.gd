extends NodeState

@export var player : Player
@export var animated_sprite_2d : AnimatedSprite2D
@export var speed : float = 200

const FOOTSTEP_CHANNEL_ID: String = "player_footsteps"
const FOOTSTEP_SFX_ID: String = "footsteps"

var direction : Vector2


func _ready() -> void:
	if GameManager != null and not GameManager.game_pause_changed.is_connected(_on_game_pause_changed):
		GameManager.game_pause_changed.connect(_on_game_pause_changed)


func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	direction = GameInputEvents.movement_input()
	
	if direction == Vector2.UP:
		animated_sprite_2d.play("walk_back")
	elif direction == Vector2.DOWN:
		animated_sprite_2d.play("walk_front")
	elif direction == Vector2.LEFT:
		animated_sprite_2d.play("walk_left")
	elif direction == Vector2.RIGHT:
		animated_sprite_2d.play("walk_right")
	
	if direction != Vector2.ZERO:
		player.player_direction = direction
		_play_footsteps()
	else:
		_stop_footsteps()
	
	player.velocity = direction * speed
	player.move_and_slide()


func _on_next_transitions() -> void:
	# GameInputEvents.movement_input() 
	# 这里不需要调用，因为在_on_physics_process中已经调用了，并且更新了direction变量的值

	if not GameInputEvents.is_movement_input():
		transition.emit("idle")


func _on_enter() -> void:
	_play_footsteps()


func _on_exit() -> void:
	animated_sprite_2d.stop()
	_stop_footsteps()


func _exit_tree() -> void:
	_stop_footsteps()


func _on_game_pause_changed(is_paused: bool) -> void:
	if is_paused:
		_stop_footsteps()


func _play_footsteps() -> void:
	if AudioManager == null:
		return
	if not AudioManager.has_method("play_loop_sfx"):
		return
	AudioManager.play_loop_sfx(FOOTSTEP_SFX_ID, FOOTSTEP_CHANNEL_ID)


func _stop_footsteps() -> void:
	if AudioManager == null:
		return
	if not AudioManager.has_method("stop_loop_sfx"):
		return
	AudioManager.stop_loop_sfx(FOOTSTEP_CHANNEL_ID)
