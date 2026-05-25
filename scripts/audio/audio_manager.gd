extends Node

const COMMAND_PLAY_BGM: String = "play_bgm"
const COMMAND_STOP_BGM: String = "stop_bgm"
const COMMAND_PLAY_SFX: String = "play_sfx"
const COMMAND_PLAY_LOOP_SFX: String = "play_loop_sfx"
const COMMAND_STOP_LOOP_SFX: String = "stop_loop_sfx"
const DEFAULT_BGM_FADE_SECONDS: float = 1.5
const DEFAULT_BGM_STOP_FADE_SECONDS: float = 1.5
const BGM_SILENCE_DB: float = -80.0

const BGM_TRACKS: Dictionary[String, String] = {
	"tuning": "res://assets/audio/陈达飞 - 调律.mp3",
	"winter_melody": "res://assets/audio/冬之旋律 - 陈达飞.mp3",
	"dark_fog_lie": "res://assets/audio/暗雾谎言 - 川井憲次.mp3",
	"cassandra_memory": "res://assets/audio/11-卡森德拉-回忆-1.mp3",
	"role_exit": "res://assets/audio/9-角色离场.wav",
	"plain_happiness": "res://assets/audio/12-Plain Happiness.wav",
	"thinking_introspection_2": "res://assets/audio/17-思考内省-2.wav",
	"truth": "res://assets/audio/24-真相.wav",
}

const SFX_TRACKS: Dictionary[String, String] = {
	"clock_bell": "",
	"door_knock": "res://assets/audio/door_knock_normal.mp3",
	"door_knock_normal": "res://assets/audio/door_knock_normal.mp3",
	"door_knock_quick": "res://assets/audio/door_knock_quick.mp3",
	"door_open": "res://assets/audio/door_open.mp3",
	"footsteps": "res://assets/audio/footsteps.mp3",
	"toast": "res://assets/audio/toast.wav",
}

var _bgm_players: Array[AudioStreamPlayer] = []
var _active_bgm_player: AudioStreamPlayer = null
var _sfx_player: AudioStreamPlayer = null
var _loop_sfx_players: Dictionary[String, AudioStreamPlayer] = {}
var _current_bgm_id: String = ""
var _is_user_paused: bool = false
var _bgm_fade_tween: Tween = null

@export var bgm_volume_db: float = -15.0:
	set(value):
		bgm_volume_db = value
		_apply_bgm_volume()
@export var sfx_volume_db: float = -10.0:
	set(value):
		sfx_volume_db = value
		_apply_sfx_volume()
@export_range(0.0, 1.0, 0.01) var paused_bgm_volume_multiplier: float = 1.0 / 3.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_bgm_player("BgmPlayerA")
	_create_bgm_player("BgmPlayerB")

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SfxPlayer"
	_sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_player)
	_apply_sfx_volume()

	if GameManager != null and not GameManager.game_state_changed.is_connected(_on_game_state_changed):
		GameManager.game_state_changed.connect(_on_game_state_changed)
		_is_user_paused = int(GameManager.current_state) == int(GameManager.GameState.PAUSED)
		_apply_bgm_volume()


func handle_dialogic_audio_signal(argument: String) -> void:
	var parts: PackedStringArray = argument.split(":", false)
	if parts.is_empty():
		return

	var command: String = parts[0]
	match command:
		COMMAND_PLAY_BGM:
			if parts.size() < 2:
				return
			var fade_seconds: float = DEFAULT_BGM_FADE_SECONDS
			if parts.size() >= 3:
				fade_seconds = parts[2].to_float()
			play_bgm(parts[1], fade_seconds)
		COMMAND_STOP_BGM:
			var fade_seconds: float = DEFAULT_BGM_STOP_FADE_SECONDS
			if parts.size() >= 2:
				fade_seconds = parts[1].to_float()
			stop_bgm(fade_seconds)
		COMMAND_PLAY_SFX:
			if parts.size() < 2:
				return
			play_sfx(parts[1])
		COMMAND_PLAY_LOOP_SFX:
			if parts.size() < 2:
				return
			var channel_id: String = ""
			if parts.size() >= 3:
				channel_id = parts[2]
			play_loop_sfx(parts[1], channel_id)
		COMMAND_STOP_LOOP_SFX:
			if parts.size() < 2:
				return
			stop_loop_sfx(parts[1])


