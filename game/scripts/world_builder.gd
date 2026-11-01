extends RefCounted
## Builds the Antalya coastal park shared by the run and the menu backdrop.
## Static props are merged per 40 m chunk (one draw call each, still
## frustum-culled); grass tufts are a single MultiMesh.

const MF = preload("res://scripts/mesh_factory.gd")
const ModelBuilder = preload("res://scripts/model_builder.gd")
const Spinner = preload("res://scripts/spinner.gd")
const Zones = preload("res://scripts/world_zones.gd")
const Ambient = preload("res://scripts/ambient.gd")

const CHUNK := 40.0
const PATH_COLOR := Color(0.7, 0.64, 0.55)

## Shared GLSL helpers: value noise and drifting cloud shadows.
const LIB := """
varying vec3 wpos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
// round dots on a jittered grid: 1 inside a dot, 0 elsewhere
float dots(vec2 p, float density, float size) {
	vec2 c = floor(p);
	vec2 o = vec2(hash(c + 3.1), hash(c + 7.7)) * 0.6 + 0.2;
	return step(1.0 - density, hash(c)) * smoothstep(size, size * 0.6, length(fract(p) - o));
}
float clouds(vec2 p) {
	vec2 q = p * 0.016 + vec2(TIME * 0.011, TIME * 0.005);
	float n = noise(q) * 0.6 + noise(q * 2.3 + 5.0) * 0.4;
	return smoothstep(0.5, 0.72, n);
}
"""

## Park lawn: layered tones, clover, tiny flowers, worn dirt/gravel paths
## (segments passed as uniforms) and cloud shadows.
const GRASS_SHADER := """
shader_type spatial;
uniform vec4 lush : source_color;
uniform vec4 deep : source_color;
uniform vec4 dry : source_color;
uniform vec4 dirt : source_color;
uniform vec4 gravel : source_color;
uniform vec4 segs[32];
uniform int seg_count = 0;
uniform float path_w = 1.3;
""" + LIB + """
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float seg_d(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a; vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}
void fragment() {
	vec2 p = wpos.xz;
	float n = noise(p * 0.07) * 0.55 + noise(p * 0.3) * 0.3 + noise(p * 2.1) * 0.15;
	vec3 col = mix(deep.rgb, lush.rgb, n);
	col = mix(col, dry.rgb, smoothstep(0.62, 0.85, noise(p * 0.045 + 13.0)) * 0.55);
	// darker clover clumps and blade texture
	col = mix(col, deep.rgb * 0.85, smoothstep(0.68, 0.8, noise(p * 0.85 + 40.0)) * 0.35);
	col *= 0.93 + noise(p * 9.0) * 0.1;
	// tiny white / yellow flowers
	vec2 fc = floor(p * 2.5);
	if (hash(fc) > 0.982) {
		float r = length(fract(p * 2.5) - 0.5);
		vec3 petal = hash(fc + 7.0) > 0.5 ? vec3(1.0, 0.98, 0.92) : vec3(1.0, 0.82, 0.22);
		col = mix(col, petal, smoothstep(0.2, 0.1, r));
	}
	col *= 0.97 + step(0.5, fract(p.x / 7.0)) * 0.035;
	// dirt and gravel paths with a soft, wobbly worn edge
	float d = 1e5;
	for (int i = 0; i < seg_count; i++) {
		d = min(d, seg_d(p, segs[i].xy, segs[i].zw));
	}
	d += (noise(p * 0.9) - 0.5) * 0.45;
	float on_path = smoothstep(path_w + 0.25, path_w - 0.15, d);
	vec3 pc = dirt.rgb * (0.9 + noise(p * 1.4) * 0.16 + noise(p * 6.0) * 0.06);
	pc = mix(pc, gravel.rgb, dots(p * 6.0, 0.45, 0.28) * 0.6);
	pc = mix(pc, dirt.rgb * 0.7, dots(p * 4.0 + 9.0, 0.25, 0.22) * 0.5);
	float worn = smoothstep(path_w + 1.2, path_w + 0.2, d) * (1.0 - on_path);
	col = mix(col, mix(col, dirt.rgb, 0.45), worn);
	col = mix(col, pc, on_path);
	col *= 1.0 - clouds(p) * 0.17;
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
"""

