extends "res://scripts/weapons/weapon.gd"
## Wind Turbine: blades orbit the player.

const ModelBuilder = preload("res://scripts/model_builder.gd")
const Fx = preload("res://scripts/fx.gd")

# blades, damage, orbit radius, angular speed
const STATS := [[2, 10.0, 3.0, 3.0], [3, 10.0, 3.0, 3.2], [3, 15.0, 3.2, 3.4], [4, 15.0, 3.4, 3.6], [5, 22.0, 3.8, 4.0], [6, 28.0, 3.8, 4.2]]
const HIT_COOLDOWN := 0.45

static var _rotor: Mesh

var _blades: Array[Node3D] = []
var _orbit: MeshInstance3D
var _angle := 0.0
var _recent := {}  # enemy -> time left before it can be hit again


static func _rotor_mesh() -> Mesh:
	if _rotor == null:
		var mb := ModelBuilder.new()
		mb.sphere(0.13, Color(0.8, 0.83, 0.86), Vector3.ZERO, Vector3(1, 0.8, 1))
		for k in 3:
			var a := float(k) / 3.0 * TAU
			mb.box(Vector3(0.13, 0.04, 0.8), Color(0.97, 0.98, 1.0), Vector3(sin(a), 0, cos(a)) * 0.42, Vector3(0.25, a, 0))
			mb.box(Vector3(0.135, 0.045, 0.12), Color(0.9, 0.25, 0.2), Vector3(sin(a), 0, cos(a)) * 0.78, Vector3(0.25, a, 0))
		_rotor = mb.commit()
	return _rotor


func _on_level() -> void:
	if _orbit == null:
		_orbit = Fx.ground(self, {"color": Color(0.85, 0.95, 1.0, 0.35), "inner": 0.94, "softness": 0.05, "dashes": 8.0, "spin": 4.0, "intensity": 0.8}, 1.0, 0.06)
	for b in _blades:
		b.queue_free()
	_blades.clear()
	for i in row(STATS, 1, -1)[0] * (2 if evolved else 1):
		var b := Node3D.new()
		add_child(b)
		MF.inst(_rotor_mesh(), MF.vc_mat(false, 0.4), b, Vector3.ZERO, false)
		MF.inst(MF.cyl_mesh(0.85, 0.85, 0.01), MF.glow_mat(Color(0.8, 0.95, 1.0, 0.14), 1.5), b, Vector3.ZERO, false)
		_blades.append(b)


func tick(delta: float) -> void:
	var s: Array = row(STATS, 1, -1)
	_angle += s[3] * delta
	_orbit.position = Vector3(player.position.x, 0.06, player.position.z)
	var orbit_r := area(s[2])
	_orbit.scale = Vector3(orbit_r + 0.4, 1, orbit_r + 0.4)
	for e in _recent.keys():
		_recent[e] -= delta
		if _recent[e] <= 0.0:
			_recent.erase(e)
	# Wind Farm: a second, wider ring spins the other way
	var n: int = s[0]
	for i in _blades.size():
		var outer := i >= n
		var k := i % n
		var a := (-_angle * 0.8 if outer else _angle) + float(k) / n * TAU
		var r := orbit_r * (1.65 if outer else 1.0)
		var b := _blades[i]
		b.position = player.position + Vector3(cos(a) * r, 0.8, sin(a) * r)
		b.rotation.y += delta * 16.0
		for e in game.enemies_near(b.position, 0.65):
			if _recent.has(e):
				continue
			_recent[e] = HIT_COOLDOWN
			game.damage_enemy(e, s[1], flat(e.position - player.position).normalized(), 4.0)
