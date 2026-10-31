extends Node
## Procedurally generated sound effects with a soft, organic palette
## (marimba / wood, water drops, bells, muffled thumps). Also sets up the
## audio buses: Master (limiter) <- Music, SFX (compressor).

const RATE := 22050
const VOICES := 18
# pentatonic notes for the rising pickup melody (C4 .. E5, nothing shrill)
const PICKUP_NOTES := [261.6, 293.7, 329.6, 392.0, 440.0, 523.3, 587.3, 659.3]

## Mix table: sound -> [base dB, min interval s, max simultaneous copies].
## Call sites pass a dB offset and may ask for a longer interval.
const MIX := {
	"pickup": [-21.0, 0.075, 3],
	"hit": [-27.0, 0.11, 2],
	"hurt": [-1.0, 0.45, 1],
	"shoot": [-17.0, 0.14, 2],
	"zap": [-12.0, 0.3, 2],
	"whoosh": [-12.0, 0.15, 2],
	"dash": [-8.0, 0.1, 1],
	"explode": [0.0, 0.15, 2],
	"levelup": [-5.0, 0.2, 1],
	"deposit": [-4.0, 0.15, 2],
	"select": [-7.0, 0.05, 2],
	"click": [-8.0, 0.04, 2],
	"warning": [-4.0, 0.6, 1],
	"win": [-2.0, 1.0, 1],
	"lose": [-2.0, 1.0, 1],
	"ult": [2.0, 0.5, 1],
}
## Big moments briefly duck the music: sound -> [dB, seconds].
const DUCK := {"explode": [-5.0, 0.6], "ult": [-9.0, 1.4], "warning": [-6.0, 1.2], "levelup": [-4.0, 0.8], "win": [-10.0, 2.5], "lose": [-10.0, 2.5]}

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _owner: Array[String] = []    # sound playing on each voice
var _started: Array[float] = []
var _last := {}
var _pickup_step := 0
var _pickup_t := -10.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
		_owner.append("")
		_started.append(0.0)
	_build_sounds()
	# test hook: `-- --dumpsfx=<dir>` writes every sound as a .wav file
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dumpsfx="):
			for k in _streams:
				_streams[k].save_to_wav(arg.substr(10).path_join(k + ".wav"))


func _setup_buses() -> void:
	if AudioServer.get_bus_index("SFX") >= 0:
		return
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, limiter)
	for bus_name in ["Music", "SFX"]:
		var i := AudioServer.bus_count
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")
	# music: a low-pass used to muffle it while paused (off by default)
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"), lp)
	# effects: gentle compressor so crowds of sounds do not pile up
	var comp := AudioEffectCompressor.new()
	comp.threshold = -14.0
	comp.ratio = 4.0
	comp.attack_us = 2000.0
	comp.release_ms = 180.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"), comp)


func play(sound: String, volume_db := 0.0, min_interval := 0.0) -> void:
	var mix: Array = MIX.get(sound, [0.0, 0.03, 2])
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(sound, -10.0)) < maxf(mix[1], min_interval):
		return
	_last[sound] = now
	var key := sound
	var pitch := randf_range(0.97, 1.03)
	if sound == "pickup":
		# consecutive pickups climb the scale, a pause resets it
		_pickup_step = mini(_pickup_step + 1, PICKUP_NOTES.size() - 1) if now - _pickup_t < 0.6 else 0
		_pickup_t = now
		key = "pickup_%d" % _pickup_step
		pitch = 1.0
	if not _streams.has(key):
		return
	var v := _voice(sound, mix[2])
	var p := _players[v]
	_owner[v] = sound
	_started[v] = now
	p.stream = _streams[key]
	p.volume_db = mix[0] + volume_db
	p.pitch_scale = pitch
	p.play()
	if DUCK.has(sound):
		var music = get_node_or_null("/root/Music")
		if music:
			music.duck(DUCK[sound][0], DUCK[sound][1])


## Picks a voice: reuse the oldest copy when the sound is at its limit,
## else a free voice, else the oldest voice overall.
func _voice(sound: String, max_copies: int) -> int:
	var copies := 0
	var oldest_same := -1
	var free := -1
	var oldest := 0
	for i in VOICES:
		var playing := _players[i].playing
		if playing and _owner[i] == sound:
			copies += 1
			if oldest_same < 0 or _started[i] < _started[oldest_same]:
				oldest_same = i
		if not playing and free < 0:
			free = i
		if _started[i] < _started[oldest]:
			oldest = i
	if copies >= max_copies and oldest_same >= 0:
		return oldest_same
	return free if free >= 0 else oldest


# --- sound design ----------------------------------------------------------------

const MARIMBA := [[1.0, 1.0, 1.0], [4.0, 0.18, 0.25], [9.8, 0.04, 0.12]]
const BELL := [[1.0, 1.0, 1.0], [2.76, 0.35, 0.6], [5.4, 0.12, 0.35]]
const WOOD := [[1.0, 1.0, 1.0], [2.3, 0.45, 0.5]]
const WARM := [[1.0, 1.0, 1.0], [2.0, 0.25, 0.6]]


