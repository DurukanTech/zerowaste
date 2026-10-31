extends RefCounted
## Builds the Antalya coastal park shared by the run and the menu backdrop.
## Static props are merged per 40 m chunk (one draw call each, still
## frustum-culled); grass tufts are a single MultiMesh.

const MF = preload("res://scripts/mesh_factory.gd")
const ModelBuilder = preload("res://scripts/model_builder.gd")
const Spinner = preload("res://scripts/spinner.gd")

const CHUNK := 40.0
const PATH_COLOR := Color(0.7, 0.64, 0.55)

const GRASS_SHADER := """
shader_type spatial;
uniform vec4 lush : source_color;
uniform vec4 deep : source_color;
uniform vec4 dry : source_color;
varying vec3 wpos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = noise(wpos.xz * 0.07) * 0.55 + noise(wpos.xz * 0.3) * 0.3 + noise(wpos.xz * 2.1) * 0.15;
	vec3 col = mix(deep.rgb, lush.rgb, n);
	col = mix(col, dry.rgb, smoothstep(0.62, 0.85, noise(wpos.xz * 0.045 + 13.0)) * 0.7);
	col *= 0.94 + step(0.5, fract(wpos.x / 7.0)) * 0.07;
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
"""

const PAVING_SHADER := """
shader_type spatial;
uniform vec4 stone : source_color;
uniform vec4 grout : source_color;
varying vec3 wpos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz / vec2(0.9, 0.6);
	p.x += step(1.0, mod(floor(p.y), 2.0)) * 0.5;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x) * 0.9, min(f.y, 1.0 - f.y) * 0.6);
	float g = smoothstep(0.02, 0.05, edge);
	vec3 col = stone.rgb * (0.88 + hash(cell) * 0.2);
	ALBEDO = mix(grout.rgb, col, g);
	ROUGHNESS = 0.85;
}
"""

const SAND_SHADER := """
shader_type spatial;
uniform vec4 sand : source_color;
uniform vec4 wet : source_color;
varying vec3 wpos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float ripple = sin(wpos.z * 3.0 + sin(wpos.x * 0.4) * 2.0) * 0.5 + 0.5;
	float grain = hash(floor(wpos.xz * 8.0));
	vec3 col = sand.rgb * (0.95 + ripple * 0.05 + grain * 0.04);
	col = mix(col, wet.rgb, smoothstep(62.0, 66.0, wpos.z));
	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.4, smoothstep(62.0, 66.0, wpos.z));
}
"""

