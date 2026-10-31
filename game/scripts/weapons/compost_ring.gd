extends "res://scripts/weapons/weapon.gd"
## Compost Ring: damaging, slowing aura around the player.

const ModelBuilder = preload("res://scripts/model_builder.gd")
const Fx = preload("res://scripts/fx.gd")

# radius, damage, tick interval
const STATS := [[2.6, 5.0, 0.5], [3.0, 7.0, 0.5], [3.4, 9.0, 0.45], [3.8, 11.0, 0.4], [4.4, 14.0, 0.35]]

var _field: Node3D
var _leaves: Node3D
var _pulse_mat: ShaderMaterial
var _motes: CPUParticles3D
var _pulse := 0.0


func _on_level() -> void:
	if _field == null:
		_field = Node3D.new()
		add_child(_field)
		Fx.ground(_field, {"color": Color(0.55, 0.75, 0.2, 0.32), "swirl": 0.7, "softness": 0.35, "intensity": 0.8}, 1.0, 0.02)
		var edge := Fx.ground(_field, {"color": Color(0.75, 0.95, 0.35, 0.8), "inner": 0.9, "softness": 0.08, "dashes": 14.0, "spin": -1.0, "intensity": 0.9}, 1.0, 0.03)
		_pulse_mat = edge.material_override
		_leaves = Node3D.new()
		add_child(_leaves)
		var mb := ModelBuilder.new()
		for i in 12:
			var a := float(i) / 12.0 * TAU
			var c := Color(0.5, 0.78, 0.2) if i % 2 == 0 else Color(0.55, 0.35, 0.15)
			mb.sphere(0.13, c, Vector3(cos(a), 0.2, sin(a)), Vector3(0.6, 0.25, 1.4), Vector3(0, -a, 0.3), 0)
		MF.inst(mb.commit(), MF.vc_mat(), _leaves, Vector3.ZERO, false)
		_motes = Fx.burst(Color(0.7, 0.95, 0.3), 14, 1.4, Vector2(0.3, 0.9), 0.07, true, 0.6)
		_motes.one_shot = false
		_motes.explosiveness = 0.0
		_motes.local_coords = false
		_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		add_child(_motes)
		_motes.emitting = true
	var r: float = STATS[level - 1][0]
	_field.scale = Vector3(r, 1, r)
	_leaves.scale = Vector3(r, 1, r)
	_motes.emission_sphere_radius = r * 0.8


func tick(delta: float) -> void:
	var s: Array = STATS[level - 1]
	position = Vector3(player.position.x, 0.04, player.position.z)
	_leaves.rotation.y += delta * 1.2
	_pulse = maxf(0.0, _pulse - delta * 3.0)
	_pulse_mat.set_shader_parameter("intensity", 0.9 + _pulse)
	timer -= delta
	if timer <= 0.0:
		timer = cd(s[2])
		var hit := false
		for e in game.enemies_near(player.position, s[0]):
			e.slow_t = 0.6
			game.damage_enemy(e, s[1])
			hit = true
		if hit:
			_pulse = 1.0