func _build_sounds() -> void:
	for i in PICKUP_NOTES.size():
		_streams["pickup_%d" % i] = _wav(_tone([PICKUP_NOTES[i]], 0.0, 0.16, 0.13, MARIMBA, 0.32))
	_streams["hit"] = _wav(_mix([_tone([150.0], 0.0, 0.09, 0.03, WOOD, 0.5), _noise(0.05, 900.0, 300.0, 0.002, 0.12)]))
	_streams["hurt"] = _wav(_mix([_thump(130.0, 55.0, 0.24, 0.4), _noise(0.12, 450.0, 150.0, 0.004, 0.1)]))
	_streams["shoot"] = _wav(_tone([740.0], 0.0, 0.14, 0.05, BELL, 0.22))
	_streams["zap"] = _wav(_tone([392.0, 587.3], 0.025, 0.5, 0.22, WARM, 0.3, 0.02))
	_streams["whoosh"] = _wav(_noise(0.28, 300.0, 1300.0, 0.09, 0.45))
	_streams["dash"] = _wav(_noise(0.18, 600.0, 1800.0, 0.03, 0.45))
	_streams["explode"] = _wav(_mix([_thump(95.0, 34.0, 0.55, 0.45), _noise(0.5, 400.0, 100.0, 0.006, 0.22)]))
	_streams["levelup"] = _wav(_mix([_tone([261.6, 329.6, 392.0, 523.3], 0.075, 0.5, 0.2, MARIMBA, 0.32), _pad(_tone([523.3], 0.0, 0.9, 0.45, BELL, 0.18), 0.3)]))
	_streams["deposit"] = _wav(_mix([_drop(420.0, 880.0, 0.12, 0.45), _pad(_tone([392.0, 493.9, 587.3, 784.0], 0.06, 0.45, 0.18, MARIMBA, 0.28), 0.06)]))
	_streams["select"] = _wav(_tone([329.6, 392.0], 0.055, 0.25, 0.1, MARIMBA, 0.35))
	_streams["click"] = _wav(_tone([380.0], 0.0, 0.07, 0.025, WARM, 0.3, 0.006))
	_streams["warning"] = _wav(_tone([146.8, 146.8], 0.45, 1.2, 0.5, [[1.0, 1.0, 1.0], [2.0, 0.45, 0.7], [2.76, 0.25, 0.45]], 0.55, 0.012))
	_streams["win"] = _wav(_mix([_tone([261.6, 329.6, 392.0, 523.3, 659.3, 784.0], 0.11, 1.0, 0.3, MARIMBA, 0.32), _pad(_tone([523.3, 784.0], 0.0, 1.6, 0.7, BELL, 0.18), 0.66)]))
	_streams["lose"] = _wav(_tone([392.0, 329.6, 261.6, 196.0], 0.22, 0.9, 0.35, MARIMBA, 0.35))
	_streams["ult"] = _wav(_mix([_thump(110.0, 40.0, 0.8, 0.45), _noise(0.7, 400.0, 2200.0, 0.02, 0.25), _pad(_tone([261.6, 392.0, 523.3], 0.05, 1.2, 0.5, BELL, 0.22), 0.1)]))


## Notes started every `gap` seconds, each ringing for `length` with the
## given partials ([ratio, amplitude, decay multiplier]).
func _tone(freqs: Array, gap: float, length: float, decay: float, partials: Array, vol: float, attack := 0.004) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(int(RATE * (gap * (freqs.size() - 1) + length)))
	for n in freqs.size():
		var off := int(RATE * gap * n)
		var count := int(RATE * length)
		for i in count:
			var t := float(i) / RATE
			var s := 0.0
			for p in partials:
				s += sin(TAU * freqs[n] * p[0] * t) * p[1] * exp(-t / (decay * p[2]))
			buf[off + i] += s * minf(1.0, t / attack) * vol
	return buf


## Water drop: a sine whose pitch sweeps up quickly.
func _drop(f0: float, f1: float, length: float, vol: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	var count := int(RATE * length)
	buf.resize(count)
	var phase := 0.0
	for i in count:
		var k := float(i) / count
		phase += lerpf(f0, f1, sqrt(k)) / RATE
		buf[i] = sin(phase * TAU) * sin(PI * minf(1.0, k * 4.0)) * pow(1.0 - k, 2.0) * vol
	return buf


## Muffled low thump (impacts, hurt, explosions).
func _thump(f0: float, f1: float, length: float, vol: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	var count := int(RATE * length)
	buf.resize(count)
	var phase := 0.0
	for i in count:
		var k := float(i) / count
		phase += lerpf(f0, f1, 1.0 - pow(1.0 - k, 3.0)) / RATE
		buf[i] = sin(phase * TAU) * exp(-k * 5.0) * minf(1.0, i / (RATE * 0.003)) * vol
	return buf


## Low-passed noise with a cutoff sweep and a smooth swell envelope.
func _noise(length: float, cut0: float, cut1: float, attack: float, vol: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	var count := int(RATE * length)
	buf.resize(count)
	var lp := 0.0
	var lp2 := 0.0
	for i in count:
		var k := float(i) / count
		var a := clampf(TAU * lerpf(cut0, cut1, k) / RATE, 0.0, 1.0)
		lp += (randf_range(-1.0, 1.0) - lp) * a
		lp2 += (lp - lp2) * a
		var t := float(i) / RATE
		buf[i] = lp2 * 2.5 * minf(1.0, t / attack) * pow(1.0 - k, 1.6) * vol
	return buf


## Delays a buffer by `seconds` (for layering).
func _pad(buf: PackedFloat32Array, seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(RATE * seconds))
	out.append_array(buf)
	return out


func _mix(layers: Array) -> PackedFloat32Array:
	var size := 0
	for l in layers:
		size = maxi(size, l.size())
	var out := PackedFloat32Array()
	out.resize(size)
	for l in layers:
		for i in l.size():
			out[i] += l[i]
	return out


## Soft-clips, fades the tail and packs 16-bit mono PCM.
func _wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var count := buf.size()
	var fade := mini(count, int(RATE * 0.01))
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var v := buf[i]
		v = v / (1.0 + absf(v))  # soft clip
		if i > count - fade:
			v *= float(count - i) / fade
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