## Running-bond paving with a lighter curb band at the plane edges.
const PAVING_SHADER := """
shader_type spatial;
uniform vec4 stone : source_color;
uniform vec4 grout : source_color;
uniform vec2 brick = vec2(0.9, 0.6);
""" + LIB + """
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz / brick;
	p.x += step(1.0, mod(floor(p.y), 2.0)) * 0.5;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x) * 0.9, min(f.y, 1.0 - f.y) * 0.6);
	float g = smoothstep(0.02, 0.05, edge);
	vec3 col = stone.rgb * (0.86 + hash(cell) * 0.2) * (0.95 + noise(wpos.xz * 0.4) * 0.08);
	col = mix(grout.rgb, col, g);
	// curb: brighter stone along the outer rim of the paved strip
	vec2 uv = abs(UV - 0.5) * 2.0;
	col = mix(col, vec3(0.86, 0.84, 0.8), step(0.985, max(uv.x, uv.y)));
	col *= 1.0 - clouds(wpos.xz) * 0.17;
	ALBEDO = col;
	ROUGHNESS = 0.85;
}
"""

## Round plaza: concentric stone rings with radial joints, discarded outside.
const PLAZA_SHADER := """
shader_type spatial;
uniform vec4 stone : source_color;
uniform vec4 accent : source_color;
uniform vec4 grout : source_color;
uniform float radius = 13.0;
""" + LIB + """
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 c = (UV - 0.5) * 2.0 * radius;
	float r = length(c);
	if (r > radius) discard;
	float ring = floor(r / 1.1);
	float ang = atan(c.y, c.x);
	float segs = max(6.0, floor(ring * 6.5));
	float a = ang / 6.2832 * segs + ring * 0.5;
	float fr = fract(r / 1.1);
	float fa = fract(a);
	float g = smoothstep(0.02, 0.07, min(min(fr, 1.0 - fr), min(fa, 1.0 - fa) * (r / 6.0 + 0.3)));
	vec3 col = (mod(ring, 4.0) == 1.0 ? accent.rgb : stone.rgb) * (0.88 + hash(vec2(ring, floor(a))) * 0.18);
	col = mix(grout.rgb, col, g);
	col = mix(col, vec3(0.9, 0.88, 0.84), smoothstep(radius - 0.6, radius - 0.45, r));
	col *= 1.0 - clouds(wpos.xz) * 0.17;
	ALBEDO = col;
	ROUGHNESS = 0.85;
}
"""

## Generic textured ground (mulch, rubber, sand-pit): noise + speckle.
const GROUND_SHADER := """
shader_type spatial;
uniform vec4 base : source_color;
uniform vec4 speck : source_color;
uniform float grain = 6.0;
uniform float speck_amt = 0.3;
""" + LIB + """
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz;
	vec3 col = base.rgb * (0.88 + noise(p * 0.6) * 0.2);
	col = mix(col, speck.rgb, dots(p * grain, speck_amt, 0.3) * 0.7);
	col *= 1.0 - clouds(p) * 0.17;
	ALBEDO = col;
	ROUGHNESS = 0.95;
}
"""

## Basketball court: rubber surface with white lines (court is 22 x 13).
const COURT_SHADER := """
shader_type spatial;
uniform vec4 inner : source_color;
uniform vec4 outer : source_color;
""" + LIB + """
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float line(float d, float w) { return smoothstep(w, w * 0.5, abs(d)); }
void fragment() {
	vec2 c = (UV - 0.5) * vec2(22.0, 13.0);
	vec2 a = abs(c);
	bool in_court = a.x < 10.0 && a.y < 5.5;
	vec3 col = in_court ? inner.rgb : outer.rgb;
	col *= 0.93 + noise(wpos.xz * 2.0) * 0.1;
	float l = 0.0;
	l = max(l, line(max(a.x - 10.0, a.y - 5.5), 0.07) * step(max(a.x - 10.0, a.y - 5.5), 0.1));
	l = max(l, line(c.x, 0.07) * step(a.y, 5.5));
	l = max(l, line(length(c) - 1.6, 0.07));
	vec2 k = vec2(10.0 - a.x, c.y);
	l = max(l, line(length(k) - 6.0, 0.07) * step(a.x, 10.0) * step(10.0 - 6.0, a.x));
	l = max(l, line(length(k - vec2(4.6, 0.0)) - 1.6, 0.07) * step(0.0, k.x));
	col = mix(col, vec3(0.97), l);
	col *= 1.0 - clouds(wpos.xz) * 0.17;
	ALBEDO = col;
	ROUGHNESS = 0.8;
}
"""

