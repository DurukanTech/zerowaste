extends RefCounted
## Detailed waste-monster models, merged per kind into at most three meshes:
## "opaque", "alpha" (see-through plastic/glass) and "glow" (emissive bits).
## All face +Z, stand on y = 0, and are cached.

const ModelBuilder = preload("res://scripts/model_builder.gd")

const WHITE := Color(0.97, 0.97, 0.95)
const BLACK := Color(0.06, 0.06, 0.07)
const BLUSH := Color(1.0, 0.55, 0.6)

static var _cache := {}


static func get_model(kind: String) -> Dictionary:
	if not _cache.has(kind):
		var o := ModelBuilder.new()
		var a := ModelBuilder.new()
		var g := ModelBuilder.new()
		match kind:
			"bag": _bag(o, a)
			"bottle": _bottle(o, a)
			"rot", "rot_small": _rot(o)
			"box": _box(o)
			"battery": _battery(o, g)
			"miniboss": _miniboss(o, g)
			"boss": _boss(o, g)
			"boss_arm_l": _boss_arm(o, Color(1.0, 0.75, 0.1), Color(0.85, 0.2, 0.2))
			"boss_arm_r": _boss_arm(o, Color(0.96, 0.96, 0.92), Color(0.2, 0.7, 0.35))
		_cache[kind] = {
			"opaque": null if o.is_empty() else o.commit(),
			"alpha": null if a.is_empty() else a.commit(),
			"glow": null if g.is_empty() else g.commit(),
		}
	return _cache[kind]


## White sclera + black pupil, looking forward.
static func _eye(mb, pos: Vector3, r: float, sclera := WHITE, pupil := BLACK) -> void:
	mb.sphere(r, sclera, pos, Vector3(1, 1, 0.7))
	mb.sphere(r * 0.52, pupil, pos + Vector3(0, -r * 0.1, r * 0.55), Vector3(1, 1, 0.6))
	mb.sphere(r * 0.16, WHITE, pos + Vector3(r * 0.2, r * 0.15, r * 0.82), Vector3.ONE, Vector3.ZERO, 0)


static func _brow(mb, pos: Vector3, w: float, angle: float) -> void:
	mb.box(Vector3(w, w * 0.22, w * 0.18), BLACK, pos, Vector3(0, 0, angle))


static func _bag(o, a) -> void:
	var film := Color(0.98, 0.98, 0.95, 0.82)
	a.sphere(0.42, film, Vector3(0, 0.82, 0), Vector3(1, 0.95, 0.85))
	a.cyl(0.36, 0.06, 0.48, film, Vector3(0, 0.4, 0), Vector3(0, 0, 0.12))
	for sx in [-1.0, 1.0]:
		a.torus(0.07, 0.12, film, Vector3(sx * 0.17, 1.2, 0), Vector3(PI * 0.5, 0, 0))
	# crinkles
	a.box(Vector3(0.03, 0.5, 0.02), Color(0.85, 0.85, 0.82, 0.8), Vector3(-0.28, 0.85, 0.24), Vector3(0, -0.6, 0.2))
	a.box(Vector3(0.03, 0.45, 0.02), Color(0.85, 0.85, 0.82, 0.8), Vector3(0.3, 0.8, 0.2), Vector3(0, 0.6, -0.2))
	# printed shop logo
	o.box(Vector3(0.34, 0.1, 0.02), Color(0.92, 0.25, 0.2), Vector3(0, 0.62, 0.33), Vector3(-0.3, 0, 0))
	o.box(Vector3(0.2, 0.05, 0.02), Color(1.0, 0.8, 0.2), Vector3(0, 0.53, 0.3), Vector3(-0.4, 0, 0))
	for sx in [-1.0, 1.0]:
		_eye(o, Vector3(sx * 0.13, 0.92, 0.31), 0.085)
		o.sphere(0.045, BLUSH, Vector3(sx * 0.25, 0.8, 0.3), Vector3(1, 0.6, 0.3), Vector3.ZERO, 0)
	o.sphere(0.045, Color(0.25, 0.08, 0.08), Vector3(0, 0.77, 0.35), Vector3(1, 1.3, 0.5), Vector3.ZERO, 0)


