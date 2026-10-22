extends SceneTree

var failures := 0
const PROVIDED := {
	"cassandra_memory": "卡森德拉-回忆-1.wav",
	"role_exit": "9-角色离场.wav",
	"plain_happiness": "12-Plain Happiness.wav",
	"thinking_introspection_2": "17-思考内省-2.wav",
	"spooky_tension": "17-Spooky Tension.wav",
	"truth": "24-真相.wav",
	"what_is_truth": "What is Truth.wav",
	"fog_in_brain": "Fog in Brain.wav",
	"dust_rain": "Dust Rain.wav",
	"hero_journey": "Hero's Journey.wav",
}

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	var audio: Node = root.get_node("AudioManager")
	var flow: Node = root.get_node("FlowManager")
	root.get_node("GameManager").enter_gameplay()
	for id: String in PROVIDED:
		var path := "res://assets/audio/" + String(PROVIDED[id])
		check(audio.BGM_TRACKS.get(id, "") == path, id + " uses the supplied WAV, not a placeholder")
		var source: AudioStream = load(path)
		check(source is AudioStreamWAV and source.get_length() > 1.0, id + " imports as a nonempty audio stream")
		audio.play_bgm(id, 0.0)
		var player: AudioStreamPlayer = audio._active_bgm_player
		check(player.playing and player.stream != source, id + " plays a separate playback resource")
		var wav := player.stream as AudioStreamWAV
		check(wav.loop_mode == AudioStreamWAV.LOOP_FORWARD and wav.loop_begin == 0 and wav.loop_end == int(round(wav.get_length() * wav.mix_rate)), id + " loops the complete WAV")
		check((source as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, id + " leaves imported source untouched")
		await create_timer(0.08).timeout
		var before := player.get_playback_position()
		audio.play_bgm(id, 0.0)
		check(audio._active_bgm_player == player and player.get_playback_position() >= before, id + " does not restart when entering another room with the same music")
	# The complete source-marked section mapping, independent of current story fixtures.
	var cases := {
		"ch0_prologue": {"ch0_0_1_identity":"cassandra_memory", "ch0_0_2_prologue_story":"role_exit"},
		"ch1_snow_villa": {"ch1_1_study_wake":"plain_happiness", "ch1_1_puzzle":"thinking_introspection_2", "ch1_1_murder_request":"truth", "ch1_2_crime_scene":"truth", "ch1_3_intro_hall":"spooky_tension", "ch1_4_first_search":"what_is_truth", "ch1_5_initial_reasoning":"what_is_truth", "ch1_6_private_chat":"what_is_truth"},
		"ch2_deepening": {"ch1_7_second_search":"what_is_truth", "ch2_1_second_reasoning":"fog_in_brain", "ch2_2_second_private_chat":"fog_in_brain", "ch2_3_third_search":"fog_in_brain", "ch2_4_third_reasoning":"fog_in_brain", "ch2_5_third_private_chat":"fog_in_brain", "ch2_6_memory_fragments":"fog_in_brain"},
	}
	for chapter: String in cases:
		for step: String in cases[chapter]:
			flow.apply_flow_state(chapter, step)
			check(audio._current_bgm_id == cases[chapter][step], "Source BGM at " + step)
	for branch: Array in [["修正线", "dust_rain"], ["抵抗路线", "hero_journey"], ["超越路线", "role_exit"]]:
		audio.handle_dialogic_audio_signal("play_bgm:%s:0.04" % branch[1])
		check(audio._current_bgm_id == branch[1], "Source BGM at " + String(branch[0]))
		await create_timer(0.25).timeout
		var playing := 0
		for player: AudioStreamPlayer in audio._bgm_players:
			playing += int(player.playing)
		check(playing == 1, "Crossfade leaves only one BGM playing")
	# Exercise a real loop boundary without waiting for a full-length music track.
	var short_wav := AudioStreamWAV.new()
	short_wav.mix_rate = 8000
	short_wav.format = AudioStreamWAV.FORMAT_8_BITS
	var silence := PackedByteArray()
	silence.resize(400)
	silence.fill(128)
	short_wav.data = silence
	var loop_player := AudioStreamPlayer.new()
	root.add_child(loop_player)
	audio._configure_loop_stream(short_wav)
	loop_player.stream = short_wav
	loop_player.play()
	await create_timer(0.2).timeout
	check(loop_player.playing, "WAV remains playing after four loop boundaries")
	loop_player.queue_free()
	audio.stop_bgm(0.04)
	await create_timer(0.09).timeout
	for player: AudioStreamPlayer in audio._bgm_players:
		check(not player.playing, "Fade-out stops BGM players")
	print("Source BGM validation finished. failures=", failures)
	quit(0 if failures == 0 else 1)

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