## Wooden boardwalk planks running along X.
const PLANK_SHADER := """
shader_type spatial;
uniform vec4 wood : source_color;
""" + LIB + """
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz;
	float row = floor(p.y / 0.32);
	float seg = floor((p.x + hash(vec2(row, 3.0)) * 4.0) / 3.2);
	float fy = fract(p.y / 0.32);
	float fx = fract((p.x + hash(vec2(row, 3.0)) * 4.0) / 3.2);
	float gap = smoothstep(0.0, 0.08, min(fy, 1.0 - fy)) * smoothstep(0.0, 0.01, min(fx, 1.0 - fx));
	vec3 col = wood.rgb * (0.82 + hash(vec2(row, seg)) * 0.25) * (0.93 + noise(vec2(p.x * 0.8, p.y * 12.0)) * 0.12);
	col = mix(col * 0.45, col, gap);
	col *= 1.0 - clouds(p) * 0.17;
	ALBEDO = col;
	ROUGHNESS = 0.8;
}
"""

const SAND_SHADER := """
shader_type spatial;
uniform vec4 sand : source_color;
uniform vec4 wet : source_color;
""" + LIB + """
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float ripple = sin(wpos.z * 3.0 + sin(wpos.x * 0.4) * 2.0) * 0.5 + 0.5;
	float grain = hash(floor(wpos.xz * 8.0));
	vec3 col = sand.rgb * (0.94 + ripple * 0.05 + grain * 0.05) * (0.96 + noise(wpos.xz * 0.3) * 0.06);
	// shells and pebbles
	if (hash(floor(wpos.xz * 1.5)) > 0.985) {
		col = mix(col, vec3(0.98, 0.93, 0.88), smoothstep(0.18, 0.1, length(fract(wpos.xz * 1.5) - 0.5)));
	}
	col = mix(col, wet.rgb, smoothstep(62.0, 66.0, wpos.z));
	col *= 1.0 - clouds(wpos.xz) * 0.17;
	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.4, smoothstep(62.0, 66.0, wpos.z));
}
"""

const WATER_SHADER := """
shader_type spatial;
render_mode cull_disabled;
""" + LIB + """
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
	col *= 1.0 - clouds(wpos.xz) * 0.12;
	ALBEDO = col + fres * 0.2;
	ROUGHNESS = 0.08;
	SPECULAR = 0.8;
}
"""

