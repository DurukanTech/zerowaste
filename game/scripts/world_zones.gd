extends RefCounted
## Themed areas of the park, merged into the world builder's chunk meshes:
## community garden (NW), market square (NE), pond (W), sports court and
## playground (E), boardwalk promenade (S) and boundary hedges.

## Zone rectangles: [x0, x1, z0, z1]. Random park props stay out of these.
const GARDEN := [-70.0, -24.0, -72.0, -34.0]
const MARKET := [24.0, 70.0, -72.0, -34.0]
const COURT := [24.0, 70.0, -6.0, 30.0]
const POND_C := Vector3(-46.0, 0.0, 8.0)
const POND_R := Vector2(11.0, 8.0)
const PROMENADE_Z := 50.5
const PLAZA_R := 13.0

const WOOD := Color(0.62, 0.42, 0.24)
const DARK_WOOD := Color(0.45, 0.3, 0.17)
const IRON := Color(0.18, 0.2, 0.22)
const WHITE := Color(0.96, 0.96, 0.94)
const SOIL := Color(0.3, 0.2, 0.12)


## Dirt / gravel path network drawn by the lawn shader: [ax, az, bx, bz].
static func path_segments() -> Array:
	var segs := []
	# a loop around the central park
	var pts := []
	for k in 14:
		var a := float(k) / 14.0 * TAU
		pts.append(Vector2(cos(a) * 52.0 + sin(a * 3.0) * 3.0, -10.0 + sin(a) * 34.0))
	for k in pts.size():
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[(k + 1) % pts.size()]
		segs.append([a.x, a.y, b.x, b.y])
	# spokes from the plaza to every zone
	for target in [Vector2(-40, -44), Vector2(42, -44), Vector2(-36, 4), Vector2(30, 10), Vector2(-22, 38), Vector2(22, 38)]:
		var dir: Vector2 = (target - Vector2(0, -10)).normalized()
		var start: Vector2 = Vector2(0, -10) + dir * (PLAZA_R - 0.5)
		var mid: Vector2 = (start + target) * 0.5 + Vector2(-dir.y, dir.x) * 3.0
		segs.append([start.x, start.y, mid.x, mid.y])
		segs.append([mid.x, mid.y, target.x, target.y])
	# garden walkways between the beds
	segs.append([-66.0, -53.0, -28.0, -53.0])
	segs.append([-47.0, -70.0, -47.0, -36.0])
	return segs


static func in_zone(p: Vector3) -> bool:
	for r in [GARDEN, MARKET, COURT]:
		if p.x > r[0] - 2.0 and p.x < r[1] + 2.0 and p.z > r[2] - 2.0 and p.z < r[3] + 2.0:
			return true
	var d := Vector2((p.x - POND_C.x) / (POND_R.x + 3.0), (p.z - POND_C.z) / (POND_R.y + 3.0))
	if d.length() < 1.0:
		return true
	if absf(p.z - PROMENADE_Z) < 3.0:
		return true
	return Vector2(p.x, p.z + 10.0).length() < PLAZA_R + 1.5


## Builds every zone. `at` maps a position to its chunk ModelBuilder,
## `ground` makes a shaded ground plane (shader, params, size, center).
static func build(at: Callable, glow, ground: Callable, sh: Dictionary, rng: RandomNumberGenerator, clear: Vector3, clear_r: float) -> void:
	_plaza(at, ground, sh)
	_garden(at, ground, sh, rng)
	_market(at, glow, ground, sh, rng)
	_pond(at, ground, sh, rng)
	_court(at, ground, sh, rng)
	_promenade(at, glow, ground, sh, rng, clear, clear_r)
	_hedges(at)


static func _cleared(p: Vector3, clear: Vector3, r: float) -> bool:
	return clear != Vector3.INF and Vector2(p.x - clear.x, p.z - clear.z).length() < r


# --- plaza --------------------------------------------------------------------

static func _plaza(at: Callable, ground: Callable, sh: Dictionary) -> void:
	var c := Vector3(0, 0, -10)
	ground.call(sh.plaza, {"stone": Color(0.82, 0.78, 0.7), "accent": Color(0.72, 0.5, 0.38), "grout": Color(0.5, 0.45, 0.4), "radius": PLAZA_R}, Vector2(PLAZA_R * 2.0, PLAZA_R * 2.0), c + Vector3(0, 0.035, 0))
	for k in 8:
		var a := float(k) / 8.0 * TAU + PI / 8.0
		var p := c + Vector3(cos(a), 0, sin(a)) * (PLAZA_R - 1.6)
		var mb = at.call(p)
		if k % 2 == 0:
			_planter(mb, p)
		else:
			_bench_facing(mb, p, a + PI * 0.5)