static func _bottle(o, a) -> void:
	var pet := Color(0.35, 0.85, 0.55, 0.7)
	a.cyl(0.26, 0.26, 0.8, pet, Vector3(0, 0.55, 0))
	a.sphere(0.26, pet, Vector3(0, 0.16, 0), Vector3(1, 0.4, 1))
	a.cyl(0.12, 0.26, 0.25, pet, Vector3(0, 1.07, 0))
	a.cyl(0.11, 0.11, 0.1, pet, Vector3(0, 1.24, 0))
	for y in [0.3, 0.88]:
		a.cyl(0.275, 0.275, 0.05, Color(0.25, 0.7, 0.45, 0.8), Vector3(0, y, 0))
	o.cyl(0.125, 0.125, 0.12, Color(0.15, 0.4, 0.95), Vector3(0, 1.34, 0))
	o.cyl(0.14, 0.14, 0.03, Color(0.1, 0.3, 0.75), Vector3(0, 1.27, 0))
	o.cyl(0.268, 0.268, 0.3, Color(0.97, 0.97, 0.94), Vector3(0, 0.62, 0))
	o.cyl(0.272, 0.272, 0.07, Color(0.9, 0.22, 0.2), Vector3(0, 0.55, 0))
	for sx in [-1.0, 1.0]:
		_eye(o, Vector3(sx * 0.1, 0.68, 0.24), 0.07)
		_brow(o, Vector3(sx * 0.1, 0.79, 0.27), 0.12, -sx * 0.35)
		o.cyl(0.06, 0.07, 0.16, Color(0.2, 0.22, 0.25), Vector3(sx * 0.12, 0.08, 0))
		o.capsule(0.045, 0.3, Color(0.25, 0.75, 0.45), Vector3(sx * 0.3, 0.6, 0.05), Vector3(0, 0, sx * 0.5))


static func _rot(o) -> void:
	o.sphere(0.5, Color(0.38, 0.36, 0.12), Vector3(0, 0.4, 0), Vector3(1, 0.78, 1))
	o.sphere(0.3, Color(0.46, 0.42, 0.16), Vector3(0.3, 0.55, 0.05))
	o.sphere(0.28, Color(0.32, 0.29, 0.1), Vector3(-0.3, 0.5, -0.1))
	o.sphere(0.25, Color(0.42, 0.4, 0.16), Vector3(0.05, 0.72, -0.2))
	o.sphere(0.18, Color(0.5, 0.3, 0.1), Vector3(-0.15, 0.25, 0.35))
	# apple core
	o.cyl(0.06, 0.06, 0.24, Color(0.96, 0.9, 0.7), Vector3(0.28, 0.88, -0.05))
	o.sphere(0.1, Color(0.82, 0.15, 0.1), Vector3(0.28, 1.0, -0.05), Vector3(1, 0.7, 1))
	o.sphere(0.1, Color(0.82, 0.15, 0.1), Vector3(0.28, 0.76, -0.05), Vector3(1, 0.7, 1))
	o.box(Vector3(0.02, 0.08, 0.02), Color(0.35, 0.2, 0.08), Vector3(0.28, 1.1, -0.05))
	# banana peel
	for i in 3:
		o.box(Vector3(0.08, 0.03, 0.36), Color(0.96, 0.85, 0.25), Vector3(-0.25, 0.8, 0.0), Vector3(-0.7, (i - 1) * 0.7, 0))
	o.sphere(0.06, Color(0.4, 0.3, 0.1), Vector3(-0.25, 0.82, 0.0))
	# egg shell
	o.sphere(0.1, Color(0.95, 0.92, 0.85), Vector3(-0.38, 0.35, 0.28), Vector3(1, 0.55, 1))
	_eye(o, Vector3(-0.17, 0.55, 0.4), 0.11, Color(0.95, 0.95, 0.6))
	_eye(o, Vector3(0.17, 0.57, 0.4), 0.085, Color(0.95, 0.95, 0.6))
	o.box(Vector3(0.26, 0.06, 0.06), Color(0.15, 0.08, 0.04), Vector3(0, 0.36, 0.44), Vector3(0, 0, 0.15))
	o.sphere(0.04, Color(0.55, 0.85, 0.2), Vector3(0.1, 0.3, 0.46), Vector3(1, 1.6, 1), Vector3.ZERO, 0)


