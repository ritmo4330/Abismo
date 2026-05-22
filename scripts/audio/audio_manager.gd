extends Node

const COMMAND_PLAY_BGM: String = "play_bgm"
const COMMAND_STOP_BGM: String = "stop_bgm"

const BGM_TRACKS: Dictionary[String, String] = {
	"tuning": "",
	"winter_melody": "",
	"dark_fog_lie": "",
}

var _bgm_player: AudioStreamPlayer = null
var _current_bgm_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmPlayer"
	_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bgm_player)


func handle_dialogic_audio_signal(argument: String) -> void:
	var parts: PackedStringArray = argument.split(":", false)
	if parts.is_empty():
		return

	var command: String = parts[0]
	match command:
		COMMAND_PLAY_BGM:
			if parts.size() < 2:
				return
			play_bgm(parts[1])
		COMMAND_STOP_BGM:
			stop_bgm()


func play_bgm(track_id: String) -> void:
	if track_id.is_empty():
		return
	if _current_bgm_id == track_id and _bgm_player != null and _bgm_player.playing:
		return

	var stream_path: String = String(BGM_TRACKS.get(track_id, ""))
	if stream_path.is_empty():
		_current_bgm_id = track_id
		return

	var stream: AudioStream = load(stream_path) as AudioStream
	if stream == null:
		return

	_current_bgm_id = track_id
	_bgm_player.stop()
	_bgm_player.stream = stream
	_bgm_player.play()


func stop_bgm() -> void:
	_current_bgm_id = ""
	if _bgm_player == null:
		return
	_bgm_player.stop()