static func _planter(mb, p: Vector3) -> void:
	mb.cyl(0.9, 0.75, 0.7, Color(0.85, 0.82, 0.76), p + Vector3(0, 0.35, 0), Vector3.ZERO, 12)
	mb.cyl(0.8, 0.8, 0.05, SOIL, p + Vector3(0, 0.71, 0), Vector3.ZERO, 12)
	mb.sphere(0.65, Color(0.25, 0.55, 0.22), p + Vector3(0, 1.1, 0), Vector3(1, 0.8, 1))
	for k in 5:
		var a := float(k) / 5.0 * TAU
		mb.sphere(0.12, [Color(0.95, 0.3, 0.4), Color(1, 0.8, 0.2), Color(0.8, 0.5, 1.0)][k % 3], p + Vector3(cos(a) * 0.55, 1.25, sin(a) * 0.55), Vector3.ONE, Vector3.ZERO, 0)


static func _bench_facing(mb, p: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	for i in 3:
		mb.box(Vector3(1.9, 0.06, 0.15), WOOD, p + b * Vector3(0, 0.5, -0.17 + i * 0.17), Vector3(0, yaw, 0))
	for i in 2:
		mb.box(Vector3(1.9, 0.14, 0.05), WOOD, p + b * Vector3(0, 0.75 + i * 0.2, -0.3), Vector3(0, yaw, 0))
	for sx in [-0.8, 0.8]:
		mb.box(Vector3(0.08, 0.5, 0.45), IRON, p + b * Vector3(sx, 0.25, -0.05), Vector3(0, yaw, 0))
		mb.box(Vector3(0.06, 0.5, 0.06), IRON, p + b * Vector3(sx, 0.85, -0.32), Vector3(0, yaw, 0))


# --- community garden (NW) ------------------------------------------------------

static func _garden(at: Callable, ground: Callable, sh: Dictionary, rng: RandomNumberGenerator) -> void:
	var r := GARDEN
	var c := Vector3((r[0] + r[1]) * 0.5, 0, (r[2] + r[3]) * 0.5)
	ground.call(sh.ground, {"base": Color(0.34, 0.25, 0.16), "speck": Color(0.52, 0.42, 0.28), "grain": 8.0, "speck_amt": 0.3}, Vector2(r[1] - r[0], r[3] - r[2]), c + Vector3(0, 0.012, 0))
	# raised vegetable beds in two blocks either side of the walkways
	var crops := ["lettuce", "tomato", "pumpkin", "carrot", "flowers"]
	var i := 0
	for bx in [-62.0, -55.5, -39.0, -32.5]:
		for bz in [-66.0, -60.0, -46.0, -40.0]:
			var p := Vector3(bx, 0, bz)
			_raised_bed(at.call(p), p, crops[i % crops.size()], rng)
			i += 1
	# compost corner, rain barrels, greenhouse, scarecrow, tool shed
	for k in 3:
		var p := Vector3(-68.0, 0, -45.0 + k * 2.4)
		_compost_bin(at.call(p), p, k)
	for p in [Vector3(-27.0, 0, -70.0), Vector3(-25.5, 0, -70.0), Vector3(-68.0, 0, -36.5)]:
		_barrel(at.call(p), p)
	var gh := Vector3(-30.0, 0, -58.0)
	_greenhouse(at.call(gh), gh)
	var sc := Vector3(-50.0, 0, -50.5)
	_scarecrow(at.call(sc), sc)
	var shed := Vector3(-66.0, 0, -69.0)
	_shed(at.call(shed), shed)
	_picket_fence(at, r, [Vector2(-47.0, -34.0), Vector2(-47.0, -72.0), Vector2(-24.0, -53.0), Vector2(-70.0, -53.0)])


static func _raised_bed(mb, p: Vector3, crop: String, rng: RandomNumberGenerator) -> void:
	mb.box(Vector3(5.0, 0.45, 1.6), WOOD, p + Vector3(0, 0.225, 0))
	mb.box(Vector3(5.1, 0.06, 1.7), DARK_WOOD, p + Vector3(0, 0.46, 0))
	mb.box(Vector3(4.8, 0.05, 1.4), SOIL, p + Vector3(0, 0.47, 0))
	for k in 8:
		var q := p + Vector3(-2.1 + k * 0.6, 0.5, rng.randf_range(-0.35, 0.35))
		match crop:
			"lettuce":
				mb.sphere(0.24, Color(0.45, 0.78, 0.3), q + Vector3(0, 0.1, 0), Vector3(1, 0.7, 1))
				mb.sphere(0.16, Color(0.6, 0.88, 0.4), q + Vector3(0, 0.18, 0), Vector3(1, 0.6, 1), Vector3.ZERO, 0)
			"tomato":
				mb.cyl(0.02, 0.02, 0.9, Color(0.6, 0.5, 0.3), q + Vector3(0, 0.45, 0), Vector3.ZERO, 4)
				mb.sphere(0.2, Color(0.25, 0.55, 0.2), q + Vector3(0, 0.55, 0), Vector3(1, 1.4, 1))
				mb.sphere(0.08, Color(0.9, 0.18, 0.12), q + Vector3(0.12, 0.45, 0.08), Vector3.ONE, Vector3.ZERO, 0)
				mb.sphere(0.07, Color(0.95, 0.3, 0.1), q + Vector3(-0.1, 0.65, -0.05), Vector3.ONE, Vector3.ZERO, 0)
			"pumpkin":
				if k % 2 == 0:
					mb.sphere(0.26, Color(0.95, 0.55, 0.12), q + Vector3(0, 0.12, 0), Vector3(1, 0.7, 1))
					mb.cyl(0.03, 0.03, 0.12, Color(0.3, 0.45, 0.15), q + Vector3(0, 0.3, 0), Vector3.ZERO, 4)
				mb.sphere(0.2, Color(0.3, 0.6, 0.22), q + Vector3(0.25, 0.05, 0.2), Vector3(1.3, 0.3, 1))
			"carrot":
				for t in 3:
					mb.prism(Vector3(0.08, 0.3, 0.02), Color(0.35, 0.7, 0.25), q + Vector3(t * 0.06 - 0.06, 0.15, 0), Vector3(0, t * 1.1, (t - 1) * 0.3))
				mb.cyl(0.06, 0.06, 0.04, Color(0.95, 0.5, 0.1), q + Vector3(0, 0.02, 0), Vector3.ZERO, 6)
			_:
				mb.cyl(0.015, 0.015, 0.4, Color(0.25, 0.5, 0.2), q + Vector3(0, 0.2, 0), Vector3.ZERO, 4)
				mb.sphere(0.12, [Color(0.95, 0.85, 0.2), Color(0.9, 0.35, 0.6), Color(0.6, 0.4, 0.95)][k % 3], q + Vector3(0, 0.42, 0), Vector3(1, 0.6, 1), Vector3.ZERO, 0)


static func _compost_bin(mb, p: Vector3, k: int) -> void:
	for sx in [-0.7, 0.7]:
		for sz in [-0.7, 0.7]:
			mb.box(Vector3(0.1, 1.1, 0.1), DARK_WOOD, p + Vector3(sx, 0.55, sz))
	for y in [0.25, 0.6, 0.95]:
		for side in 4:
			var yaw := side * PI * 0.5
			var d := Vector3(sin(yaw), 0, cos(yaw)) * 0.7
			mb.box(Vector3(1.45, 0.18, 0.05), WOOD, p + d + Vector3(0, y, 0), Vector3(0, yaw, 0))
	mb.sphere(0.6, [Color(0.35, 0.25, 0.15), Color(0.42, 0.33, 0.18), Color(0.3, 0.4, 0.2)][k], p + Vector3(0, 0.75, 0), Vector3(1, 0.5, 1))
	mb.sphere(0.12, Color(0.85, 0.25, 0.15), p + Vector3(0.2, 1.02, 0.1), Vector3.ONE, Vector3.ZERO, 0)


static func _barrel(mb, p: Vector3) -> void:
	mb.cyl(0.42, 0.38, 1.0, Color(0.2, 0.45, 0.8), p + Vector3(0, 0.5, 0), Vector3.ZERO, 12)
	mb.cyl(0.44, 0.44, 0.06, Color(0.15, 0.35, 0.65), p + Vector3(0, 1.02, 0), Vector3.ZERO, 12)
	mb.cyl(0.05, 0.05, 0.18, Color(0.75, 0.75, 0.78), p + Vector3(0, 0.2, 0.42), Vector3(PI * 0.5, 0, 0), 6)
	# leaf badge: rain water harvesting
	mb.sphere(0.14, Color(0.4, 0.85, 0.4), p + Vector3(0, 0.6, 0.4), Vector3(0.6, 1, 0.2), Vector3.ZERO, 0)


static func _greenhouse(mb, p: Vector3) -> void:
	var glass := Color(0.78, 0.9, 0.92)
	var frame := Color(0.92, 0.94, 0.95)
	mb.box(Vector3(6.0, 0.3, 4.0), Color(0.75, 0.72, 0.68), p + Vector3(0, 0.15, 0))
	mb.box(Vector3(5.9, 1.8, 3.9), glass, p + Vector3(0, 1.2, 0))
	mb.prism(Vector3(6.0, 1.2, 4.0), glass.lightened(0.05), p + Vector3(0, 2.7, 0), Vector3(0, PI * 0.5, 0))
	for x in [-2.95, -1.5, 0.0, 1.5, 2.95]:
		mb.box(Vector3(0.08, 1.85, 4.0), frame, p + Vector3(x, 1.2, 0))
	mb.box(Vector3(6.0, 0.08, 4.0), frame, p + Vector3(0, 2.12, 0))
	mb.box(Vector3(0.9, 1.6, 0.05), Color(0.6, 0.78, 0.8), p + Vector3(0, 1.1, 1.97))
	for x in [-2.0, -0.6, 0.8, 2.0]:
		mb.sphere(0.4, Color(0.3, 0.62, 0.25), p + Vector3(x, 1.4, -0.8), Vector3(1, 1.2, 1))


static func _scarecrow(mb, p: Vector3) -> void:
	mb.cyl(0.05, 0.06, 2.2, DARK_WOOD, p + Vector3(0, 1.1, 0), Vector3.ZERO, 6)
	mb.box(Vector3(1.6, 0.08, 0.08), DARK_WOOD, p + Vector3(0, 1.7, 0))
	mb.box(Vector3(0.7, 0.8, 0.35), Color(0.75, 0.3, 0.25), p + Vector3(0, 1.5, 0))
	mb.sphere(0.28, Color(0.92, 0.82, 0.55), p + Vector3(0, 2.15, 0))
	mb.cyl(0.0, 0.45, 0.5, Color(0.85, 0.72, 0.35), p + Vector3(0, 2.55, 0), Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		mb.sphere(0.12, Color(0.85, 0.75, 0.4), p + Vector3(sx * 0.82, 1.7, 0), Vector3(1, 1, 1))


static func _shed(mb, p: Vector3) -> void:
	mb.box(Vector3(3.0, 2.2, 2.4), Color(0.55, 0.38, 0.22), p + Vector3(0, 1.1, 0))
	for x in [-1.2, -0.6, 0.0, 0.6, 1.2]:
		mb.box(Vector3(0.05, 2.2, 2.42), DARK_WOOD, p + Vector3(x, 1.1, 0))
	mb.prism(Vector3(3.3, 0.9, 2.7), Color(0.3, 0.45, 0.3), p + Vector3(0, 2.65, 0), Vector3(0, PI * 0.5, 0))
	mb.box(Vector3(0.9, 1.7, 0.06), DARK_WOOD, p + Vector3(0.6, 0.85, 1.22))


## Picket fence around rectangle `r`, leaving gaps at `gates`.
static func _picket_fence(at: Callable, r: Array, gates: Array) -> void:
	var corners := [Vector2(r[0], r[2]), Vector2(r[1], r[2]), Vector2(r[1], r[3]), Vector2(r[0], r[3])]
	for side in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var yaw := atan2(dir.x, dir.y)
		var t := 0.0
		while t < length:
			var q := a + dir * t
			var gate := false
			for g in gates:
				if q.distance_to(g) < 2.0:
					gate = true
			if not gate:
				var p := Vector3(q.x, 0, q.y)
				var mb = at.call(p)
				mb.box(Vector3(0.1, 0.8, 0.05), WHITE, p + Vector3(0, 0.4, 0), Vector3(0, yaw + PI * 0.5, 0))
				if fmod(t, 2.4) < 0.6:
					mb.box(Vector3(0.05, 0.06, 2.4), WHITE, p + Vector3(0, 0.55, 0) + Vector3(dir.x, 0, dir.y) * 1.2, Vector3(0, yaw, 0))
			t += 0.6


# --- market square (NE) --------------------------------------------------------

static func _market(at: Callable, glow, ground: Callable, sh: Dictionary, rng: RandomNumberGenerator) -> void:
	var r := MARKET
	var c := Vector3((r[0] + r[1]) * 0.5, 0, (r[2] + r[3]) * 0.5)
	ground.call(sh.paving, {"stone": Color(0.78, 0.72, 0.64), "grout": Color(0.48, 0.43, 0.38), "brick": Vector2(0.6, 0.6)}, Vector2(r[1] - r[0], r[3] - r[2]), c + Vector3(0, 0.022, 0))
	var awnings := [[Color(0.9, 0.25, 0.22), WHITE], [Color(0.2, 0.5, 0.85), WHITE], [Color(0.25, 0.65, 0.35), Color(1.0, 0.92, 0.6)], [Color(0.98, 0.7, 0.15), WHITE]]
	var produce := [Color(0.95, 0.3, 0.2), Color(1.0, 0.6, 0.1), Color(0.6, 0.8, 0.25), Color(0.55, 0.25, 0.55), Color(1.0, 0.85, 0.2)]
	var k := 0
	for sx in [30.0, 38.0, 46.0, 54.0, 62.0]:
		var p := Vector3(sx, 0, -66.0)
		_stall(at.call(p), p, awnings[k % awnings.size()], produce, rng)
		k += 1
	for sx in [32.0, 46.0, 60.0]:
		for sz in [-50.0, -42.0]:
			var p := Vector3(sx + rng.randf_range(-1.0, 1.0), 0, sz)
			_cafe(at.call(p), p, awnings[(k + int(sz)) % awnings.size()][0], rng)
			k += 1
	var rs := Vector3(66.0, 0, -40.0)
	_recycle_station(at.call(rs), rs)
	var bk := Vector3(28.0, 0, -37.0)
	_bike_rack(at.call(bk), bk)
	var kiosk := Vector3(66.0, 0, -55.0)
	_kiosk(at.call(kiosk), kiosk)
	for p in [Vector3(26.0, 0, -58.0), Vector3(68.0, 0, -66.0), Vector3(40.0, 0, -36.5), Vector3(52.0, 0, -36.5)]:
		_planter(at.call(p), p)
	for x in [27.0, 47.0, 67.0]:
		var p := Vector3(x, 0, -45.5)
		_string_lights(at.call(p), glow, p)


static func _stall(mb, p: Vector3, cols: Array, produce: Array, rng: RandomNumberGenerator) -> void:
	for sx in [-1.6, 1.6]:
		for sz in [-0.9, 0.9]:
			mb.cyl(0.05, 0.05, 2.4, DARK_WOOD, p + Vector3(sx, 1.2, sz), Vector3.ZERO, 6)
	mb.box(Vector3(3.4, 0.9, 1.0), WOOD, p + Vector3(0, 0.45, 0.4))
	mb.box(Vector3(3.5, 0.08, 1.1), DARK_WOOD, p + Vector3(0, 0.92, 0.4))
	for i in 7:
		mb.box(Vector3(0.5, 0.08, 2.3), cols[i % 2], p + Vector3(-1.5 + i * 0.5, 2.45, 0.1), Vector3(-0.25, 0, 0))
	for i in 5:
		var q := p + Vector3(-1.3 + i * 0.65, 1.02, 0.45)
		mb.box(Vector3(0.55, 0.16, 0.5), Color(0.75, 0.58, 0.36), q)
		var c: Color = produce[(i + rng.randi()) % produce.size()]
		for j in 4:
			mb.sphere(0.1, c, q + Vector3((j % 2) * 0.2 - 0.1, 0.12, (j / 2) * 0.18 - 0.09), Vector3.ONE, Vector3.ZERO, 0)


static func _cafe(mb, p: Vector3, c: Color, rng: RandomNumberGenerator) -> void:
	mb.cyl(0.55, 0.55, 0.05, WHITE, p + Vector3(0, 0.75, 0), Vector3.ZERO, 12)
	mb.cyl(0.05, 0.05, 0.75, IRON, p + Vector3(0, 0.37, 0), Vector3.ZERO, 6)
	mb.cyl(0.04, 0.04, 2.2, WHITE, p + Vector3(0, 1.1, 0), Vector3.ZERO, 6)
	mb.cyl(0.05, 1.4, 0.4, c, p + Vector3(0, 2.3, 0), Vector3.ZERO, 8)
	mb.cyl(1.42, 1.42, 0.05, WHITE, p + Vector3(0, 2.1, 0), Vector3.ZERO, 8)
	for k in 3:
		var a := float(k) / 3.0 * TAU + rng.randf() * 0.4
		var q := p + Vector3(cos(a), 0, sin(a)) * 0.95
		mb.box(Vector3(0.42, 0.05, 0.42), WOOD, q + Vector3(0, 0.45, 0), Vector3(0, -a, 0))
		mb.box(Vector3(0.42, 0.45, 0.05), WOOD, q + Vector3(cos(a), 0, sin(a)) * 0.2 + Vector3(0, 0.7, 0), Vector3(0, PI * 0.5 - a, 0))
		mb.cyl(0.03, 0.03, 0.45, IRON, q + Vector3(0, 0.22, 0), Vector3.ZERO, 4)
	mb.cyl(0.06, 0.05, 0.12, WHITE, p + Vector3(0.15, 0.83, 0.1), Vector3.ZERO, 6)


static func _recycle_station(mb, p: Vector3) -> void:
	var cols := [GameData.MATERIALS.plastic.color, GameData.MATERIALS.paper.color, GameData.MATERIALS.glass.color, GameData.MATERIALS.organic.color, Color(0.6, 0.6, 0.65)]
	mb.box(Vector3(5.2, 0.12, 1.4), Color(0.7, 0.68, 0.64), p + Vector3(0, 0.06, 0))
	for i in cols.size():
		var q := p + Vector3(-2.0 + i * 1.0, 0, 0)
		mb.box(Vector3(0.8, 1.1, 0.8), cols[i], q + Vector3(0, 0.67, 0))
		mb.box(Vector3(0.84, 0.1, 0.84), cols[i].darkened(0.25), q + Vector3(0, 1.25, 0))
		mb.box(Vector3(0.4, 0.06, 0.05), Color(0.08, 0.08, 0.08), q + Vector3(0, 1.0, 0.41))
	# sign board with the recycling triangle
	mb.box(Vector3(0.1, 2.4, 0.1), IRON, p + Vector3(2.8, 1.2, 0))
	mb.box(Vector3(1.2, 0.9, 0.06), Color(0.2, 0.6, 0.35), p + Vector3(2.8, 2.2, 0.06))
	for k in 3:
		var a := float(k) / 3.0 * TAU
		mb.prism(Vector3(0.22, 0.22, 0.03), WHITE, p + Vector3(2.8 + sin(a) * 0.2, 2.2 + cos(a) * 0.2, 0.1), Vector3(0, 0, -a))


static func _bike_rack(mb, p: Vector3) -> void:
	for i in 4:
		var q := p + Vector3(i * 1.0 - 1.5, 0, 0)
		mb.torus(0.4, 0.46, Color(0.7, 0.72, 0.75), q + Vector3(0, 0.0, 0), Vector3(0, 0, PI * 0.5))
	for i in 2:
		var q := p + Vector3(i * 2.0 - 1.0, 0, 0.3)
		var c: Color = [Color(0.9, 0.25, 0.2), Color(0.2, 0.6, 0.9)][i]
		for wx in [-0.55, 0.55]:
			mb.torus(0.26, 0.32, Color(0.1, 0.1, 0.1), q + Vector3(0, 0.32, wx), Vector3(0, 0, PI * 0.5))
		mb.box(Vector3(0.05, 0.05, 1.0), c, q + Vector3(0, 0.55, 0), Vector3(0.3, 0, 0))
		mb.box(Vector3(0.05, 0.5, 0.05), c, q + Vector3(0, 0.55, -0.15), Vector3(0.35, 0, 0))
		mb.box(Vector3(0.12, 0.05, 0.25), Color(0.15, 0.15, 0.15), q + Vector3(0, 0.82, -0.25))
		mb.box(Vector3(0.45, 0.04, 0.04), Color(0.2, 0.2, 0.2), q + Vector3(0, 0.88, 0.45))


static func _kiosk(mb, p: Vector3) -> void:
	mb.box(Vector3(2.4, 2.2, 2.0), Color(0.98, 0.92, 0.85), p + Vector3(0, 1.1, 0))
	mb.box(Vector3(1.8, 0.9, 0.05), Color(0.35, 0.25, 0.2), p + Vector3(0, 1.45, 1.01))
	mb.box(Vector3(2.6, 0.1, 0.5), Color(0.9, 0.5, 0.65), p + Vector3(0, 1.0, 1.15))
	for i in 5:
		mb.box(Vector3(0.52, 0.08, 1.2), [Color(0.9, 0.5, 0.65), WHITE][i % 2], p + Vector3(-1.04 + i * 0.52, 2.35, 1.0), Vector3(-0.35, 0, 0))
	# giant ice cream on top
	mb.cyl(0.35, 0.05, 0.8, Color(0.85, 0.65, 0.35), p + Vector3(0, 2.75, 0), Vector3(PI, 0, 0), 8)
	mb.sphere(0.4, Color(1.0, 0.75, 0.82), p + Vector3(0, 3.25, 0))


static func _string_lights(mb, glow, p: Vector3) -> void:
	mb.cyl(0.06, 0.07, 3.6, IRON, p + Vector3(0, 1.8, 0), Vector3.ZERO, 6)
	for k in 9:
		var t := float(k) / 8.0
		var q := p + Vector3(-9.0 + t * 18.0, 3.4 - sin(t * PI) * 0.6, 0)
		glow.sphere(0.09, [Color(1.0, 0.85, 0.5), Color(1.0, 0.6, 0.4), Color(0.7, 0.9, 1.0)][k % 3], q, Vector3.ONE, Vector3.ZERO, 0)


# --- pond (W) ------------------------------------------------------------------

static func _pond(at: Callable, ground: Callable, sh: Dictionary, rng: RandomNumberGenerator) -> void:
	ground.call(sh.pond, {}, POND_R * 2.0, POND_C + Vector3(0, 0.03, 0))
	# rocks on the shore, reeds in clumps
	for k in 26:
		var a := float(k) / 26.0 * TAU + rng.randf() * 0.15
		var p := POND_C + Vector3(cos(a) * POND_R.x, 0, sin(a) * POND_R.y) * rng.randf_range(0.97, 1.08)
		var mb = at.call(p)
		if k % 3 == 0:
			_reeds(mb, p, rng)
		else:
			var s := rng.randf_range(0.35, 0.7)
			mb.sphere(s, Color(0.55, 0.55, 0.52).darkened(rng.randf() * 0.2), p + Vector3(0, s * 0.3, 0), Vector3(1.3, 0.6, 1.0), Vector3(0, rng.randf() * TAU, 0), 0)
	for k in 9:
		var a := rng.randf() * TAU
		var p := POND_C + Vector3(cos(a) * POND_R.x, 0, sin(a) * POND_R.y) * rng.randf_range(0.2, 0.75)
		var mb = at.call(p)
		mb.cyl(0.55, 0.55, 0.02, Color(0.25, 0.55, 0.25), p + Vector3(0, 0.05, 0), Vector3.ZERO, 10)
		if k % 3 == 0:
			mb.sphere(0.13, Color(1.0, 0.65, 0.8), p + Vector3(0.1, 0.12, 0.1), Vector3(1, 0.7, 1), Vector3.ZERO, 0)
	# wooden dock reaching into the water
	var d := POND_C + Vector3(POND_R.x * 0.55, 0, -POND_R.y * 0.95)
	var mb = at.call(d)
	for i in 6:
		mb.box(Vector3(1.6, 0.08, 0.32), WOOD.lightened(0.05 * (i % 2)), d + Vector3(0, 0.35, i * 0.36))
	for sx in [-0.75, 0.75]:
		for sz in [0.0, 1.8]:
			mb.cyl(0.07, 0.07, 0.7, DARK_WOOD, d + Vector3(sx, 0.2, sz), Vector3.ZERO, 6)
	_bench_facing(at.call(POND_C + Vector3(-POND_R.x - 2.5, 0, 0)), POND_C + Vector3(-POND_R.x - 2.5, 0, 0), -PI * 0.5)


static func _reeds(mb, p: Vector3, rng: RandomNumberGenerator) -> void:
	for k in 6:
		var q := p + Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
		var h := rng.randf_range(0.9, 1.6)
		mb.cyl(0.02, 0.03, h, Color(0.4, 0.6, 0.25), q + Vector3(0, h * 0.5, 0), Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15)), 4)
		if k % 2 == 0:
			mb.cyl(0.05, 0.05, 0.25, Color(0.45, 0.3, 0.15), q + Vector3(0, h + 0.05, 0), Vector3.ZERO, 6)


