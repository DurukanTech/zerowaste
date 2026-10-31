extends RefCounted
## Builds the Antalya coastal park shared by the run and the menu backdrop.

const MF = preload("res://scripts/mesh_factory.gd")


static func setup_environment(parent: Node3D, golden := false) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.82, 0.9)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 0.8
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	if golden:
		# warm "golden hour" look for the menu backdrop, with a visible horizon
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.32, 0.45, 0.72)
		sky_mat.sky_horizon_color = Color(1.0, 0.68, 0.45)
		sky_mat.ground_horizon_color = Color(1.0, 0.68, 0.45)
		sky_mat.ground_bottom_color = Color(0.2, 0.25, 0.3)
		var sky := Sky.new()
		sky.sky_material = sky_mat
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_color = Color(0.85, 0.75, 0.75)
		env.ambient_light_energy = 0.3
		env.fog_enabled = true
		env.fog_light_color = Color(0.85, 0.6, 0.45)
		env.fog_density = 0.0025
		# low sun over the sea (south-west), light travelling inland
		sun.rotation_degrees = Vector3(-22, 25, 0)
		sun.light_color = Color(1.0, 0.78, 0.55)
		sun.light_energy = 0.8
		sun.directional_shadow_max_distance = 60.0
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.55, 0.8, 0.95)
	we.environment = env
	parent.add_child(we)
	parent.add_child(sun)


static func build_arena(parent: Node3D, clear := Vector3.INF, clear_r := 0.0) -> void:
	var world := Node3D.new()
	world.name = "World"
	parent.add_child(world)
	var x0 := GameData.ARENA_X + 6.0
	# grass park
	var grass := MeshInstance3D.new()
	var gm := PlaneMesh.new()
	gm.size = Vector2(x0 * 2.0, GameData.ARENA_Z_MAX - GameData.ARENA_Z_MIN + 12.0)
	grass.mesh = gm
	grass.position = Vector3(0, 0, (GameData.ARENA_Z_MAX + GameData.ARENA_Z_MIN) * 0.5 - 4.0)
	grass.material_override = _checker_material(Color(0.3, 0.52, 0.22), Color(0.27, 0.48, 0.2), 4.0)
	world.add_child(grass)
	# beach strip
	var sand := MeshInstance3D.new()
	var sm := PlaneMesh.new()
	sm.size = Vector2(x0 * 2.0 + 60.0, 12.0)
	sand.mesh = sm
	sand.position = Vector3(0, 0.01, GameData.ARENA_Z_MAX + 2.0)
	sand.material_override = _checker_material(Color(0.93, 0.85, 0.62), Color(0.9, 0.82, 0.58), 3.0)
	world.add_child(sand)
	# Mediterranean sea
	var sea := MeshInstance3D.new()
	var wm := PlaneMesh.new()
	wm.size = Vector2(x0 * 2.0 + 120.0, 80.0)
	sea.mesh = wm
	sea.position = Vector3(0, -0.15, GameData.ARENA_Z_MAX + 48.0)
	sea.material_override = _water_material()
	world.add_child(sea)
	# outer ground so camera never sees the void
	var outer := MeshInstance3D.new()
	var om := PlaneMesh.new()
	om.size = Vector2(400, 400)
	outer.mesh = om
	outer.position = Vector3(0, -0.3, -120)
	outer.material_override = MF.mat(Color(0.33, 0.55, 0.27))
	world.add_child(outer)
	# paths: a cross of paving through the park
	MF.box(world, Vector3(4.0, 0.04, GameData.ARENA_Z_MAX - GameData.ARENA_Z_MIN), Color(0.62, 0.56, 0.48), Vector3(0, 0.02, (GameData.ARENA_Z_MAX + GameData.ARENA_Z_MIN) * 0.5), false)
	MF.box(world, Vector3(GameData.ARENA_X * 2.0, 0.04, 4.0), Color(0.62, 0.56, 0.48), Vector3(0, 0.02, -10), false)
	# fountain at the crossing
	MF.cyl(world, 3.0, 3.2, 0.6, Color(0.85, 0.85, 0.82), Vector3(0, 0.3, -10))
	MF.cyl(world, 2.6, 2.6, 0.05, Color(0.35, 0.7, 0.95), Vector3(0, 0.62, -10), false)
	MF.cyl(world, 0.3, 0.4, 1.6, Color(0.85, 0.85, 0.82), Vector3(0, 1.2, -10))
	# northern edge: white houses with terracotta roofs
	var x := -GameData.ARENA_X - 4.0
	while x < GameData.ARENA_X + 4.0:
		var w := randf_range(5.0, 8.0)
		var h := randf_range(4.0, 8.0)
		var zc := GameData.ARENA_Z_MIN - 6.0 + randf_range(-1.0, 1.0)
		MF.box(world, Vector3(w, h, 6.0), Color(0.96, 0.94, 0.9), Vector3(x + w * 0.5, h * 0.5, zc))
		MF.inst(MF.prism_mesh(Vector3(w + 0.4, 1.8, 6.4)), MF.mat(Color(0.8, 0.38, 0.22)), world, Vector3(x + w * 0.5, h + 0.9, zc))
		for wi in int(w / 2.0):
			MF.box(world, Vector3(0.8, 1.0, 0.05), Color(0.3, 0.55, 0.75), Vector3(x + 1.2 + wi * 2.0, h * 0.6, zc + 3.03), false)
		x += w + randf_range(0.5, 1.5)
	# east / west: rows of pines
	for side in [-1.0, 1.0]:
		var z := GameData.ARENA_Z_MIN
		while z < GameData.ARENA_Z_MAX:
			_pine(world, Vector3(side * (GameData.ARENA_X + randf_range(3.0, 6.0)), 0, z))
			z += randf_range(3.0, 5.0)
	# palms along the beach
	var px := -GameData.ARENA_X
	while px < GameData.ARENA_X:
		var pp := Vector3(px, 0, GameData.ARENA_Z_MAX - 2.0 + randf_range(-1.0, 1.0))
		px += randf_range(6.0, 10.0)
		if clear != Vector3.INF and Vector2(pp.x - clear.x, pp.z - clear.z).length() < clear_r * 0.6:
			continue
		_palm(world, pp)
	# scattered park props
	for i in 70:
		var p := Vector3(randf_range(-GameData.ARENA_X, GameData.ARENA_X), 0, randf_range(GameData.ARENA_Z_MIN, GameData.ARENA_Z_MAX - 6.0))
		if absf(p.x) < 4.0 or absf(p.z + 10.0) < 4.0:
			continue
		if clear != Vector3.INF and Vector2(p.x - clear.x, p.z - clear.z).length() < clear_r:
			continue
		match i % 5:
			0, 1:
				_palm(world, p)
			2:
				_tree(world, p)
			3:
				_bench(world, p)
			4:
				_flowers(world, p)


