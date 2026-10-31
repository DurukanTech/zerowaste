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


static func _mesh_for(t: String) -> Mesh:
	if not _meshes.has(t):
		var mb := ModelBuilder.new()
		if t == "heal":
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
	var mat := MF.vc_mat() if t == "heal" else MF.vc_mat(false, 1.4)
	_mesh = MF.inst(_mesh_for(t), mat, self, Vector3(0, 0.45, 0), false)
	if v >= 4.0:
		_mesh.scale = Vector3.ONE * 1.5


func animate(delta: float) -> void:
	_t += delta
	_mesh.rotation.y = _t * 2.5
	_mesh.position.y = 0.45 + sin(_t * 3.0) * 0.1