# --- sports court and playground (E) ----------------------------------------------

static func _court(at: Callable, ground: Callable, sh: Dictionary, rng: RandomNumberGenerator) -> void:
	var cc := Vector3(46.0, 0, 2.0)
	ground.call(sh.court, {"inner": Color(0.25, 0.5, 0.72), "outer": Color(0.72, 0.38, 0.28)}, Vector2(22.0, 13.0), cc + Vector3(0, 0.028, 0))
	for sx in [-1.0, 1.0]:
		var p := cc + Vector3(sx * 10.6, 0, 0)
		var mb = at.call(p)
		mb.cyl(0.08, 0.1, 3.2, Color(0.3, 0.32, 0.35), p + Vector3(0, 1.6, 0), Vector3.ZERO, 8)
		mb.box(Vector3(0.08, 1.0, 1.6), WHITE, p + Vector3(-sx * 0.35, 3.1, 0))
		mb.box(Vector3(0.09, 0.45, 0.6), Color(0.9, 0.3, 0.2), p + Vector3(-sx * 0.36, 2.95, 0))
		mb.torus(0.2, 0.25, Color(0.95, 0.45, 0.1), p + Vector3(-sx * 0.65, 2.75, 0))
	# playground on rubber tiles
	var pg := Vector3(46.0, 0, 21.0)
	ground.call(sh.ground, {"base": Color(0.78, 0.42, 0.3), "speck": Color(0.95, 0.75, 0.3), "grain": 9.0, "speck_amt": 0.12}, Vector2(26.0, 14.0), pg + Vector3(0, 0.026, 0))
	var sl := pg + Vector3(-7.0, 0, 0)
	_slide(at.call(sl), sl)
	var sw := pg + Vector3(1.0, 0, -1.0)
	_swings(at.call(sw), sw)
	var ss := pg + Vector3(8.5, 0, 2.0)
	_seesaw(at.call(ss), ss)
	var sb := pg + Vector3(1.0, 0, 4.5)
	_sandbox(at.call(sb), sb)


