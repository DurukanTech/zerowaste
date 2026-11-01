extends Node3D
## Ambient wildlife: butterflies over flowers and the garden, seagulls
## gliding over the beach, ducks paddling on the pond. Each kind is one
## MultiMesh animated in code (a few dozen transforms per frame).

const MF = preload("res://scripts/mesh_factory.gd")
const ModelBuilder = preload("res://scripts/model_builder.gd")
const Zones = preload("res://scripts/world_zones.gd")

const BUTTERFLIES := 26
const GULLS := 6
const DUCKS := 3

var _flies: MultiMesh
var _gulls: MultiMesh
var _ducks: MultiMesh
var _fly_data: Array = []   # [anchor, phase, speed, radius]
var _gull_data: Array = []
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var anchors := [Vector3(-47, 0, -53), Vector3(-36, 0, -44), Vector3(0, 0, -10), Vector3(-46, 0, 8), Vector3(20, 0, 15), Vector3(-20, 0, 20), Vector3(46, 0, 21), Vector3(10, 0, 42)]
	var cols := [Color(1.0, 0.85, 0.2), Color(1.0, 0.55, 0.15), Color(0.95, 0.95, 1.0), Color(0.55, 0.75, 1.0), Color(0.95, 0.45, 0.7)]
	_flies = _multimesh(_butterfly_mesh(), BUTTERFLIES, true)
	for i in BUTTERFLIES:
		var a: Vector3 = anchors[i % anchors.size()] + Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))
		_fly_data.append([a, rng.randf() * TAU, rng.randf_range(0.5, 0.9), rng.randf_range(1.5, 3.5)])
		_flies.set_instance_color(i, cols[i % cols.size()])
	_gulls = _multimesh(_gull_mesh(), GULLS, false)
	for i in GULLS:
		_gull_data.append([Vector3(rng.randf_range(-50, 50), 0, rng.randf_range(62, 74)), rng.randf() * TAU, rng.randf_range(0.18, 0.3), rng.randf_range(6.0, 12.0)])
	_ducks = _multimesh(_duck_mesh(), DUCKS, false)


func _multimesh(mesh: Mesh, count: int, colors: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors
	mm.mesh = mesh
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = MF.vc_mat()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mm


func _process(delta: float) -> void:
	_t += delta
	for i in BUTTERFLIES:
		var d: Array = _fly_data[i]
		var ph: float = d[1] + _t * d[2]
		var r: float = d[3]
		var pos: Vector3 = d[0] + Vector3(sin(ph) * r + sin(ph * 2.3) * 0.6, 0.9 + sin(ph * 3.1) * 0.35, cos(ph * 0.8) * r)
		var heading := atan2(cos(ph) * r, -sin(ph * 0.8) * r * 0.8)
		var flap := 0.25 + absf(sin(_t * 18.0 + i)) * 0.9
		_flies.set_instance_transform(i, Transform3D(Basis(Vector3.UP, heading).scaled(Vector3(flap, 1.0, 1.0)), pos))
	for i in GULLS:
		var d: Array = _gull_data[i]
		var ph: float = d[1] + _t * d[2]
		var r: float = d[3]
		var pos: Vector3 = d[0] + Vector3(cos(ph) * r, 8.0 + sin(ph * 2.0) * 0.8, sin(ph) * r * 0.6)
		var heading := ph + PI
		var flap := 0.75 + sin(_t * 5.0 + i * 2.0) * 0.25
		_gulls.set_instance_transform(i, Transform3D(Basis(Vector3.UP, heading).scaled(Vector3(1.0, flap, 1.0)), pos))
	for i in DUCKS:
		var ph := _t * 0.12 + i * TAU / DUCKS
		var pos := Zones.POND_C + Vector3(cos(ph) * Zones.POND_R.x * 0.45, 0.08 + sin(_t * 2.0 + i) * 0.03, sin(ph) * Zones.POND_R.y * 0.45)
		_ducks.set_instance_transform(i, Transform3D(Basis(Vector3.UP, -ph), pos))


static func _butterfly_mesh() -> Mesh:
	var mb := ModelBuilder.new()
	var w := Color(1, 1, 1)
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(0.22, 0.01, 0.18), w, Vector3(sx * 0.12, 0, 0.04), Vector3(0, 0, sx * 0.4))
		mb.box(Vector3(0.16, 0.01, 0.12), w, Vector3(sx * 0.1, -0.02, -0.1), Vector3(0, 0, sx * 0.4))
	mb.box(Vector3(0.03, 0.03, 0.22), Color(0.15, 0.12, 0.1), Vector3.ZERO)
	return mb.commit()


static func _gull_mesh() -> Mesh:
	var mb := ModelBuilder.new()
	var white := Color(0.97, 0.97, 0.97)
	mb.capsule(0.12, 0.6, white, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(0.7, 0.03, 0.25), white, Vector3(sx * 0.38, 0.08, 0), Vector3(0, 0, sx * 0.25))
		mb.box(Vector3(0.25, 0.03, 0.2), Color(0.3, 0.32, 0.35), Vector3(sx * 0.82, 0.18, 0), Vector3(0, 0, sx * 0.25))
	mb.box(Vector3(0.05, 0.05, 0.12), Color(1.0, 0.75, 0.2), Vector3(0, 0, 0.36))
	return mb.commit()


static func _duck_mesh() -> Mesh:
	var mb := ModelBuilder.new()
	mb.sphere(0.25, Color(0.55, 0.42, 0.3), Vector3(0, 0.08, 0), Vector3(1, 0.7, 1.4))
	mb.sphere(0.13, Color(0.15, 0.45, 0.25), Vector3(0, 0.3, 0.28))
	mb.box(Vector3(0.08, 0.04, 0.12), Color(1.0, 0.7, 0.15), Vector3(0, 0.28, 0.42))
	mb.box(Vector3(0.12, 0.03, 0.03), Color(0.95, 0.95, 0.95), Vector3(0, 0.25, 0.2))
	return mb.commit()
