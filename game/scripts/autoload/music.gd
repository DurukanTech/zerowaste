extends Node
## Background music: one looping track that keeps playing across scenes.
## Muffled (low-pass + quieter) while the tree is paused, briefly ducked
## under big sound effects, and slightly faster during the final boss.

const TRACK := "res://music/sifiratikmusic.wav"
const BASE_DB := -9.0
const MUFFLE_HZ := 900.0
const MUFFLE_DB := -5.0
const BOSS_PITCH := 1.05

var _player: AudioStreamPlayer
var _lowpass: AudioEffectLowPassFilter
var _muffle := 0.0      # 0..1
var _duck_db := 0.0     # current duck amount (negative)
var _duck_hold := 0.0
var _intense := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bus := AudioServer.get_bus_index("Music")
	_lowpass = AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	_player.stream = load(TRACK)
	_player.volume_db = BASE_DB
	add_child(_player)
	_player.play()


## Briefly lowers the music by `db` (negative) for about `time` seconds.
func duck(db: float, time: float) -> void:
	_duck_db = minf(_duck_db, db)
	_duck_hold = maxf(_duck_hold, time * 0.4)


func set_intense(on: bool) -> void:
	_intense = on


func _process(delta: float) -> void:
	var paused := get_tree().paused
	_muffle = move_toward(_muffle, 1.0 if paused else 0.0, delta * 3.0)
	if _lowpass:
		# exponential sweep sounds natural: 20 kHz open -> ~900 Hz muffled
		_lowpass.cutoff_hz = exp(lerpf(log(20000.0), log(MUFFLE_HZ), _muffle))
	if _duck_hold > 0.0:
		_duck_hold -= delta
	else:
		_duck_db = move_toward(_duck_db, 0.0, delta * 8.0)
	_player.volume_db = BASE_DB + MUFFLE_DB * _muffle + _duck_db
	_player.pitch_scale = move_toward(_player.pitch_scale, BOSS_PITCH if _intense else 1.0, delta * 0.05)


func _exit_tree() -> void:
	# release the track so it is not reported as leaked on quit
	_player.stop()
	_player.stream = null