static func _slide(mb, p: Vector3) -> void:
	for sx in [-0.6, 0.6]:
		for sz in [-0.6, 0.6]:
			mb.cyl(0.07, 0.07, 2.0, Color(0.95, 0.75, 0.15), p + Vector3(sx, 1.0, sz), Vector3.ZERO, 6)
	mb.box(Vector3(1.4, 0.1, 1.4), Color(0.2, 0.55, 0.85), p + Vector3(0, 1.6, 0))
	mb.prism(Vector3(1.5, 0.7, 1.5), Color(0.9, 0.3, 0.25), p + Vector3(0, 2.35, 0))
	mb.box(Vector3(0.8, 0.08, 3.2), Color(0.25, 0.75, 0.4), p + Vector3(0, 0.9, 2.1), Vector3(0.52, 0, 0))
	for i in 5:
		mb.box(Vector3(0.8, 0.05, 0.08), Color(0.95, 0.75, 0.15), p + Vector3(0, 0.3 + i * 0.3, -0.75))


static func _swings(mb, p: Vector3) -> void:
	var c := Color(0.25, 0.6, 0.85)
	for sx in [-2.0, 2.0]:
		mb.cyl(0.07, 0.07, 2.8, c, p + Vector3(sx, 1.3, -0.5), Vector3(0.35, 0, 0), 6)
		mb.cyl(0.07, 0.07, 2.8, c, p + Vector3(sx, 1.3, 0.5), Vector3(-0.35, 0, 0), 6)
	mb.cyl(0.07, 0.07, 4.2, c, p + Vector3(0, 2.6, 0), Vector3(0, 0, PI * 0.5), 6)
	for sx in [-1.0, 1.0]:
		for cx in [-0.25, 0.25]:
			mb.cyl(0.015, 0.015, 2.0, Color(0.7, 0.7, 0.7), p + Vector3(sx + cx, 1.6, 0), Vector3.ZERO, 4)
		mb.box(Vector3(0.6, 0.06, 0.3), Color(0.95, 0.4, 0.3), p + Vector3(sx, 0.6, 0))


