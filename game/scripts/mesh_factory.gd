extends RefCounted
## Cached primitive meshes and materials so hundreds of enemies share resources.

static var _mats := {}
static var _meshes := {}


static func mat(color: Color, emission := 0.0, unshaded := false) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [color.to_html(), emission, unshaded]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if color.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = Color(color.r, color.g, color.b)
		m.emission_energy_multiplier = emission
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m


static func _cached(key: String, factory: Callable) -> Mesh:
	if not _meshes.has(key):
		_meshes[key] = factory.call()
	return _meshes[key]


static func box_mesh(size: Vector3) -> Mesh:
	return _cached("box%s" % size, func():
		var m := BoxMesh.new()
		m.size = size
		return m)


static func sphere_mesh(r: float, h := -1.0) -> Mesh:
	var height := r * 2.0 if h < 0.0 else h
	return _cached("sph%s_%s" % [r, height], func():
		var m := SphereMesh.new()
		m.radius = r
		m.height = height
		m.radial_segments = 16
		m.rings = 8
		return m)


static func cyl_mesh(top: float, bottom: float, h: float) -> Mesh:
	return _cached("cyl%s_%s_%s" % [top, bottom, h], func():
		var m := CylinderMesh.new()
		m.top_radius = top
		m.bottom_radius = bottom
		m.height = h
		m.radial_segments = 14
		m.rings = 1
		return m)


static func torus_mesh(inner: float, outer: float) -> Mesh:
	return _cached("tor%s_%s" % [inner, outer], func():
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = 32
		m.ring_segments = 8
		return m)


static func prism_mesh(size: Vector3) -> Mesh:
	return _cached("pri%s" % size, func():
		var m := PrismMesh.new()
		m.size = size
		return m)


static func inst(mesh: Mesh, material: Material, parent: Node3D, pos := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, color: Color, pos := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	return inst(box_mesh(size), mat(color), parent, pos, shadow)


static func sphere(parent: Node3D, r: float, color: Color, pos := Vector3.ZERO, shadow := true, h := -1.0) -> MeshInstance3D:
	return inst(sphere_mesh(r, h), mat(color), parent, pos, shadow)


static func cyl(parent: Node3D, top: float, bottom: float, h: float, color: Color, pos := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	return inst(cyl_mesh(top, bottom, h), mat(color), parent, pos, shadow)


## Two cartoon eyes facing +Z (kept to 2 meshes for draw-call budget).
static func eyes(parent: Node3D, y: float, z: float, spread := 0.14, size := 0.08, color := Color(0.05, 0.05, 0.05)) -> void:
	var m := mat(color)
	for sx in [-1.0, 1.0]:
		inst(sphere_mesh(size), m, parent, Vector3(sx * spread, y, z), false)
