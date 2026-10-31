extends Node
## Procedurally generated sound effects (no audio files needed).

const RATE := 22050
const VOICES := 14

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _last := {}
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_streams["pickup"] = _make([1046.0, 1568.0], 0.035, 0.18, "sine")
	_streams["hit"] = _make([180.0], 0.05, 0.22, "noise")
	_streams["hurt"] = _make([220.0, 150.0], 0.07, 0.25, "square")
	_streams["shoot"] = _make([1400.0], 0.05, 0.08, "tri", -0.6)
	_streams["zap"] = _make([900.0, 1800.0, 600.0], 0.04, 0.16, "square")
	_streams["whoosh"] = _make([300.0], 0.22, 0.2, "noise", -0.5)
	_streams["explode"] = _make([90.0], 0.35, 0.45, "noise")
	_streams["levelup"] = _make([523.0, 659.0, 784.0, 1046.0], 0.08, 0.22, "tri")
	_streams["deposit"] = _make([659.0, 880.0, 1175.0, 1318.0], 0.06, 0.22, "sine")
	_streams["select"] = _make([784.0, 1175.0], 0.05, 0.2, "tri")
	_streams["warning"] = _make([110.0, 98.0, 110.0, 98.0], 0.18, 0.3, "square")
	_streams["win"] = _make([523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0], 0.14, 0.25, "tri")
	_streams["lose"] = _make([392.0, 330.0, 262.0, 196.0], 0.2, 0.25, "tri")
	_streams["click"] = _make([600.0], 0.03, 0.15, "square")


func play(sound: String, volume_db := 0.0, min_interval := 0.03) -> void:
	if not _streams.has(sound):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(sound, -10.0)) < min_interval:
		return
	_last[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[sound]
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.94, 1.06)
	p.play()


func _make(freqs: Array, seg: float, vol: float, wave: String, slide := 0.0) -> AudioStreamWAV:
	var total := int(RATE * seg * freqs.size())
	var data := PackedByteArray()
	data.resize(total * 2)
	var phase := 0.0
	var lp := 0.0
	for i in total:
		var t := float(i) / RATE
		var si := mini(int(t / seg), freqs.size() - 1)
		var local_t := t - si * seg
		var f: float = freqs[si] * (1.0 + slide * local_t / seg)
		phase += f / RATE
		var s := 0.0
		match wave:
			"sine":
				s = sin(phase * TAU)
			"square":
				s = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			"tri":
				s = absf(fmod(phase, 1.0) * 4.0 - 2.0) - 1.0
			"noise":
				# low-passed noise, cutoff scales with "frequency"
				lp = lerpf(lp, randf_range(-1.0, 1.0), clampf(f / 2000.0, 0.02, 1.0))
				s = lp * 2.0
		var env := pow(1.0 - float(i) / total, 1.5)
		var attack := minf(1.0, local_t * 300.0)
		var v := clampf(s * env * attack * vol, -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
