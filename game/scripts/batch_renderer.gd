extends Node3D
## Draws many copies of the same mesh+material with one MultiMesh each.
## Every frame: begin(), add() each instance, end() to upload the buffers.

const BLOB_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
void fragment() {
	float d = length(UV * 2.0 - 1.0);
	ALBEDO = vec3(0.0);
	ALPHA = smoothstep(1.0, 0.35, d) * 0.42;
}
"""


class Batch:
	var mm: MultiMesh
	var buf := PackedFloat32Array()  # written in place (member, no copy-on-write)
	var n := 0
	var cap := 0

	func grow() -> void:
		cap = maxi(32, cap * 2)
		buf.resize(cap * 12)
		mm.instance_count = cap


static var _plane_mesh: PlaneMesh

var _batches := {}   # key -> Batch
var _blob_mat: ShaderMaterial


func begin() -> void:
	for b in _batches.values():
		b.n = 0


## Queues one instance. `key` must be unique per (mesh, material) pair.
func add(key: String, mesh: Mesh, material: Material, xf: Transform3D, shadow := false) -> void:
	var b: Batch = _batches.get(key)
	if b == null:
		b = _make(mesh, material, shadow)
		_batches[key] = b
	if b.n >= b.cap:
		b.grow()
	var i := b.n * 12
	var bs := xf.basis
	var o := xf.origin
	b.buf[i] = bs.x.x
	b.buf[i + 1] = bs.y.x
	b.buf[i + 2] = bs.z.x
	b.buf[i + 3] = o.x
	b.buf[i + 4] = bs.x.y
	b.buf[i + 5] = bs.y.y
	b.buf[i + 6] = bs.z.y
	b.buf[i + 7] = o.y
	b.buf[i + 8] = bs.x.z
	b.buf[i + 9] = bs.y.z
	b.buf[i + 10] = bs.z.z
	b.buf[i + 11] = o.z
	b.n += 1


## Soft dark disc on the ground (a cheap stand-in for a real shadow).
func blob(pos: Vector3, radius: float) -> void:
	if _blob_mat == null:
		var sh := Shader.new()
		sh.code = BLOB_SHADER
		_blob_mat = ShaderMaterial.new()
		_blob_mat.shader = sh
	var xf := Transform3D(Basis.from_scale(Vector3(radius, 1.0, radius)), Vector3(pos.x, 0.04, pos.z))
	add("__blob", _blob_plane(), _blob_mat, xf)


func end() -> void:
	for b in _batches.values():
		b.mm.buffer = b.buf
		b.mm.visible_instance_count = b.n


func _make(mesh: Mesh, material: Material, shadow: bool) -> Batch:
	var b := Batch.new()
	b.mm = MultiMesh.new()
	b.mm.transform_format = MultiMesh.TRANSFORM_3D
	b.mm.mesh = mesh
	# instances are spread over the whole arena; skip per-frame AABB updates
	b.mm.custom_aabb = AABB(Vector3(-200, -10, -200), Vector3(400, 40, 400))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = b.mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	b.grow()
	return b


static func _blob_plane() -> PlaneMesh:
	if _plane_mesh == null:
		_plane_mesh = PlaneMesh.new()
		_plane_mesh.size = Vector2(2, 2)
	return _plane_mesh