static func _box(o) -> void:
	var card := Color(0.76, 0.58, 0.36)
	var dark := Color(0.62, 0.45, 0.27)
	var tape := Color(0.86, 0.76, 0.55)
	o.box(Vector3(1.0, 0.82, 0.9), card, Vector3(0, 0.5, 0))
	o.box(Vector3(0.22, 0.02, 0.92), tape, Vector3(0, 0.915, 0))
	o.box(Vector3(0.22, 0.28, 0.02), tape, Vector3(0, 0.76, 0.455))
	o.box(Vector3(1.0, 0.04, 0.42), dark, Vector3(0, 1.0, 0.34), Vector3(-0.7, 0, 0))
	o.box(Vector3(1.0, 0.04, 0.42), dark, Vector3(0, 1.0, -0.34), Vector3(0.7, 0, 0))
	o.box(Vector3(0.4, 0.04, 0.9), dark, Vector3(-0.6, 0.98, 0), Vector3(0, 0, -0.6))
	o.box(Vector3(0.4, 0.04, 0.9), dark, Vector3(0.6, 0.98, 0), Vector3(0, 0, 0.6))
	# "this side up" print on the side
	o.prism(Vector3(0.16, 0.16, 0.02), Color(0.15, 0.1, 0.05), Vector3(0.502, 0.6, 0.15), Vector3(0, PI * 0.5, 0))
	o.box(Vector3(0.02, 0.12, 0.05), Color(0.15, 0.1, 0.05), Vector3(0.502, 0.47, 0.15))
	# toothy mouth
	o.box(Vector3(0.6, 0.22, 0.02), Color(0.18, 0.08, 0.04), Vector3(0, 0.38, 0.452))
	for x in [-0.18, 0.0, 0.18]:
		o.prism(Vector3(0.1, 0.1, 0.03), WHITE, Vector3(x, 0.44, 0.465), Vector3(0, 0, PI))
	for x in [-0.09, 0.09]:
		o.prism(Vector3(0.1, 0.09, 0.03), WHITE, Vector3(x, 0.31, 0.465))
	for sx in [-1.0, 1.0]:
		_eye(o, Vector3(sx * 0.22, 0.68, 0.43), 0.11)
		_brow(o, Vector3(sx * 0.22, 0.83, 0.46), 0.22, -sx * 0.3)
		o.cyl(0.08, 0.08, 0.45, dark, Vector3(sx * 0.6, 0.48, 0.1), Vector3(0.3, 0, sx * 0.5))
		o.box(Vector3(0.2, 0.14, 0.24), Color(0.45, 0.32, 0.18), Vector3(sx * 0.25, 0.07, 0.02))


static func _battery(o, g) -> void:
	o.cyl(0.2, 0.2, 0.5, Color(0.12, 0.12, 0.14), Vector3(0, 0.42, 0))
	o.cyl(0.205, 0.205, 0.18, Color(0.98, 0.58, 0.12), Vector3(0, 0.6, 0))
	o.cyl(0.07, 0.07, 0.08, Color(0.82, 0.82, 0.85), Vector3(0, 0.73, 0))
	o.cyl(0.205, 0.205, 0.03, Color(0.82, 0.82, 0.85), Vector3(0, 0.18, 0))
	o.box(Vector3(0.1, 0.025, 0.02), WHITE, Vector3(0, 0.6, 0.21))
	o.box(Vector3(0.025, 0.1, 0.02), WHITE, Vector3(0, 0.6, 0.21))
	o.cyl(0.012, 0.012, 0.14, Color(0.3, 0.3, 0.3), Vector3(0.02, 0.82, 0), Vector3(0, 0, -0.3))
	for sx in [-1.0, 1.0]:
		_eye(o, Vector3(sx * 0.08, 0.43, 0.18), 0.055, Color(1.0, 0.95, 0.4))
		_brow(o, Vector3(sx * 0.08, 0.5, 0.2), 0.09, -sx * 0.45)
		o.cyl(0.045, 0.05, 0.17, Color(0.25, 0.25, 0.28), Vector3(sx * 0.09, 0.085, 0))
	g.sphere(0.07, Color(1.0, 0.85, 0.3), Vector3(0.06, 0.9, 0), Vector3.ONE, Vector3.ZERO, 0)


