extends Node3D
## Color-coded recycling bin. Depositing matching materials grants a buff.

const MF = preload("res://scripts/mesh_factory.gd")
const DEPOSIT_RADIUS := 2.4

var mat_type := "plastic"
var busy := false
var _t := 0.0
var _arrow: MeshInstance3D
var _label: Label3D
var _particles: CPUParticles3D
var _visual: Node3D


func setup(t: String) -> void:
	mat_type = t
	var c: Color = GameData.MATERIALS[t].color
	_visual = Node3D.new()
	add_child(_visual)
	MF.box(_visual, Vector3(1.3, 1.5, 1.1), c, Vector3(0, 0.75, 0))
	MF.box(_visual, Vector3(1.45, 0.18, 1.25), c.darkened(0.3), Vector3(0, 1.58, 0))
	MF.box(_visual, Vector3(0.7, 0.12, 0.05), Color(0.1, 0.1, 0.1), Vector3(0, 1.2, 0.56), false)
	# recycle "arrows" on the front: three small triangles
	for i in 3:
		var p := MF.inst(MF.prism_mesh(Vector3(0.22, 0.22, 0.04)), MF.mat(Color(1, 1, 1)), _visual, Vector3(0, 0.75, 0.56), false)
		p.rotation.z = float(i) / 3.0 * TAU
		p.position += Vector3(sin(p.rotation.z), cos(p.rotation.z), 0) * -0.2
	# deposit radius ring + sky beam so it reads from far away
	var ring := MF.inst(MF.torus_mesh(DEPOSIT_RADIUS - 0.12, DEPOSIT_RADIUS), MF.mat(Color(c.r, c.g, c.b, 0.7), 1.0, true), self, Vector3(0, 0.05, 0), false)
	ring.scale.y = 0.2
	MF.inst(MF.cyl_mesh(0.25, 0.25, 30.0), MF.mat(Color(c.r, c.g, c.b, 0.18), 1.0, true), self, Vector3(0, 15.0, 0), false)
	_arrow = MF.inst(MF.prism_mesh(Vector3(0.6, 0.7, 0.2)), MF.mat(c, 1.2), self, Vector3(0, 2.8, 0), false)
	_arrow.rotation.z = PI
	_label = Label3D.new()
	_label.font_size = 56
	_label.outline_size = 12
	_label.pixel_size = 0.01
	_label.modulate = c.lightened(0.3)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.position = Vector3(0, 3.6, 0)
	add_child(_label)
	_particles = CPUParticles3D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 32
	_particles.lifetime = 0.9
	_particles.explosiveness = 1.0
	_particles.direction = Vector3.UP
	_particles.spread = 50.0
	_particles.initial_velocity_min = 5.0
	_particles.initial_velocity_max = 9.0
	_particles.gravity = Vector3(0, -14, 0)
	_particles.scale_amount_min = 0.6
	_particles.scale_amount_max = 1.2
	_particles.mesh = MF.box_mesh(Vector3(0.18, 0.18, 0.18))
	_particles.material_override = MF.mat(c, 1.0)
	_particles.position = Vector3(0, 1.6, 0)
	add_child(_particles)
	refresh_text()
	Loc.language_changed.connect(refresh_text)


func refresh_text() -> void:
	_label.text = Loc.pick(GameData.MATERIALS[mat_type].name).to_upper()


func tick(delta: float) -> void:
	_t += delta
	_arrow.position.y = 2.8 + sin(_t * 3.0) * 0.25
	_arrow.rotation.y = _t * 2.0


func burst() -> void:
	_particles.restart()
	var tw := create_tween()
	_visual.scale = Vector3(1.25, 0.8, 1.25)
	tw.tween_property(_visual, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func relocate(new_pos: Vector3) -> void:
	busy = true
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
	tw.tween_callback(func(): position = new_pos)
	tw.tween_property(self, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): busy = false)
