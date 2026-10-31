extends Node3D
## Material pickup dropped by waste monsters: a glowing faceted crystal
## (or a water bottle for healing).

const MF = preload("res://scripts/mesh_factory.gd")
const ModelBuilder = preload("res://scripts/model_builder.gd")

static var _meshes := {}

var mat_type := "plastic"
var value := 1.0
var magnet := false
var pull_speed := 0.0
var _t := 0.0
var _mesh: MeshInstance3D
var _size := 1.0
var draw_key := ""
var draw_mat: Material
var use_batch := false  # set by game.gd; the menu backdrop draws its own meshes


static func _mesh_for(t: String) -> Mesh:
	if not _meshes.has(t):
		var mb := ModelBuilder.new()
		if t == "chest":
			# reward crate made of reclaimed wood with a recycling badge
			var wood := Color(0.62, 0.42, 0.22)
			mb.box(Vector3(0.62, 0.42, 0.44), wood, Vector3(0, 0, 0))
			mb.box(Vector3(0.66, 0.06, 0.48), Color(1.0, 0.8, 0.25), Vector3(0, 0.12, 0))
			mb.box(Vector3(0.66, 0.06, 0.48), Color(1.0, 0.8, 0.25), Vector3(0, -0.14, 0))
			mb.box(Vector3(0.64, 0.14, 0.46), wood.lightened(0.15), Vector3(0, 0.26, 0))
			for i in 3:
				var a := float(i) / 3.0 * TAU
				mb.prism(Vector3(0.1, 0.1, 0.02), Color(0.4, 1.0, 0.55), Vector3(sin(a) * 0.08, cos(a) * 0.08, 0.23), Vector3(0, 0, -a))
		elif t == "heal":
			mb.cyl(0.15, 0.15, 0.42, Color(0.35, 0.8, 1.0), Vector3(0, 0, 0))
			mb.cyl(0.155, 0.155, 0.16, Color(0.96, 0.96, 0.96), Vector3(0, -0.02, 0))
			mb.cyl(0.08, 0.08, 0.1, Color(0.15, 0.35, 0.9), Vector3(0, 0.26, 0))
		else:
			var c: Color = GameData.MATERIALS[t].color
			mb.gem(0.2, c, Vector3.ZERO, Vector3(0.75, 1.35, 0.75))
			mb.gem(0.09, c.lightened(0.4), Vector3(0.12, -0.1, 0.05), Vector3(0.7, 1.2, 0.7), Vector3(0, 0.6, 0.4))
		_meshes[t] = mb.commit()
	return _meshes[t]


func setup(t: String, v: float) -> void:
	mat_type = t
	value = v
	_t = randf() * TAU
	_size = 1.5 if v >= 4.0 or t == "chest" else 1.0
	if t == "chest":
		MF.inst(MF.cyl_mesh(0.05, 0.3, 6.0), MF.glow_mat(Color(1.0, 0.85, 0.35, 0.3), 2.0), self, Vector3(0, 3.0, 0), false)
	if use_batch and t != "chest":
		draw_key = "gem|" + t
		draw_mat = material_for(t)
		return  # drawn in bulk by game._draw_batches
	_mesh = MF.inst(_mesh_for(t), material_for(t), self, Vector3(0, 0.45, 0), false)
	_mesh.scale = Vector3.ONE * _size


static func material_for(t: String) -> Material:
	if t == "heal":
		return MF.vc_mat()
	return MF.vc_mat(false, 0.6 if t == "chest" else 1.4)


func mesh_for() -> Mesh:
	return _mesh_for(mat_type)


func animate(delta: float) -> void:
	_t += delta
	if _mesh:
		_mesh.rotation.y = _t * 2.5
		_mesh.position.y = 0.45 + sin(_t * 3.0) * 0.1


## World transform of the spinning, bobbing crystal (for batched drawing).
func mesh_transform() -> Transform3D:
	var b := Basis(Vector3.UP, _t * 2.5).scaled(Vector3.ONE * _size)
	return Transform3D(b, position + Vector3(0, 0.45 + sin(_t * 3.0) * 0.1, 0))