static func _miniboss(o, g) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	o.sphere(1.7, Color(0.3, 0.28, 0.24), Vector3(0, 1.1, 0), Vector3(1, 0.8, 1))
	var mounds := [Color(0.36, 0.33, 0.26), Color(0.28, 0.3, 0.22), Color(0.4, 0.36, 0.3)]
	for i in 7:
		var ang := float(i) / 7.0 * TAU
		o.sphere(rng.randf_range(0.6, 0.9), mounds[i % 3], Vector3(cos(ang) * 1.2, rng.randf_range(0.6, 1.4), sin(ang) * 1.2))
	for i in 30:
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(0.6, 1.6)
		var p := Vector3(cos(ang) * rad, 2.3 - rad * 0.75 + rng.randf_range(-0.2, 0.3), sin(ang) * rad)
		if p.z > 1.0 and absf(p.x) < 1.1:
			continue  # keep the face clear
		var rot := Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		match i % 6:
			0: o.box(Vector3(0.5, 0.4, 0.45), Color(0.76, 0.58, 0.36), p, rot)
			1: o.cyl(0.13, 0.13, 0.55, Color(0.35, 0.85, 0.55), p, rot)
			2: o.sphere(0.25, WHITE, p, Vector3(1, 0.9, 0.8), rot)
			3: o.cyl(0.11, 0.11, 0.28, [Color(0.85, 0.2, 0.2), Color(0.75, 0.75, 0.8)][i % 2], p, rot)
			4: o.torus(0.16, 0.32, Color(0.12, 0.12, 0.13), p, rot)
			5: o.box(Vector3(0.08, 0.03, 0.4), Color(0.96, 0.85, 0.25), p, rot)
	for sx in [-1.0, 1.0]:
		o.sphere(0.36, WHITE, Vector3(sx * 0.52, 1.65, 1.32), Vector3(1, 1, 0.6))
		_brow(o, Vector3(sx * 0.52, 2.08, 1.4), 0.6, -sx * 0.4)
		g.sphere(0.16, Color(1.0, 0.25, 0.15), Vector3(sx * 0.52, 1.62, 1.5))
	o.box(Vector3(1.1, 0.28, 0.12), Color(0.12, 0.05, 0.04), Vector3(0, 1.05, 1.5), Vector3(-0.2, 0, 0))
	for x in [-0.4, -0.13, 0.13, 0.4]:
		o.prism(Vector3(0.18, 0.18, 0.06), Color(0.9, 0.88, 0.7), Vector3(x, 1.16, 1.55), Vector3(-0.2, 0, PI))