func play_bgm(track_id: String, fade_seconds: float = DEFAULT_BGM_FADE_SECONDS) -> void:
	if track_id.is_empty():
		return
	if _current_bgm_id == track_id and _active_bgm_player != null and _active_bgm_player.playing:
		return

	var stream_path: String = String(BGM_TRACKS.get(track_id, ""))
	if stream_path.is_empty():
		_current_bgm_id = track_id
		return

	var stream: AudioStream = load(stream_path) as AudioStream
	if stream == null:
		return

	stream = stream.duplicate() as AudioStream
	_configure_bgm_stream_loop(stream)

	_kill_bgm_fade_tween()
	var previous_player: AudioStreamPlayer = _active_bgm_player
	var next_player: AudioStreamPlayer = _get_inactive_bgm_player()
	if next_player == null:
		return

	_current_bgm_id = track_id
	_active_bgm_player = next_player
	next_player.stop()
	next_player.stream = stream

	var fade_duration: float = maxf(0.0, fade_seconds)
	if fade_duration <= 0.0:
		_stop_inactive_bgm_players(next_player)
		_set_bgm_fade_factor(1.0, next_player)
		next_player.play()
		return

	_set_bgm_fade_factor(0.0, next_player)
	next_player.play()

	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_bgm_fade_tween.tween_method(_set_bgm_fade_factor.bind(next_player), 0.0, 1.0, fade_duration)

	if previous_player != null and previous_player != next_player and previous_player.playing:
		var previous_factor: float = _get_bgm_fade_factor(previous_player)
		_bgm_fade_tween.parallel().tween_method(
			_set_bgm_fade_factor.bind(previous_player),
			previous_factor,
			0.0,
			fade_duration
		)
		_bgm_fade_tween.tween_callback(_finish_previous_bgm_player.bind(previous_player, next_player))
	_bgm_fade_tween.tween_callback(_clear_bgm_fade_tween)


func stop_bgm(fade_seconds: float = DEFAULT_BGM_STOP_FADE_SECONDS) -> void:
	_current_bgm_id = ""
	_kill_bgm_fade_tween()

	var playing_players: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in _bgm_players:
		if player.playing or player.stream != null:
			playing_players.append(player)

	if playing_players.is_empty():
		return

	var fade_duration: float = maxf(0.0, fade_seconds)
	if fade_duration <= 0.0:
		for player: AudioStreamPlayer in playing_players:
			_finish_bgm_player(player)
		_active_bgm_player = null
		return

	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var is_first: bool = true
	for player: AudioStreamPlayer in playing_players:
		var start_factor: float = _get_bgm_fade_factor(player)
		if is_first:
			_bgm_fade_tween.tween_method(_set_bgm_fade_factor.bind(player), start_factor, 0.0, fade_duration)
			is_first = false
		else:
			_bgm_fade_tween.parallel().tween_method(_set_bgm_fade_factor.bind(player), start_factor, 0.0, fade_duration)
	_bgm_fade_tween.tween_callback(_finish_stopped_bgm_players.bind(playing_players))
	_bgm_fade_tween.tween_callback(_clear_bgm_fade_tween)


func play_sfx(sfx_id: String) -> void:
	if sfx_id.is_empty() or _sfx_player == null:
		return

	var stream_path: String = String(SFX_TRACKS.get(sfx_id, ""))
	if stream_path.is_empty():
		return

	var stream: AudioStream = load(stream_path) as AudioStream
	if stream == null:
		return

	_sfx_player.stream = stream
	_apply_sfx_volume()
	_sfx_player.play()


func play_loop_sfx(sfx_id: String, channel_id: String = "") -> void:
	if sfx_id.is_empty():
		return
	if channel_id.is_empty():
		channel_id = sfx_id

	var player: AudioStreamPlayer = _loop_sfx_players.get(channel_id, null)
	if player != null and player.playing and String(player.get_meta("sfx_id", "")) == sfx_id:
		return

	var stream_path: String = String(SFX_TRACKS.get(sfx_id, ""))
	if stream_path.is_empty():
		return

	var stream: AudioStream = load(stream_path) as AudioStream
	if stream == null:
		return

	stream = stream.duplicate() as AudioStream
	_configure_loop_stream(stream)

	if player == null:
		player = AudioStreamPlayer.new()
		player.name = "LoopSfxPlayer_%s" % channel_id
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_loop_sfx_players[channel_id] = player

	player.stop()
	player.stream = stream
	player.set_meta("sfx_id", sfx_id)
	_apply_sfx_player_volume(player)
	player.play()


