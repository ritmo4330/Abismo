extends SceneTree

var failures := 0
var speed: Node
var dialogue: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	speed = root.get_node("TextSpeedManager")
	dialogue = root.get_node("Dialogic")
	var game: Node = root.get_node("GameManager")
	game.enter_gameplay()
	var initial_scale := Engine.time_scale
	dialogue.current_timeline = DialogicTimeline.new()
	dialogue.current_state = DialogicGameHandler.States.ANIMATING
	var actor := Node2D.new()
	root.add_child(actor)
	var tween := actor.create_tween()
	tween.tween_property(actor, "position:x", 100.0, 2.0)
	var player := AnimationPlayer.new()
	actor.add_child(player)
	var library := AnimationLibrary.new()
	var animation := Animation.new()
	animation.length = 2.0
	library.add_animation("test", animation)
	player.add_animation_library("", library)
	player.play("test")
	var timer := create_timer(2.0)
	await real_wait(0.10)
	check(actor.position.x < 25, "Running animation initially plays at normal speed")
	hold_ctrl(true)
	check(is_equal_approx(Engine.time_scale, initial_scale * 8.0), "Ctrl accelerates the story clock immediately")
	await real_wait(0.35)
	check(not tween.is_running() and is_equal_approx(actor.position.x, 100), "An already-running tween reaches its final state faster")
	check(not player.is_playing(), "AnimationPlayer accelerates together with the tween")
	check(timer.time_left <= 0.0, "Awaited timers finish with the accelerated animation")
	dialogue.current_state = DialogicGameHandler.States.AWAITING_CHOICE
	check(is_equal_approx(Engine.time_scale, initial_scale), "Choices immediately restore normal animation speed")
	await real_wait(0.20)
	check(dialogue.current_state == DialogicGameHandler.States.AWAITING_CHOICE, "Holding Ctrl never selects or bypasses an option")
	dialogue.current_state = DialogicGameHandler.States.ANIMATING
	check(Engine.time_scale > initial_scale, "Animation acceleration resumes after leaving a choice")
	hold_ctrl(false)
	check(is_equal_approx(Engine.time_scale, initial_scale), "Releasing Ctrl restores normal time")
	hold_ctrl(true)
	dialogue.paused = true
	check(is_equal_approx(Engine.time_scale, initial_scale), "Opening dialogue history or pause restores normal time")
	dialogue.paused = false
	check(Engine.time_scale > initial_scale, "Closing history resumes held fast-forward")
	speed._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not speed._hold_acceleration and is_equal_approx(Engine.time_scale, initial_scale), "Losing focus clears Ctrl and restores speed")
	Engine.time_scale = 0.75
	hold_ctrl(true)
	hold_ctrl(false)
	check(is_equal_approx(Engine.time_scale, 0.75), "Existing non-default playback speed is preserved")
	Engine.time_scale = initial_scale
	hold_ctrl(true)
	dialogue.current_timeline = null
	speed._sync_animation_speed()
	check(is_equal_approx(Engine.time_scale, initial_scale), "Ending dialogue restores normal time without accelerating free investigation")
	var scene_manager: Node = root.get_node("SceneManager")
	var cinematic := Node2D.new()
	root.add_child(cinematic)
	scene_manager.current_room = cinematic
	speed._sync_animation_speed()
	check(Engine.time_scale > initial_scale, "Scripted cinematic scenes accelerate even between dialogue timelines")
	scene_manager.current_room = null
	cinematic.queue_free()
	speed._sync_animation_speed()
	check(is_equal_approx(Engine.time_scale, initial_scale), "Leaving a cinematic restores its previous clock")
	dialogue.current_timeline = DialogicTimeline.new()
	speed._sync_animation_speed()
	game.enter_main_menu()
	check(is_equal_approx(Engine.time_scale, initial_scale), "Returning to main menu cannot leave fast-forward active")
	hold_ctrl(false)
	dialogue.current_timeline = null
	actor.queue_free()
	print("Dialogue fast-forward failures=", failures)
	quit(0 if failures == 0 else 1)

func hold_ctrl(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_CTRL
	event.pressed = pressed
	speed._input(event)

func real_wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout

func check(ok: bool, description: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + description)
	if not ok:
		failures += 1