static func _boss(o, g) -> void:
	var suit := Color(0.3, 0.22, 0.38)
	var suit_dark := Color(0.2, 0.15, 0.26)
	var skin := Color(0.92, 0.75, 0.6)
	var gold := Color(1.0, 0.78, 0.25)
	for sx in [-1.0, 1.0]:
		o.box(Vector3(0.9, 1.3, 0.9), suit_dark, Vector3(sx * 0.65, 0.75, 0))
		o.box(Vector3(1.0, 0.3, 1.35), BLACK, Vector3(sx * 0.65, 0.15, 0.2))
	o.box(Vector3(2.8, 2.6, 1.9), suit, Vector3(0, 2.6, 0))
	o.sphere(1.3, suit, Vector3(0, 2.3, 0.45), Vector3(1.05, 0.95, 0.75))
	o.box(Vector3(0.9, 1.9, 0.06), WHITE, Vector3(0, 3.0, 0.97))
	o.box(Vector3(0.36, 1.5, 0.07), Color(0.88, 0.12, 0.15), Vector3(0, 2.85, 1.02))
	o.box(Vector3(0.42, 0.3, 0.09), Color(0.7, 0.08, 0.1), Vector3(0, 3.62, 1.02))
	for sx in [-1.0, 1.0]:
		o.box(Vector3(0.5, 1.5, 0.07), suit_dark, Vector3(sx * 0.52, 3.15, 0.99), Vector3(0, 0, sx * 0.35))
	o.box(Vector3(2.85, 0.26, 1.95), BLACK, Vector3(0, 1.35, 0))
	o.box(Vector3(0.42, 0.3, 0.06), gold, Vector3(0, 1.35, 1.0))
	o.sphere(0.08, gold, Vector3(0, 2.4, 1.42))
	o.sphere(0.08, gold, Vector3(0, 2.0, 1.42))
	o.torus(0.9, 0.96, gold, Vector3(0.6, 2.2, 1.2), Vector3(PI * 0.5, 0.4, 0))
	# head
	o.sphere(0.95, skin, Vector3(0, 4.55, 0))
	o.sphere(0.7, skin, Vector3(0, 4.05, 0.25), Vector3(1, 0.6, 0.9))
	o.sphere(0.2, Color(0.95, 0.6, 0.55), Vector3(0, 4.5, 0.95))
	for sx in [-1.0, 1.0]:
		o.sphere(0.2, skin, Vector3(sx * 0.95, 4.55, 0))
		o.box(Vector3(0.6, 0.16, 0.16), Color(0.3, 0.28, 0.3), Vector3(sx * 0.3, 4.27, 0.88), Vector3(0, 0, -sx * 0.25))
		o.sphere(0.17, WHITE, Vector3(sx * 0.32, 4.68, 0.82), Vector3(1, 1, 0.5))
		_brow(o, Vector3(sx * 0.33, 4.93, 0.86), 0.42, -sx * 0.35)
		g.sphere(0.09, Color(1.0, 0.2, 0.15), Vector3(sx * 0.32, 4.66, 0.92))
	o.torus(0.19, 0.24, gold, Vector3(0.32, 4.68, 0.9), Vector3(PI * 0.5, 0, 0))
	# top hat
	o.cyl(0.75, 0.72, 1.2, Color(0.07, 0.07, 0.09), Vector3(0, 5.85, 0))
	o.cyl(1.15, 1.15, 0.1, Color(0.07, 0.07, 0.09), Vector3(0, 5.3, 0))
	o.cyl(0.77, 0.77, 0.22, Color(0.8, 0.12, 0.15), Vector3(0, 5.5, 0))
	o.box(Vector3(0.35, 0.22, 0.03), WHITE, Vector3(0.55, 6.1, 0.55), Vector3(0, 0.8, 0.2))


## Arm hanging from a shoulder pivot at the origin, holding a shopping bag.
static func _boss_arm(o, bag: Color, stripe: Color) -> void:
	var suit := Color(0.3, 0.22, 0.38)
	o.box(Vector3(0.65, 2.0, 0.65), suit, Vector3(0, -1.0, 0))
	o.box(Vector3(0.72, 0.22, 0.72), WHITE, Vector3(0, -2.05, 0))
	o.sphere(0.32, Color(0.92, 0.75, 0.6), Vector3(0, -2.3, 0))
	o.box(Vector3(1.05, 1.15, 0.5), bag, Vector3(0, -3.05, 0.15))
	o.box(Vector3(1.07, 0.2, 0.52), stripe, Vector3(0, -2.85, 0.15))
	o.box(Vector3(0.06, 0.5, 0.06), Color(0.3, 0.3, 0.3), Vector3(-0.25, -2.35, 0.15), Vector3(0, 0, -0.4))
	o.box(Vector3(0.06, 0.5, 0.06), Color(0.3, 0.3, 0.3), Vector3(0.25, -2.35, 0.15), Vector3(0, 0, 0.4))