## Pond: an ellipse of calm water with a muddy shore, discarded outside.
const POND_SHADER := """
shader_type spatial;
""" + LIB + """
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 c = (UV - 0.5) * 2.0;
	float wob = (noise(wpos.xz * 0.35) - 0.5) * 0.12;
	float r = length(c) + wob;
	if (r > 1.0) discard;
	float ripple = sin(r * 40.0 - TIME * 1.6) * 0.5 + 0.5;
	vec3 water = mix(vec3(0.12, 0.42, 0.45), vec3(0.2, 0.58, 0.6), smoothstep(0.85, 0.5, r));
	water += vec3(0.08) * ripple * smoothstep(0.4, 0.9, r) * 0.5;
	water += vec3(1.0) * step(0.992, noise(wpos.xz * 3.0 + TIME * 0.3)) * 0.4;
	vec3 shore = vec3(0.38, 0.32, 0.22);
	vec3 col = mix(water, shore, smoothstep(0.9, 0.97, r));
	col *= 1.0 - clouds(wpos.xz) * 0.14;
	ALBEDO = col;
	ROUGHNESS = mix(0.08, 0.9, smoothstep(0.9, 0.97, r));
	SPECULAR = mix(0.8, 0.2, smoothstep(0.9, 0.97, r));
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
	# bloom on emissive gems, beams, eyes and sparks (desktop only: the
	# extra full-screen passes cost too much in the browser)
	env.glow_enabled = not OS.has_feature("web")
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

	var segs := PackedVector4Array()
	for sg in Zones.path_segments():
		segs.append(Vector4(sg[0], sg[1], sg[2], sg[3]))
	_plane(world, Vector2(x0 * 2.0, zmax - zmin + 12.0), Vector3(0, 0, zc - 4.0),
		_shader_mat(GRASS_SHADER, {"lush": Color(0.27, 0.46, 0.19), "deep": Color(0.14, 0.29, 0.12), "dry": Color(0.44, 0.46, 0.24),
			"dirt": Color(0.46, 0.36, 0.25), "gravel": Color(0.66, 0.6, 0.5), "segs": segs, "seg_count": segs.size()}))
	_plane(world, Vector2(x0 * 2.0 + 60.0, 12.0), Vector3(0, 0.01, zmax + 2.0),
		_shader_mat(SAND_SHADER, {"sand": Color(0.94, 0.85, 0.62), "wet": Color(0.72, 0.62, 0.45)}))
	_plane(world, Vector2(x0 * 2.0 + 160.0, 90.0), Vector3(0, -0.15, zmax + 53.0), _shader_mat(WATER_SHADER, {}))
	_plane(world, Vector2(420, 420), Vector3(0, -0.3, -130), MF.mat(Color(0.25, 0.45, 0.2)))
	var paving := _shader_mat(PAVING_SHADER, {"stone": PATH_COLOR, "grout": Color(0.45, 0.4, 0.35)})
	_plane(world, Vector2(4.0, zmax - zmin), Vector3(0, 0.02, zc), paving)
	_plane(world, Vector2(ax * 2.0, 4.0), Vector3(0, 0.025, -10), paving)

	var chunks := {}
	var glow := ModelBuilder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026

	_fountain(_at(chunks, Vector3(0, 0, -10)), Vector3(0, 0, -10))
	# themed zones (garden, market, pond, court, promenade, hedges)
	var at := func(p: Vector3): return _at(chunks, p)
	var ground := func(code: String, params: Dictionary, size: Vector2, pos: Vector3): _plane(world, size, pos, _shader_mat(code, params))
	var shaders := {"plaza": PLAZA_SHADER, "ground": GROUND_SHADER, "paving": PAVING_SHADER, "court": COURT_SHADER, "plank": PLANK_SHADER, "pond": POND_SHADER}
	Zones.build(at, glow, ground, shaders, rng, clear, clear_r)
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
	# scattered park props in the open lawn (zones keep their own furniture)
	for i in 140:
		var p := Vector3(rng.randf_range(-ax, ax), 0, rng.randf_range(zmin, zmax - 8.0))
		if absf(p.x) < 4.5 or absf(p.z + 10.0) < 4.5 or Zones.in_zone(p) or _cleared(p, clear, clear_r):
			continue
		match i % 10:
			0, 1, 2:
				_tree(_at(chunks, p), p, rng)
			3:
				_palm(_at(chunks, p), p, rng)
			4, 5:
				_bush(_at(chunks, p), p, rng)
			6:
				_rock(_at(chunks, p), p, rng)
			7:
				_flowers(_at(chunks, p), p, rng)
			8:
				_bench(_at(chunks, p), p, rng)
			9:
				_bin_can(_at(chunks, p), p)

	var mat := MF.vc_mat()
	for k in chunks:
		MF.inst(chunks[k].commit(), mat, world)
	MF.inst(glow.commit(), MF.vc_mat(false, 3.0), world, Vector3.ZERO, false)
	_grass(world, rng, clear, clear_r)
	_wildflowers(world, rng, clear, clear_r)
	_wind_farm(world)
	world.add_child(Ambient.new())


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


static func _bush(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	var s := rng.randf_range(0.7, 1.2)
	var g := [Color(0.2, 0.45, 0.2), Color(0.26, 0.52, 0.22), Color(0.3, 0.56, 0.26)]
	for k in 4:
		var a := float(k) / 4.0 * TAU + rng.randf()
		mb.sphere(0.55 * s, g[k % 3], p + Vector3(cos(a) * 0.45, 0.45, sin(a) * 0.45) * s, Vector3(1, 0.85, 1))
	if rng.randf() < 0.4:
		for k in 5:
			var a := rng.randf() * TAU
			mb.sphere(0.07, Color(0.95, 0.95, 1.0) if k % 2 == 0 else Color(0.95, 0.4, 0.55), p + Vector3(cos(a) * 0.7, 0.75, sin(a) * 0.7) * s, Vector3.ONE, Vector3.ZERO, 0)


static func _rock(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	var grey := Color(0.55, 0.55, 0.52)
	for k in rng.randi_range(1, 3):
		var s := rng.randf_range(0.35, 0.8)
		var q := p + Vector3(rng.randf_range(-0.6, 0.6), s * 0.25, rng.randf_range(-0.6, 0.6))
		mb.sphere(s, grey.darkened(rng.randf() * 0.25), q, Vector3(1.2, 0.65, 1.0), Vector3(rng.randf(), rng.randf() * TAU, 0), 0)
	mb.sphere(0.25, Color(0.3, 0.5, 0.22), p + Vector3(0.5, 0.05, 0.4), Vector3(1.4, 0.3, 1.0), Vector3.ZERO, 0)


## Park litter bin (a small sorted pair: recycling + general waste).
static func _bin_can(mb, p: Vector3) -> void:
	mb.cyl(0.05, 0.05, 1.0, Color(0.18, 0.2, 0.22), p + Vector3(0, 0.5, 0), Vector3.ZERO, 6)
	mb.cyl(0.26, 0.24, 0.6, Color(0.2, 0.55, 0.3), p + Vector3(-0.28, 0.6, 0), Vector3.ZERO, 10)
	mb.cyl(0.26, 0.24, 0.6, Color(0.35, 0.35, 0.38), p + Vector3(0.28, 0.6, 0), Vector3.ZERO, 10)
	mb.cyl(0.28, 0.28, 0.05, Color(0.15, 0.4, 0.22), p + Vector3(-0.28, 0.92, 0), Vector3.ZERO, 10)
	mb.cyl(0.28, 0.28, 0.05, Color(0.25, 0.25, 0.28), p + Vector3(0.28, 0.92, 0), Vector3.ZERO, 10)


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
	var count := 2200 if OS.has_feature("web") else 4500
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
		if absf(p.x) < 2.3 or absf(p.z + 10.0) < 2.3 or Zones.in_zone(p):
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


## Clusters of tiny wildflowers in the open lawn (one MultiMesh).
static func _wildflowers(parent: Node3D, rng: RandomNumberGenerator, clear: Vector3, clear_r: float) -> void:
	var mb := ModelBuilder.new()
	# low-poly on purpose: there are thousands of these
	mb.box(Vector3(0.02, 0.28, 0.02), Color(0.35, 0.55, 0.25), Vector3(0, 0.14, 0))
	mb.cyl(0.08, 0.06, 0.03, Color(1, 1, 1), Vector3(0, 0.29, 0), Vector3.ZERO, 5)
	mb.box(Vector3(0.04, 0.03, 0.04), Color(1.0, 0.85, 0.3), Vector3(0, 0.31, 0))
	var palette := [Color(1, 1, 1), Color(1.0, 0.85, 0.25), Color(0.75, 0.55, 1.0), Color(1.0, 0.5, 0.6), Color(0.55, 0.75, 1.0)]
	var count := 1200 if OS.has_feature("web") else 2600
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mb.commit()
	mm.instance_count = count
	var placed := 0
	var patches := 0
	while placed < count and patches < 400:
		patches += 1
		var c := Vector3(rng.randf_range(-GameData.ARENA_X, GameData.ARENA_X), 0, rng.randf_range(GameData.ARENA_Z_MIN, GameData.ARENA_Z_MAX - 10.0))
		if absf(c.x) < 4.0 or absf(c.z + 10.0) < 4.0 or Zones.in_zone(c) or _cleared(c, clear, clear_r):
			continue
		var tint: Color = palette[rng.randi() % palette.size()]
		for k in rng.randi_range(25, 60):
			if placed >= count:
				break
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * rng.randf_range(1.5, 3.0)
			var p := c + Vector3(cos(a) * r, 0, sin(a) * r)
			var s := rng.randf_range(0.7, 1.3)
			mm.set_instance_transform(placed, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), p))
			mm.set_instance_color(placed, tint if rng.randf() < 0.8 else palette[rng.randi() % palette.size()])
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
