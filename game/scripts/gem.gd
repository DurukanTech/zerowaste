extends Node3D
## Material pickup dropped by waste monsters.

const MF = preload("res://scripts/mesh_factory.gd")

var mat_type := "plastic"
var value := 1.0
var magnet := false
var pull_speed := 0.0
var _t := 0.0
var _mesh: MeshInstance3D


func setup(t: String, v: float) -> void:
	mat_type = t
	value = v
	_t = randf() * TAU
	var color: Color = GameData.MATERIALS[t].color
	var size := 0.32 if v < 4.0 else 0.48
	if t == "heal":
		_mesh = MF.cyl(self, 0.16, 0.16, 0.5, color, Vector3(0, 0.5, 0), false)
		MF.cyl(_mesh, 0.08, 0.08, 0.14, Color(0.15, 0.3, 0.9), Vector3(0, 0.3, 0), false)
	else:
		_mesh = MF.inst(MF.prism_mesh(Vector3(size, size * 1.3, size * 0.6)), MF.mat(color, 0.6), self, Vector3(0, 0.45, 0), false)


func animate(delta: float) -> void:
	_t += delta
	_mesh.rotation.y = _t * 2.5
	_mesh.position.y = 0.45 + sin(_t * 3.0) * 0.1