static func _seesaw(mb, p: Vector3) -> void:
	mb.prism(Vector3(0.4, 0.5, 0.4), Color(0.95, 0.75, 0.15), p + Vector3(0, 0.25, 0))
	mb.box(Vector3(3.0, 0.08, 0.3), Color(0.9, 0.3, 0.25), p + Vector3(0, 0.55, 0), Vector3(0, 0, 0.18))
	for sx in [-1.3, 1.3]:
		mb.cyl(0.03, 0.03, 0.4, Color(0.2, 0.55, 0.85), p + Vector3(sx, 0.55 + sx * 0.18 + 0.2, 0), Vector3.ZERO, 4)


static func _sandbox(mb, p: Vector3) -> void:
	for side in 4:
		var yaw := side * PI * 0.5
		var d := Vector3(sin(yaw), 0, cos(yaw)) * 1.6
		mb.box(Vector3(3.3, 0.3, 0.2), WOOD, p + d + Vector3(0, 0.15, 0), Vector3(0, yaw, 0))
	mb.box(Vector3(3.0, 0.05, 3.0), Color(0.95, 0.86, 0.62), p + Vector3(0, 0.2, 0))
	mb.cyl(0.25, 0.15, 0.3, Color(0.9, 0.3, 0.25), p + Vector3(0.6, 0.35, 0.4), Vector3.ZERO, 8)
	mb.sphere(0.35, Color(0.95, 0.86, 0.62), p + Vector3(-0.5, 0.25, -0.3), Vector3(1, 0.6, 1))