func stop_loop_sfx(channel_id: String) -> void:
	if channel_id.is_empty():
		return
	var player: AudioStreamPlayer = _loop_sfx_players.get(channel_id, null)
	if player == null:
		return
	player.stop()
	player.stream = null
	player.remove_meta("sfx_id")


func _on_game_state_changed(_previous_state: int, new_state: int) -> void:
	_is_user_paused = new_state == int(GameManager.GameState.PAUSED)
	_apply_bgm_volume()


func _apply_bgm_volume() -> void:
	for player: AudioStreamPlayer in _bgm_players:
		_apply_bgm_player_volume(player)


func _apply_sfx_volume() -> void:
	if _sfx_player != null:
		_apply_sfx_player_volume(_sfx_player)
	for player: AudioStreamPlayer in _loop_sfx_players.values():
		_apply_sfx_player_volume(player)


func _get_target_bgm_volume_db(fade_factor: float = 1.0) -> float:
	var base_linear: float = db_to_linear(bgm_volume_db)
	base_linear *= clampf(fade_factor, 0.0, 1.0)
	if _is_user_paused:
		base_linear *= clampf(paused_bgm_volume_multiplier, 0.0, 1.0)
	if base_linear <= 0.0:
		return BGM_SILENCE_DB
	return linear_to_db(base_linear)


func _configure_bgm_stream_loop(stream: AudioStream) -> void:
	_configure_loop_stream(stream)


func _configure_loop_stream(stream: AudioStream) -> void:
	if stream == null:
		return
	stream.set("loop", true)
	stream.set("loop_offset", 0)


func _apply_sfx_player_volume(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.volume_db = sfx_volume_db


func _create_bgm_player(player_name: String) -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.set_meta("bgm_fade_factor", 0.0)
	player.volume_db = BGM_SILENCE_DB
	add_child(player)
	_bgm_players.append(player)
	if not player.finished.is_connected(_on_bgm_finished):
		player.finished.connect(_on_bgm_finished.bind(player))


func _get_inactive_bgm_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _bgm_players:
		if player != _active_bgm_player:
			return player
	if _bgm_players.is_empty():
		return null
	return _bgm_players[0]


func _stop_inactive_bgm_players(keep_player: AudioStreamPlayer) -> void:
	for player: AudioStreamPlayer in _bgm_players:
		if player == keep_player:
			continue
		_finish_bgm_player(player)


func _finish_previous_bgm_player(previous_player: AudioStreamPlayer, current_player: AudioStreamPlayer) -> void:
	if previous_player == null or previous_player == current_player:
		return
	_finish_bgm_player(previous_player)


func _finish_stopped_bgm_players(players: Array[AudioStreamPlayer]) -> void:
	for player: AudioStreamPlayer in players:
		_finish_bgm_player(player)
	_active_bgm_player = null


func _finish_bgm_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.stream = null
	_set_bgm_fade_factor(0.0, player)


func _set_bgm_fade_factor(fade_factor: float, player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.set_meta("bgm_fade_factor", clampf(fade_factor, 0.0, 1.0))
	_apply_bgm_player_volume(player)


func _get_bgm_fade_factor(player: AudioStreamPlayer) -> float:
	if player == null or not player.has_meta("bgm_fade_factor"):
		return 1.0
	return float(player.get_meta("bgm_fade_factor"))


func _apply_bgm_player_volume(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.volume_db = _get_target_bgm_volume_db(_get_bgm_fade_factor(player))


func _kill_bgm_fade_tween() -> void:
	if _bgm_fade_tween == null:
		return
	_bgm_fade_tween.kill()
	_bgm_fade_tween = null


func _clear_bgm_fade_tween() -> void:
	_bgm_fade_tween = null


func _on_bgm_finished(player: AudioStreamPlayer) -> void:
	if _current_bgm_id.is_empty() or player == null or player != _active_bgm_player or player.stream == null:
		return
	player.play()
