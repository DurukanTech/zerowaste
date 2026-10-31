extends "res://scripts/weapons/weapon.gd"
## Water Jet: sprays a cone of pressurized water where the player faces,
## damaging and pushing waste. Evolves into four rotating jets.

const Fx = preload("res://scripts/fx.gd")

# damage per tick, length, half angle (rad), cooldown, spray time
const STATS := [[6.0, 5.0, 0.35, 1.6, 0.8], [8.0, 5.0, 0.35, 1.6, 0.8], [8.0, 6.2, 0.45, 1.6, 0.9], [11.0, 6.2, 0.45, 1.3, 0.9], [11.0, 6.5, 0.45, 1.3, 0.9], [15.0, 7.5, 0.42, 0.0, 1.0]]
const TICK := 0.15

var _jets: Array[CPUParticles3D] = []
var _spray := 0.0
var _tick := 0.0
var _spin := 0.0


func _on_level() -> void:
	var want := _jet_count()
	while _jets.size() < want:
		var p := Fx.burst(Color(0.55, 0.85, 1.0), 60, 0.45, Vector2(13, 18), 0.11, true, -9.0)
		p.mesh = MF.sphere_mesh(0.09)
		p.one_shot = false
		p.explosiveness = 0.0
		p.local_coords = false
		p.direction = Vector3(0, 0.12, 1)
		add_child(p)
		_jets.append(p)
	var s: Array = row(STATS, 0, 3)
	for p in _jets:
		p.spread = rad_to_deg(s[2]) * 0.8
		p.initial_velocity_min = s[1] * 2.2
		p.initial_velocity_max = s[1] * 2.9 * player.area_mult()


func _jet_count() -> int:
	if evolved:
		return 4
	return 2 if level >= 5 else 1


func _jet_angle(i: int) -> float:
	if evolved:
		return _spin + i * TAU / 4.0
	return player.facing + i * PI


func tick(delta: float) -> void:
	var s: Array = row(STATS, 0, 3)
	_spin += delta * 1.8
	if evolved:
		_spray = 1.0
	else:
		timer -= delta
		if timer <= 0.0 and _spray <= 0.0:
			timer = cd(s[3]) + s[4]
			_spray = s[4]
			Sfx.play("whoosh")
		_spray -= delta
	var on := _spray > 0.0
	for i in _jets.size():
		var p := _jets[i]
		p.emitting = on
		p.global_position = player.position + Vector3(0, 0.9, 0)
		p.rotation.y = _jet_angle(i)
	if not on:
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	var length := area(s[1])
	var cos_half := cos(s[2])
	for e in game.enemies_near(player.position, length):
		var to := flat(e.position - player.position)
		var d := to.length()
		if d < 0.01:
			continue
		var dir := to / d
		for i in _jets.size():
			var a := _jet_angle(i)
			if dir.dot(Vector3(sin(a), 0, cos(a))) >= cos_half:
				game.damage_enemy(e, s[0], dir, 5.0)
				break