# --- promenade (S) --------------------------------------------------------------

static func _promenade(at: Callable, glow, ground: Callable, sh: Dictionary, rng: RandomNumberGenerator, clear: Vector3, clear_r: float) -> void:
	var ax := GameData.ARENA_X
	ground.call(sh.plank, {"wood": Color(0.7, 0.52, 0.34)}, Vector2(ax * 2.0 + 12.0, 3.2), Vector3(0, 0.03, PROMENADE_Z))
	var x := -ax + 4.0
	while x < ax:
		var p := Vector3(x, 0, PROMENADE_Z + 1.9)
		if not _cleared(p, clear, clear_r * 0.6):
			var mb = at.call(p)
			# rope railing post + lamp every other one
			mb.cyl(0.08, 0.08, 1.0, DARK_WOOD, p + Vector3(0, 0.5, 0), Vector3.ZERO, 6)
			mb.box(Vector3(4.0, 0.05, 0.05), Color(0.85, 0.78, 0.6), p + Vector3(2.0, 0.85, 0))
		x += 4.0
	x = -ax + 10.0
	while x < ax:
		var p := Vector3(x, 0, PROMENADE_Z - 2.2)
		if not _cleared(p, clear, clear_r * 0.6):
			_bench_facing(at.call(p), p, PI)
		x += 18.0
	# beach: lifeguard tower and a volleyball net
	var lg := Vector3(-30.0, 0, 56.5)
	if not _cleared(lg, clear, clear_r * 0.6):
		var mb = at.call(lg)
		for sx in [-0.8, 0.8]:
			for sz in [-0.8, 0.8]:
				mb.cyl(0.08, 0.08, 2.6, WHITE, lg + Vector3(sx, 1.3, sz), Vector3.ZERO, 6)
		mb.box(Vector3(2.0, 1.2, 2.0), Color(0.9, 0.25, 0.2), lg + Vector3(0, 3.2, 0))
		mb.box(Vector3(2.0, 0.3, 2.0), WHITE, lg + Vector3(0, 3.65, 0))
		mb.prism(Vector3(2.3, 0.6, 2.3), Color(0.9, 0.25, 0.2), lg + Vector3(0, 4.15, 0))
		mb.box(Vector3(0.8, 0.06, 2.4), WOOD, lg + Vector3(0, 1.3, 1.6), Vector3(0.9, 0, 0))
	var vb := Vector3(36.0, 0, 56.0)
	if not _cleared(vb, clear, clear_r * 0.6):
		var mb = at.call(vb)
		for sx in [-4.0, 4.0]:
			mb.cyl(0.06, 0.06, 2.5, WHITE, vb + Vector3(sx, 1.25, 0), Vector3.ZERO, 6)
		mb.box(Vector3(8.0, 0.8, 0.03), Color(0.92, 0.92, 0.9), vb + Vector3(0, 2.0, 0))
		mb.box(Vector3(8.0, 0.06, 0.05), Color(0.2, 0.3, 0.6), vb + Vector3(0, 2.4, 0))
		mb.sphere(0.2, Color(1.0, 0.85, 0.2), vb + Vector3(2.0, 0.2, 1.5), Vector3.ONE, Vector3.ZERO, 0)


