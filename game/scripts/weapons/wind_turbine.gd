extends "res://scripts/weapons/weapon.gd"
## Wind Turbine: blades orbit the player.

# blades, damage, orbit radius, angular speed
const STATS := [[2, 10.0, 3.0, 3.0], [3, 10.0, 3.0, 3.2], [3, 15.0, 3.2, 3.4], [4, 15.0, 3.4, 3.6], [5, 22.0, 3.8, 4.0]]
const HIT_COOLDOWN := 0.45

var _blades: Array[Node3D] = []
var _angle := 0.0
var _recent := {}  # enemy -> time left before it can be hit again


func _on_level() -> void:
	for b in _blades:
		b.queue_free()
	_blades.clear()
	for i in STATS[level - 1][0]:
		var b := Node3D.new()
		add_child(b)
		MF.cyl(b, 0.12, 0.12, 0.16, Color(0.75, 0.78, 0.8), Vector3.ZERO, false)
		for k in 3:
			var blade := MF.box(b, Vector3(0.12, 0.05, 0.75), Color(0.97, 0.98, 1.0), Vector3.ZERO, false)
			blade.rotation.y = float(k) / 3.0 * TAU
			blade.position = Vector3(sin(blade.rotation.y), 0, cos(blade.rotation.y)) * 0.38
		_blades.append(b)


func tick(delta: float) -> void:
	var s: Array = STATS[level - 1]
	_angle += s[3] * delta
	for e in _recent.keys():
		_recent[e] -= delta
		if _recent[e] <= 0.0:
			_recent.erase(e)
	var n := _blades.size()
	for i in n:
		var a := _angle + float(i) / n * TAU
		var b := _blades[i]
		b.position = player.position + Vector3(cos(a) * s[2], 0.8, sin(a) * s[2])
		b.rotation.y += delta * 16.0
		for e in game.enemies_near(b.position, 0.65):
			if _recent.has(e):
				continue
			_recent[e] = HIT_COOLDOWN
			game.damage_enemy(e, s[1], flat(e.position - player.position).normalized(), 4.0)