const WATER_SHADER := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float w1 = sin(wpos.x * 0.45 + TIME * 1.4) * 0.5 + 0.5;
	float w2 = sin(wpos.z * 0.6 - TIME * 1.1 + wpos.x * 0.2) * 0.5 + 0.5;
	float w3 = sin((wpos.x + wpos.z) * 1.3 + TIME * 2.3) * 0.5 + 0.5;
	vec3 deep = vec3(0.03, 0.3, 0.55);
	vec3 shallow = vec3(0.15, 0.68, 0.8);
	float shore = clamp(1.0 - (wpos.z - 66.0) / 14.0, 0.0, 1.0);
	vec3 col = mix(deep, shallow, shore * 0.8 + w1 * w2 * 0.2);
	// foam line that laps against the beach
	float foam_z = 66.3 + sin(TIME * 0.9 + wpos.x * 0.15) * 0.6;
	float foam = smoothstep(1.2, 0.0, abs(wpos.z - foam_z)) * (0.6 + w3 * 0.4);
	col = mix(col, vec3(0.95), foam * 0.8);
	col += vec3(1.0) * step(0.985, w1 * w2 * w3 + 0.2) * 0.35;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = col + fres * 0.2;
	ROUGHNESS = 0.08;
	SPECULAR = 0.8;
}
"""


static func setup_environment(parent: Node3D, golden := false) -> Environment:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.7, 0.85)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	# bloom on emissive gems, beams, eyes and sparks
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.06
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_energy = 0.95
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.shadow_opacity = 0.8
	# one shadow split: half the shadow draw calls of PARALLEL_2_SPLITS
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 40.0
	# cool sky fill from the opposite side so shadowed faces are not flat
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, 140, 0)
	fill.light_energy = 0.25
	fill.light_color = Color(0.55, 0.7, 1.0)
	if golden:
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.32, 0.45, 0.72)
		sky_mat.sky_horizon_color = Color(1.0, 0.68, 0.45)
		sky_mat.ground_horizon_color = Color(1.0, 0.68, 0.45)
		sky_mat.ground_bottom_color = Color(0.2, 0.25, 0.3)
		var sky := Sky.new()
		sky.sky_material = sky_mat
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_color = Color(0.85, 0.72, 0.75)
		env.ambient_light_energy = 0.32
		env.fog_enabled = true
		env.fog_light_color = Color(0.85, 0.6, 0.45)
		env.fog_density = 0.0025
		# low sun over the sea (south-west), light travelling inland
		sun.rotation_degrees = Vector3(-22, 25, 0)
		sun.light_color = Color(1.0, 0.78, 0.55)
		sun.light_energy = 0.85
		sun.directional_shadow_max_distance = 60.0
		fill.light_color = Color(0.5, 0.55, 0.95)
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.55, 0.78, 0.95)
	we.environment = env
	parent.add_child(we)
	parent.add_child(sun)
	parent.add_child(fill)
	return env


static func build_arena(parent: Node3D, clear := Vector3.INF, clear_r := 0.0) -> void:
	var world := Node3D.new()
	world.name = "World"
	parent.add_child(world)
	var ax := GameData.ARENA_X
	var zmin := GameData.ARENA_Z_MIN
	var zmax := GameData.ARENA_Z_MAX
	var x0 := ax + 6.0
	var zc := (zmax + zmin) * 0.5

	_plane(world, Vector2(x0 * 2.0, zmax - zmin + 12.0), Vector3(0, 0, zc - 4.0),
		_shader_mat(GRASS_SHADER, {"lush": Color(0.3, 0.5, 0.2), "deep": Color(0.17, 0.34, 0.13), "dry": Color(0.46, 0.48, 0.24)}))
	_plane(world, Vector2(x0 * 2.0 + 60.0, 12.0), Vector3(0, 0.01, zmax + 2.0),
		_shader_mat(SAND_SHADER, {"sand": Color(0.94, 0.85, 0.62), "wet": Color(0.72, 0.62, 0.45)}))
	_plane(world, Vector2(x0 * 2.0 + 160.0, 90.0), Vector3(0, -0.15, zmax + 53.0), _shader_mat(WATER_SHADER, {}))
	_plane(world, Vector2(420, 420), Vector3(0, -0.3, -130), MF.mat(Color(0.25, 0.45, 0.2)))
	var paving := _shader_mat(PAVING_SHADER, {"stone": PATH_COLOR, "grout": Color(0.45, 0.4, 0.35)})
	_plane(world, Vector2(4.0, zmax - zmin), Vector3(0, 0.02, zc), paving)
	_plane(world, Vector2(ax * 2.0, 4.0), Vector3(0, 0.025, -10), paving)
	_plane(world, Vector2(14.0, 14.0), Vector3(0, 0.03, -10), paving)

	var chunks := {}
	var glow := ModelBuilder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026

	_fountain(_at(chunks, Vector3(0, 0, -10)), Vector3(0, 0, -10))
	# northern edge: whitewashed houses, terracotta roofs, many with solar panels
	var x := -ax - 4.0
	while x < ax + 4.0:
		var w := rng.randf_range(5.0, 8.0)
		var h := rng.randf_range(4.0, 8.5)
		var p := Vector3(x + w * 0.5, 0, zmin - 6.0 + rng.randf_range(-1.0, 1.0))
		_house(_at(chunks, p), p, w, h, rng)
		x += w + rng.randf_range(0.5, 1.5)
	# east / west: rows of pines
	for side in [-1.0, 1.0]:
		var z := zmin
		while z < zmax:
			var p := Vector3(side * (ax + rng.randf_range(3.0, 6.5)), 0, z)
			_pine(_at(chunks, p), p, rng)
			z += rng.randf_range(2.5, 4.5)
	# beach: palms, parasols, loungers; boats out at sea
	var px := -ax
	while px < ax:
		var p := Vector3(px, 0, zmax - 2.0 + rng.randf_range(-1.0, 1.0))
		px += rng.randf_range(6.0, 10.0)
		if _cleared(p, clear, clear_r * 0.6):
			continue
		_palm(_at(chunks, p), p, rng)
	for i in 12:
		var p := Vector3(rng.randf_range(-ax, ax), 0, zmax + rng.randf_range(2.5, 6.0))
		if _cleared(p, clear, clear_r * 0.6):
			continue
		_parasol(_at(chunks, p), p, rng)
	for i in 4:
		var p := Vector3(rng.randf_range(-60, 60), 0, zmax + rng.randf_range(20.0, 45.0))
		_boat(_at(chunks, p), p, rng)
	# street lamps along both paths
	var lz := zmin + 6.0
	while lz < zmax - 4.0:
		for sx in [-1.0, 1.0]:
			var p := Vector3(sx * 2.8, 0, lz)
			if absf(lz + 10.0) > 8.0:
				_lamp(_at(chunks, p), glow, p)
		lz += 14.0
	var lx := -ax + 6.0
	while lx < ax:
		if absf(lx) > 8.0:
			var p := Vector3(lx, 0, -12.8)
			_lamp(_at(chunks, p), glow, p)
		lx += 14.0
	# scattered park props
	for i in 80:
		var p := Vector3(rng.randf_range(-ax, ax), 0, rng.randf_range(zmin, zmax - 6.0))
		if absf(p.x) < 4.5 or absf(p.z + 10.0) < 5.0 or _cleared(p, clear, clear_r):
			continue
		match i % 6:
			0, 1:
				_palm(_at(chunks, p), p, rng)
			2, 3:
				_tree(_at(chunks, p), p, rng)
			4:
				_bench(_at(chunks, p), p, rng)
			5:
				_flowers(_at(chunks, p), p, rng)

	var mat := MF.vc_mat()
	for k in chunks:
		MF.inst(chunks[k].commit(), mat, world)
	MF.inst(glow.commit(), MF.vc_mat(false, 3.0), world, Vector3.ZERO, false)
	_grass(world, rng, clear, clear_r)
	_wind_farm(world)


static func _cleared(p: Vector3, clear: Vector3, r: float) -> bool:
	return clear != Vector3.INF and Vector2(p.x - clear.x, p.z - clear.z).length() < r


static func _at(chunks: Dictionary, p: Vector3) -> ModelBuilder:
	var k := Vector2i(floori(p.x / CHUNK), floori(p.z / CHUNK))
	if not chunks.has(k):
		chunks[k] = ModelBuilder.new()
	return chunks[k]


static func _plane(parent: Node3D, size: Vector2, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


static func _shader_mat(code: String, params: Dictionary) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


# --- props (all merged into chunk meshes) ------------------------------------

static func _fountain(mb, p: Vector3) -> void:
	var stone := Color(0.88, 0.86, 0.8)
	mb.cyl(3.0, 3.2, 0.6, stone, p + Vector3(0, 0.3, 0), Vector3.ZERO, 24)
	mb.cyl(2.65, 2.65, 0.05, Color(0.3, 0.65, 0.92), p + Vector3(0, 0.6, 0), Vector3.ZERO, 24)
	mb.cyl(0.35, 0.5, 1.6, stone, p + Vector3(0, 1.2, 0))
	mb.cyl(1.0, 0.8, 0.25, stone, p + Vector3(0, 2.0, 0))
	mb.sphere(0.35, Color(0.6, 0.85, 1.0), p + Vector3(0, 2.35, 0), Vector3(1, 1.4, 1))


static func _house(mb, p: Vector3, w: float, h: float, rng: RandomNumberGenerator) -> void:
	var wall: Color = [Color(0.97, 0.95, 0.9), Color(0.98, 0.92, 0.8), Color(0.95, 0.9, 0.86)][rng.randi() % 3]
	mb.box(Vector3(w, h, 6.0), wall, p + Vector3(0, h * 0.5, 0))
	mb.box(Vector3(w + 0.1, 0.3, 6.1), wall.darkened(0.12), p + Vector3(0, 0.15, 0))
	mb.prism(Vector3(w + 0.5, 1.8, 6.5), Color(0.82, 0.38, 0.22), p + Vector3(0, h + 0.9, 0))
	var front := p.z + 3.02
	var cols := int(w / 2.0)
	for row in int(h / 2.6):
		for c in cols:
			var wp := Vector3(p.x - w * 0.5 + 1.2 + c * 2.0, 1.8 + row * 2.4, front)
			mb.box(Vector3(0.95, 1.15, 0.05), Color(0.95, 0.95, 0.92), wp)
			mb.box(Vector3(0.75, 0.95, 0.06), Color(0.25, 0.48, 0.68), wp)
			if rng.randf() < 0.4:
				# green wooden shutters
				mb.box(Vector3(0.35, 1.0, 0.07), Color(0.2, 0.5, 0.35), wp + Vector3(-0.58, 0, 0))
				mb.box(Vector3(0.35, 1.0, 0.07), Color(0.2, 0.5, 0.35), wp + Vector3(0.58, 0, 0))
	mb.box(Vector3(1.1, 2.0, 0.08), Color(0.45, 0.28, 0.16), Vector3(p.x + w * 0.5 - 1.2, 1.0, front))
	if h > 6.0:
		mb.box(Vector3(2.0, 0.12, 0.8), wall.darkened(0.1), Vector3(p.x, 4.0, front + 0.4))
		mb.box(Vector3(2.0, 0.5, 0.05), Color(0.3, 0.3, 0.32), Vector3(p.x, 4.3, front + 0.78))
	if rng.randf() < 0.6:
		# rooftop solar panels on the sea-facing slope
		var n := int((w - 1.0) / 1.4)
		for i in n:
			var sp := Vector3(p.x - (n - 1) * 0.7 + i * 1.4, h + 0.75, p.z + 1.6)
			mb.box(Vector3(1.25, 0.06, 1.8), Color(0.1, 0.16, 0.35), sp, Vector3(0.55, 0, 0))
			mb.box(Vector3(1.27, 0.065, 0.04), Color(0.75, 0.78, 0.82), sp + Vector3(0, 0.0, 0), Vector3(0.55, 0, 0))
	if rng.randf() < 0.5:
		mb.cyl(0.5, 0.5, 0.9, Color(0.85, 0.85, 0.88), Vector3(p.x - w * 0.25, h + 1.5, p.z - 1.5))


static func _pine(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	var s := rng.randf_range(0.85, 1.3)
	mb.cyl(0.18 * s, 0.26 * s, 1.4 * s, Color(0.45, 0.3, 0.18), p + Vector3(0, 0.7 * s, 0), Vector3.ZERO, 8)
	var greens := [Color(0.12, 0.38, 0.2), Color(0.15, 0.45, 0.24), Color(0.18, 0.5, 0.27)]
	for i in 3:
		mb.cyl(0.0, (1.5 - i * 0.35) * s, 1.9 * s, greens[i], p + Vector3(0, (2.0 + i * 1.05) * s, 0), Vector3.ZERO, 9)


static func _palm(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	var lean := Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
	var top := p
	var segs := 6
	for i in segs:
		var t := float(i) / segs
		var a := p + Vector3(0, i * 0.7, 0) + lean * t * t
		var b := p + Vector3(0, (i + 1) * 0.7, 0) + lean * (t + 1.0 / segs) * (t + 1.0 / segs)
		var mid := (a + b) * 0.5
		var dir := (b - a).normalized()
		var rot := Vector3(atan2(dir.z, dir.y), 0, -atan2(dir.x, dir.y))
		var r := 0.24 - t * 0.1
		mb.cyl(r * 0.9, r, 0.72, Color(0.62, 0.47, 0.3) if i % 2 == 0 else Color(0.55, 0.4, 0.25), mid, rot, 8)
		top = b
	var yaw0 := rng.randf() * TAU
	for k in 8:
		var yaw := yaw0 + float(k) / 8.0 * TAU
		var d := Vector3(sin(yaw), 0, cos(yaw))
		var c := Color(0.2, 0.58, 0.24) if k % 2 == 0 else Color(0.26, 0.66, 0.28)
		mb.box(Vector3(0.55, 0.05, 1.3), c, top + d * 0.65 + Vector3(0, 0.12, 0), Vector3(-0.35, yaw, 0))
		mb.box(Vector3(0.42, 0.05, 1.1), c.darkened(0.08), top + d * 1.6 + Vector3(0, -0.25, 0), Vector3(0.45, yaw, 0))
	for k in 3:
		var a := float(k) / 3.0 * TAU
		mb.sphere(0.16, Color(0.42, 0.3, 0.14), top + Vector3(cos(a) * 0.18, -0.2, sin(a) * 0.18), Vector3.ONE, Vector3.ZERO, 0)


static func _tree(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	var s := rng.randf_range(0.85, 1.25)
	mb.cyl(0.18 * s, 0.28 * s, 1.8 * s, Color(0.45, 0.3, 0.18), p + Vector3(0, 0.9 * s, 0), Vector3.ZERO, 8)
	var greens := [Color(0.28, 0.56, 0.22), Color(0.34, 0.63, 0.26), Color(0.24, 0.5, 0.2)]
	mb.sphere(1.25 * s, greens[0], p + Vector3(0, 2.5 * s, 0))
	mb.sphere(0.85 * s, greens[1], p + Vector3(0.65, 3.05, 0.25) * s)
	mb.sphere(0.8 * s, greens[2], p + Vector3(-0.6, 2.9, -0.3) * s)
	if rng.randf() < 0.5:
		# orange tree, a nod to Antalya
		for i in 5:
			var a := rng.randf() * TAU
			mb.sphere(0.12, Color(1.0, 0.55, 0.1), p + Vector3(cos(a) * 1.1, 2.3 + rng.randf() * 0.8, sin(a) * 1.1) * s, Vector3.ONE, Vector3.ZERO, 0)


static func _bench(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	var yaw := rng.randf() * TAU
	var b := Basis(Vector3.UP, yaw)
	var wood := Color(0.62, 0.42, 0.24)
	var iron := Color(0.18, 0.2, 0.22)
	for i in 3:
		mb.box(Vector3(1.9, 0.06, 0.15), wood, p + b * Vector3(0, 0.5, -0.17 + i * 0.17), Vector3(0, yaw, 0))
	for i in 2:
		mb.box(Vector3(1.9, 0.14, 0.05), wood, p + b * Vector3(0, 0.75 + i * 0.2, -0.3), Vector3(0, yaw, 0))
	for sx in [-0.8, 0.8]:
		mb.box(Vector3(0.08, 0.5, 0.45), iron, p + b * Vector3(sx, 0.25, -0.05), Vector3(0, yaw, 0))
		mb.box(Vector3(0.06, 0.5, 0.06), iron, p + b * Vector3(sx, 0.85, -0.32), Vector3(0, yaw, 0))


static func _flowers(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	mb.cyl(1.25, 1.3, 0.3, Color(0.9, 0.88, 0.82), p + Vector3(0, 0.15, 0), Vector3.ZERO, 16)
	mb.cyl(1.12, 1.12, 0.06, Color(0.35, 0.24, 0.15), p + Vector3(0, 0.31, 0), Vector3.ZERO, 16)
	var cols := [Color(0.95, 0.3, 0.4), Color(1, 0.85, 0.2), Color(0.7, 0.4, 0.95), Color(1, 1, 1), Color(1.0, 0.5, 0.2)]
	for k in 14:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.1, 0.95)
		var fp := p + Vector3(cos(a) * r, 0.42, sin(a) * r)
		mb.cyl(0.015, 0.015, 0.2, Color(0.2, 0.5, 0.2), fp + Vector3(0, -0.05, 0), Vector3.ZERO, 4)
		mb.sphere(0.11, cols[k % cols.size()], fp + Vector3(0, 0.07, 0), Vector3(1, 0.6, 1), Vector3.ZERO, 0)


static func _lamp(mb, glow, p: Vector3) -> void:
	var iron := Color(0.15, 0.17, 0.2)
	mb.cyl(0.18, 0.22, 0.3, iron, p + Vector3(0, 0.15, 0), Vector3.ZERO, 8)
	mb.cyl(0.07, 0.09, 3.4, iron, p + Vector3(0, 1.85, 0), Vector3.ZERO, 8)
	mb.cyl(0.32, 0.1, 0.25, iron, p + Vector3(0, 3.7, 0), Vector3.ZERO, 8)
	glow.sphere(0.2, Color(1.0, 0.85, 0.55), p + Vector3(0, 3.45, 0), Vector3(1, 0.9, 1), Vector3.ZERO, 0)


static func _parasol(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	var cols := [Color(0.95, 0.3, 0.25), Color(0.2, 0.55, 0.9), Color(1.0, 0.8, 0.2), Color(0.25, 0.7, 0.45)]
	var c: Color = cols[rng.randi() % cols.size()]
	mb.cyl(0.04, 0.04, 2.3, Color(0.9, 0.9, 0.9), p + Vector3(0, 1.15, 0), Vector3.ZERO, 6)
	mb.cyl(0.05, 1.3, 0.45, c, p + Vector3(0, 2.4, 0), Vector3.ZERO, 8)
	mb.cyl(1.32, 1.32, 0.06, Color(0.97, 0.97, 0.95), p + Vector3(0, 2.18, 0), Vector3.ZERO, 8)
	var yaw := rng.randf() * TAU
	var b := Basis(Vector3.UP, yaw)
	mb.box(Vector3(0.7, 0.08, 1.8), Color(0.98, 0.98, 0.96), p + b * Vector3(1.2, 0.35, 0), Vector3(0, yaw, 0))
	mb.box(Vector3(0.7, 0.08, 0.6), Color(0.98, 0.98, 0.96), p + b * Vector3(1.2, 0.55, -0.85), Vector3(0.7, yaw, 0))
	mb.box(Vector3(0.6, 0.3, 0.4), c.darkened(0.2), p + b * Vector3(1.2, 0.15, 0.6), Vector3(0, yaw, 0))


static func _boat(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	var yaw := rng.randf_range(-0.6, 0.6) + PI * 0.5
	var b := Basis(Vector3.UP, yaw)
	mb.box(Vector3(4.5, 0.7, 1.6), Color(0.97, 0.97, 0.95), p + Vector3(0, 0.15, 0), Vector3(0, yaw, 0))
	mb.box(Vector3(4.55, 0.18, 1.62), Color(0.15, 0.4, 0.75), p + Vector3(0, 0.45, 0), Vector3(0, yaw, 0))
	mb.prism(Vector3(1.6, 1.0, 0.7), Color(0.97, 0.97, 0.95), p + b * Vector3(2.6, 0.15, 0), Vector3(0, yaw, -PI * 0.5))
	mb.cyl(0.06, 0.06, 4.5, Color(0.6, 0.45, 0.3), p + Vector3(0, 2.6, 0), Vector3.ZERO, 6)
	mb.prism(Vector3(2.4, 3.6, 0.05), Color(0.98, 0.96, 0.9), p + b * Vector3(-0.8, 2.6, 0), Vector3(0, yaw, 0))


static func _grass(parent: Node3D, rng: RandomNumberGenerator, clear: Vector3, clear_r: float) -> void:
	var mb := ModelBuilder.new()
	for k in 5:
		var a := float(k) / 5.0 * TAU
		var tilt := Vector3(0.35, a, 0)
		mb.prism(Vector3(0.09, 0.45 + (k % 2) * 0.15, 0.02), Color(0.42, 0.68, 0.26), Vector3(sin(a) * 0.05, 0.22, cos(a) * 0.05), tilt)
	var count := 4500
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mb.commit()
	mm.instance_count = count
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 3:
		tries += 1
		var p := Vector3(rng.randf_range(-GameData.ARENA_X - 4.0, GameData.ARENA_X + 4.0), 0, rng.randf_range(GameData.ARENA_Z_MIN - 3.0, GameData.ARENA_Z_MAX - 4.0))
		if absf(p.x) < 2.3 or absf(p.z + 10.0) < 2.3 or Vector2(p.x, p.z + 10.0).length() < 7.5:
			continue
		var s := rng.randf_range(0.7, 1.4)
		var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s)), p)
		mm.set_instance_transform(placed, xf)
		var tint := rng.randf_range(0.75, 1.1)
		mm.set_instance_color(placed, Color(tint, tint * rng.randf_range(0.95, 1.05), tint * 0.9))
		placed += 1
	mm.visible_instance_count = placed
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = MF.vc_mat()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


## Wind turbines on the ridge behind the town, rotors actually spinning.
static func _wind_farm(parent: Node3D) -> void:
	var tower := ModelBuilder.new()
	tower.cyl(0.35, 0.7, 24.0, Color(0.95, 0.96, 0.97), Vector3(0, 12.0, 0), Vector3.ZERO, 10)
	tower.box(Vector3(1.2, 1.1, 2.8), Color(0.92, 0.93, 0.95), Vector3(0, 24.4, -0.2))
	var tower_mesh := tower.commit()
	var rotor := ModelBuilder.new()
	rotor.sphere(0.6, Color(0.92, 0.93, 0.95), Vector3.ZERO, Vector3(1, 1, 1.3))
	for k in 3:
		var a := float(k) / 3.0 * TAU
		var d := Vector3(sin(a), cos(a), 0)
		rotor.box(Vector3(0.6, 9.5, 0.15), Color(0.97, 0.97, 0.98), d * 5.0, Vector3(0, 0, -a))
		rotor.box(Vector3(0.62, 1.0, 0.16), Color(0.9, 0.3, 0.25), d * 9.3, Vector3(0, 0, -a))
	var rotor_mesh := rotor.commit()
	var spots := [Vector3(-55, 0, -100), Vector3(-25, 0, -108), Vector3(10, 0, -102), Vector3(42, 0, -110), Vector3(70, 0, -98)]
	for i in spots.size():
		var t := Node3D.new()
		parent.add_child(t)
		t.position = spots[i]
		t.rotation.y = 0.2
		MF.inst(tower_mesh, MF.vc_mat(), t)
		var r = Spinner.new()
		r.speed = 0.6 + i * 0.07
		r.position = Vector3(0, 24.4, 1.3)
		r.rotation.z = i * 0.7
		t.add_child(r)
		MF.inst(rotor_mesh, MF.vc_mat(), r)