static func _pine(parent: Node3D, p: Vector3) -> void:
	MF.cyl(parent, 0.18, 0.25, 1.2, Color(0.45, 0.3, 0.18), p + Vector3(0, 0.6, 0))
	MF.cyl(parent, 0.0, 1.4, 2.4, Color(0.15, 0.42, 0.22), p + Vector3(0, 2.2, 0))
	MF.cyl(parent, 0.0, 1.0, 1.8, Color(0.18, 0.48, 0.25), p + Vector3(0, 3.3, 0))


static func _palm(parent: Node3D, p: Vector3) -> void:
	var trunk := MF.cyl(parent, 0.14, 0.24, 4.0, Color(0.6, 0.45, 0.28), p + Vector3(0, 2.0, 0))
	trunk.rotation.z = randf_range(-0.12, 0.12)
	var top := p + Vector3(-sin(trunk.rotation.z) * 2.0, 4.0, 0)
	for k in 6:
		var leaf := MF.box(parent, Vector3(0.5, 0.06, 2.0), Color(0.2, 0.6, 0.25), top, true)
		leaf.rotation = Vector3(0.45, float(k) / 6.0 * TAU, 0)
		leaf.position += Vector3(sin(leaf.rotation.y), -0.3, cos(leaf.rotation.y)) * 0.8
	MF.sphere(parent, 0.18, Color(0.45, 0.32, 0.15), top + Vector3(0.15, -0.2, 0), false)


static func _tree(parent: Node3D, p: Vector3) -> void:
	MF.cyl(parent, 0.2, 0.28, 1.6, Color(0.45, 0.3, 0.18), p + Vector3(0, 0.8, 0))
	MF.sphere(parent, 1.2, Color(0.3, 0.58, 0.25), p + Vector3(0, 2.3, 0))
	MF.sphere(parent, 0.8, Color(0.35, 0.65, 0.28), p + Vector3(0.6, 2.9, 0.2))


static func _bench(parent: Node3D, p: Vector3) -> void:
	var b := Node3D.new()
	parent.add_child(b)
	b.position = p
	b.rotation.y = randf() * TAU
	MF.box(b, Vector3(1.8, 0.1, 0.5), Color(0.6, 0.4, 0.22), Vector3(0, 0.5, 0))
	MF.box(b, Vector3(1.8, 0.4, 0.08), Color(0.6, 0.4, 0.22), Vector3(0, 0.8, -0.24))
	MF.box(b, Vector3(0.1, 0.5, 0.4), Color(0.2, 0.2, 0.22), Vector3(-0.8, 0.25, 0))
	MF.box(b, Vector3(0.1, 0.5, 0.4), Color(0.2, 0.2, 0.22), Vector3(0.8, 0.25, 0))


static func _flowers(parent: Node3D, p: Vector3) -> void:
	MF.cyl(parent, 1.2, 1.3, 0.3, Color(0.5, 0.35, 0.2), p + Vector3(0, 0.15, 0))
	var cols := [Color(0.95, 0.3, 0.4), Color(1, 0.85, 0.2), Color(0.7, 0.4, 0.95), Color(1, 1, 1)]
	for k in 6:
		var a := float(k) / 6.0 * TAU
		MF.sphere(parent, 0.22, cols[k % cols.size()], p + Vector3(cos(a) * 0.7, 0.45, sin(a) * 0.7), false)


static func _checker_material(a: Color, b: Color, tile: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform vec4 color_a : source_color;
uniform vec4 color_b : source_color;
uniform float tile = 4.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 c = floor(wpos.xz / tile);
	float k = mod(c.x + c.y, 2.0);
	float n = fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
	ALBEDO = mix(color_a.rgb, color_b.rgb, k) * (0.96 + n * 0.08);
	ROUGHNESS = 1.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("color_a", a)
	m.set_shader_parameter("color_b", b)
	m.set_shader_parameter("tile", tile)
	return m


static func _water_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float w1 = sin(wpos.x * 0.45 + TIME * 1.4) * 0.5 + 0.5;
	float w2 = sin(wpos.z * 0.6 - TIME * 1.1 + wpos.x * 0.2) * 0.5 + 0.5;
	vec3 deep = vec3(0.05, 0.38, 0.62);
	vec3 shallow = vec3(0.2, 0.7, 0.85);
	float shore = clamp(1.0 - (wpos.z - 64.0) / 12.0, 0.0, 1.0);
	vec3 col = mix(deep, shallow, shore * 0.7 + w1 * w2 * 0.25);
	col += vec3(0.6) * step(0.97, w1 * w2) * 0.4;
	ALBEDO = col;
	ROUGHNESS = 0.15;
	SPECULAR = 0.7;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
