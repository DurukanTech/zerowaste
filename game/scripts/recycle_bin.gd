extends Node3D
## Color-coded recycling bin. Depositing matching materials grants a buff.

const MF = preload("res://scripts/mesh_factory.gd")
const ModelBuilder = preload("res://scripts/model_builder.gd")
const Fx = preload("res://scripts/fx.gd")
const DEPOSIT_RADIUS := 2.4

static var _meshes := {}

var mat_type := "plastic"
var busy := false
var _t := 0.0
var _active := false
var _arrow: MeshInstance3D
var _label: Label3D
var _ring: MeshInstance3D
var _ring_mat: ShaderMaterial
var _particles: CPUParticles3D
var _visual: Node3D


static func _mesh_for(t: String) -> Mesh:
	if _meshes.has(t):
		return _meshes[t]
	var c: Color = GameData.MATERIALS[t].color
	var dark := c.darkened(0.3)
	var white := Color(0.96, 0.96, 0.96)
	var mb := ModelBuilder.new()
	mb.box(Vector3(1.3, 1.35, 1.1), c, Vector3(0, 0.78, 0))
	mb.box(Vector3(1.22, 0.1, 1.02), dark, Vector3(0, 0.08, 0))
	mb.box(Vector3(1.38, 0.08, 1.18), dark, Vector3(0, 1.46, 0))
	mb.box(Vector3(1.42, 0.14, 1.24), c.lightened(0.1), Vector3(0, 1.58, -0.02), Vector3(-0.08, 0, 0))
	mb.box(Vector3(0.7, 0.08, 0.06), Color(0.1, 0.1, 0.1), Vector3(0, 1.58, 0.6))
	mb.box(Vector3(0.5, 0.06, 0.12), dark, Vector3(0, 1.72, -0.45))
	for sx in [-1.0, 1.0]:
		mb.cyl(0.16, 0.16, 0.1, Color(0.12, 0.12, 0.13), Vector3(sx * 0.62, 0.16, -0.48), Vector3(0, 0, PI * 0.5))
	# front plate with the recycling triangle and a material icon
	mb.box(Vector3(0.9, 0.75, 0.03), white, Vector3(0, 0.82, 0.56))
	for i in 3:
		var a := float(i) / 3.0 * TAU
		mb.prism(Vector3(0.16, 0.16, 0.03), c, Vector3(sin(a) * 0.15 - 0.2, 0.82 + cos(a) * 0.15, 0.58), Vector3(0, 0, -a))
	var icon := Vector3(0.22, 0.82, 0.58)
	match t:
		"plastic":
			mb.cyl(0.07, 0.07, 0.24, dark, icon)
			mb.cyl(0.03, 0.06, 0.08, dark, icon + Vector3(0, 0.16, 0))
		"paper":
			mb.box(Vector3(0.2, 0.26, 0.02), dark, icon, Vector3(0, 0, 0.15))
			mb.box(Vector3(0.12, 0.02, 0.02), white, icon + Vector3(0, 0.04, 0.012), Vector3(0, 0, 0.15))
		"glass":
			mb.cyl(0.08, 0.09, 0.2, dark, icon)
			mb.cyl(0.05, 0.05, 0.06, dark, icon + Vector3(0, 0.13, 0))
		"organic":
			mb.sphere(0.1, dark, icon, Vector3(1, 0.9, 0.6))
			mb.box(Vector3(0.08, 0.03, 0.02), Color(0.3, 0.7, 0.2), icon + Vector3(0.05, 0.12, 0), Vector3(0, 0, 0.6))
	_meshes[t] = mb.commit()
	return _meshes[t]


func setup(t: String) -> void:
	mat_type = t
	var c: Color = GameData.MATERIALS[t].color
	_visual = Node3D.new()
	add_child(_visual)
	MF.inst(_mesh_for(t), MF.vc_mat(), _visual)
	# deposit radius ring + soft sky beam so it reads from far away
	_ring = Fx.ground(self, {"color": c, "inner": 0.86, "softness": 0.1, "dashes": 10.0, "spin": 1.5, "intensity": 1.0}, DEPOSIT_RADIUS, 0.06)
	_ring_mat = _ring.material_override
	Fx.ground(self, {"color": Color(c.r, c.g, c.b, 0.35), "falloff": 1.0, "intensity": 0.8}, DEPOSIT_RADIUS * 0.9, 0.05)
	MF.inst(MF.cyl_mesh(0.08, 0.4, 30.0), MF.glow_mat(Color(c.r, c.g, c.b, 0.16), 1.5), self, Vector3(0, 15.0, 0), false)
	_arrow = MF.inst(MF.prism_mesh(Vector3(0.6, 0.7, 0.2)), MF.mat(c, 1.5), self, Vector3(0, 2.8, 0), false)
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
	_particles = Fx.burst(c, 32, 0.9, Vector2(5, 9), 0.18)
	_particles.spread = 50.0
	_particles.position = Vector3(0, 1.6, 0)
	add_child(_particles)
	refresh_text()
	Loc.language_changed.connect(refresh_text)


func refresh_text() -> void:
	_label.text = Loc.upper(Loc.pick(GameData.MATERIALS[mat_type].name))


func set_label_visible(on: bool) -> void:
	_label.visible = on


## Highlighted while the player carries this bin's material.
func set_active(on: bool) -> void:
	_active = on


func tick(delta: float) -> void:
	_t += delta
	_arrow.position.y = 2.8 + sin(_t * 3.0) * 0.25
	_arrow.rotation.y = _t * 2.0
	var target := 1.2 + sin(_t * 5.0) * 0.6 if _active else 0.55
	_ring_mat.set_shader_parameter("intensity", target)
	_arrow.visible = _active or int(_t * 2.0) % 2 == 0


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