# --- boundary --------------------------------------------------------------------

## Low clipped hedges just outside the playable rectangle so its edges read.
static func _hedges(at: Callable) -> void:
	var ax := GameData.ARENA_X + 1.6
	var z0 := GameData.ARENA_Z_MIN - 1.6
	var z1 := GameData.ARENA_Z_MAX - 9.0
	var runs := [[Vector2(-ax, z0), Vector2(ax, z0)], [Vector2(-ax, z0), Vector2(-ax, z1)], [Vector2(ax, z0), Vector2(ax, z1)]]
	for run in runs:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var t := 0.0
		while t < length:
			var seg := minf(6.0, length - t)
			var q := a + dir * (t + seg * 0.5)
			var p := Vector3(q.x, 0, q.y)
			var yaw := atan2(dir.x, dir.y)
			var mb = at.call(p)
			# gap every 30 m so the hedge reads as a garden border, not a wall
			if fmod(t, 30.0) > 1.0:
				mb.box(Vector3(1.1, 1.0, seg - 0.2), Color(0.18, 0.42, 0.2), p + Vector3(0, 0.5, 0), Vector3(0, yaw, 0))
				mb.box(Vector3(1.0, 0.18, seg - 0.3), Color(0.24, 0.52, 0.25), p + Vector3(0, 1.05, 0), Vector3(0, yaw, 0))
			t += 6.0
