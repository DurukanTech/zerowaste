extends RefCounted
## Merges many primitive parts into ONE vertex-colored mesh, so a detailed
## model costs a single draw call. Parts are placed with position / euler
## rotation / scale. Avoid negative scales (they flip triangle winding).

static var _prims := {}

var _st := SurfaceTool.new()
var _count := 0


func _init() -> void:
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)


static func _arrays(key: String, factory: Callable) -> Array:
	if not _prims.has(key):
		var m: PrimitiveMesh = factory.call()
		_prims[key] = m.get_mesh_arrays()
	return _prims[key]


func add_arrays(arrays: Array, color: Color, pos: Vector3, rot: Vector3, scl: Vector3) -> void:
	var basis := Basis.from_euler(rot) * Basis.from_scale(scl)
	var xf := Transform3D(basis, pos)
	var nb := basis.inverse().transposed()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in verts.size():
		_st.set_color(color)
		_st.set_normal((nb * norms[i]).normalized())
		_st.add_vertex(xf * verts[i])
	for i in idx:
		_st.add_index(_count + i)
	_count += verts.size()


func box(size: Vector3, c: Color, pos := Vector3.ZERO, rot := Vector3.ZERO) -> void:
	var a := _arrays("box", func():
		var m := BoxMesh.new()
		m.size = Vector3.ONE
		return m)
	add_arrays(a, c, pos, rot, size)


func sphere(r: float, c: Color, pos := Vector3.ZERO, scl := Vector3.ONE, rot := Vector3.ZERO, detail := 1) -> void:
	var a := _arrays("sph%d" % detail, func():
		var m := SphereMesh.new()
		m.radius = 1.0
		m.height = 2.0
		m.radial_segments = [8, 12, 18][detail]
		m.rings = [4, 6, 9][detail]
		return m)
	add_arrays(a, c, pos, rot, scl * r)


## Low-poly faceted gem / octahedron.
func gem(r: float, c: Color, pos := Vector3.ZERO, scl := Vector3.ONE, rot := Vector3.ZERO) -> void:
	var a := _arrays("gem", func():
		var m := SphereMesh.new()
		m.radius = 1.0
		m.height = 2.0
		m.radial_segments = 4
		m.rings = 2
		return m)
	add_arrays(a, c, pos, rot, scl * r)


func cyl(top: float, bottom: float, h: float, c: Color, pos := Vector3.ZERO, rot := Vector3.ZERO, segs := 12) -> void:
	# keyed by radius ratio so cones / tapered shapes share base arrays
	var ratio := snappedf(top / maxf(bottom, 0.0001), 0.01)
	var a := _arrays("cyl%s_%d" % [ratio, segs], func():
		var m := CylinderMesh.new()
		m.top_radius = ratio
		m.bottom_radius = 1.0
		m.height = 1.0
		m.radial_segments = segs
		m.rings = 1
		return m)
	add_arrays(a, c, pos, rot, Vector3(bottom, h, bottom))


func capsule(r: float, h: float, c: Color, pos := Vector3.ZERO, rot := Vector3.ZERO) -> void:
	var a := _arrays("cap%s" % snappedf(h / r, 0.01), func():
		var m := CapsuleMesh.new()
		m.radius = 1.0
		m.height = h / r
		m.radial_segments = 12
		m.rings = 4
		return m)
	add_arrays(a, c, pos, rot, Vector3.ONE * r)


func torus(inner: float, outer: float, c: Color, pos := Vector3.ZERO, rot := Vector3.ZERO) -> void:
	var a := _arrays("tor%s" % snappedf(inner / outer, 0.01), func():
		var m := TorusMesh.new()
		m.inner_radius = inner / outer
		m.outer_radius = 1.0
		m.rings = 16
		m.ring_segments = 8
		return m)
	add_arrays(a, c, pos, rot, Vector3.ONE * outer)


func prism(size: Vector3, c: Color, pos := Vector3.ZERO, rot := Vector3.ZERO) -> void:
	var a := _arrays("prism", func():
		var m := PrismMesh.new()
		m.size = Vector3.ONE
		return m)
	add_arrays(a, c, pos, rot, size)


func is_empty() -> bool:
	return _count == 0


func commit() -> ArrayMesh:
	return _st.commit()
