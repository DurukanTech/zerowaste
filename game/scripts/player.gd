extends Node3D
## The Zero Waste Volunteer: movement, stats, XP, buffs, weapon ownership.

const MF = preload("res://scripts/mesh_factory.gd")
const ModelBuilder = preload("res://scripts/model_builder.gd")
const Fx = preload("res://scripts/fx.gd")
const WEAPON_SCRIPTS := {
	"glass": preload("res://scripts/weapons/glass_shards.gd"),
	"boomerang": preload("res://scripts/weapons/boomerang.gd"),
	"compost": preload("res://scripts/weapons/compost_ring.gd"),
	"turbine": preload("res://scripts/weapons/wind_turbine.gd"),
	"solar": preload("res://scripts/weapons/solar_beam.gd"),
	"tote": preload("res://scripts/weapons/tote_wave.gd"),
	"tree": preload("res://scripts/weapons/tree_planter.gd"),
	"water": preload("res://scripts/weapons/water_jet.gd"),
}
const RADIUS := 0.45
const BASE_SPEED := 6.5
const BASE_PICKUP := 2.6
const DASH_SPEED := 24.0
const DASH_TIME := 0.17
const DASH_CD := 1.6
const ULT_MAX := 100.0

const SUIT := Color(0.16, 0.58, 0.36)
const VEST := Color(0.98, 0.8, 0.12)
const SKIN := Color(0.96, 0.8, 0.65)

static var _parts := {}

var game
var max_hp := 100.0
var hp := 100.0
var level := 1
var xp := 0.0
var xp_need := 5.0
var weapons: Array = []
var passives := {}
var buffs := {}  # buff id -> seconds left
var bonus := {}  # stat card id -> times taken
var facing := 0.0
var moving := false
var ult := 0.0
var dash_cd := 0.0
var rerolls := 0
var revives := 0

var _body: Node3D
var _head: Node3D
var _arms: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _body_meshes: Array[MeshInstance3D] = []
var _orig: Array[Material] = []
var _ring: MeshInstance3D
var _dust: CPUParticles3D
var _hurt_flash := 0.0
var _walk_t := 0.0
var _idle_t := 0.0
var _dash_t := 0.0
var _dash_dir := Vector3.ZERO
var _iframes := 0.0
var _bot_t := 0.0


func _ready() -> void:
	if game != null:
		max_hp += 10.0 * meta("hp")
		hp = max_hp
		rerolls = meta("reroll")
		revives = meta("revive")
	_build_parts()
	_body = Node3D.new()
	add_child(_body)
	_attach(_body, "torso")
	_head = Node3D.new()
	_head.position = Vector3(0, 1.38, 0)
	_body.add_child(_head)
	_attach(_head, "head")
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.37, 1.24, 0)
		_body.add_child(arm)
		_attach(arm, "arm_r" if side > 0 else "arm_l")
		_arms.append(arm)
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.13, 0.66, 0)
		_body.add_child(leg)
		_attach(leg, "leg")
		_legs.append(leg)
	# hero ring keeps the player readable inside a crowd
	_ring = Fx.ground(self, {"color": Color(0.45, 1.0, 0.6, 0.9), "inner": 0.78, "softness": 0.18, "dashes": 6.0, "spin": 2.0, "intensity": 1.3}, 0.95, 0.04)
	_dust = Fx.burst(Color(0.75, 0.68, 0.55), 10, 0.5, Vector2(0.5, 1.5), 0.12, false, -2.0)
	_dust.one_shot = false
	_dust.explosiveness = 0.0
	_dust.spread = 40.0
	_dust.local_coords = false
	add_child(_dust)


func _attach(parent: Node3D, part: String) -> void:
	var mi := MF.inst(_parts[part], MF.vc_mat(), parent)
	_body_meshes.append(mi)
	_orig.append(mi.material_override)


static func _build_parts() -> void:
	if not _parts.is_empty():
		return
	var navy := Color(0.14, 0.2, 0.32)
	var white := Color(0.94, 0.95, 0.97)
	# torso: suit, high-vis vest with reflective stripes, belt, backpack
	var t := ModelBuilder.new()
	t.capsule(0.28, 0.9, SUIT, Vector3(0, 0.98, 0))
	t.cyl(0.305, 0.3, 0.46, VEST, Vector3(0, 1.02, 0))
	for y in [0.92, 1.1]:
		t.cyl(0.31, 0.31, 0.05, white, Vector3(0, y, 0))
	t.cyl(0.295, 0.295, 0.07, Color(0.3, 0.2, 0.12), Vector3(0, 0.74, 0))
	t.box(Vector3(0.1, 0.07, 0.03), Color(0.85, 0.75, 0.3), Vector3(0, 0.74, 0.29))
	t.box(Vector3(0.44, 0.52, 0.24), Color(0.15, 0.42, 0.85), Vector3(0, 1.04, -0.33))
	t.box(Vector3(0.46, 0.12, 0.26), Color(0.1, 0.3, 0.65), Vector3(0, 1.32, -0.33))
	for i in 3:
		var a := float(i) / 3.0 * TAU
		t.prism(Vector3(0.1, 0.1, 0.02), white, Vector3(sin(a) * 0.09, 1.04 + cos(a) * 0.09, -0.46), Vector3(0, 0, -a))
	for sx in [-1.0, 1.0]:
		t.box(Vector3(0.07, 0.5, 0.04), Color(0.1, 0.3, 0.65), Vector3(sx * 0.14, 1.08, 0.27), Vector3(-0.15, 0, 0))
	t.cyl(0.11, 0.12, 0.1, SKIN, Vector3(0, 1.36, 0))
	_parts["torso"] = t.commit()
	# head (pivot at neck): face, hair, cap with leaf logo
	var h := ModelBuilder.new()
	h.sphere(0.26, SKIN, Vector3(0, 0.22, 0), Vector3.ONE, Vector3.ZERO, 2)
	h.sphere(0.268, Color(0.35, 0.22, 0.12), Vector3(0, 0.27, -0.04), Vector3(1, 0.75, 1))
	h.sphere(0.275, SUIT, Vector3(0, 0.34, 0), Vector3(1, 0.55, 1))
	h.box(Vector3(0.32, 0.03, 0.22), Color(0.12, 0.45, 0.28), Vector3(0, 0.3, 0.26), Vector3(-0.15, 0, 0))
	h.prism(Vector3(0.09, 0.12, 0.02), Color(0.7, 1.0, 0.5), Vector3(0, 0.42, 0.23), Vector3(-0.4, 0, 0))
	for sx in [-1.0, 1.0]:
		h.sphere(0.04, Color(0.08, 0.06, 0.06), Vector3(sx * 0.09, 0.23, 0.23), Vector3(1, 1.2, 0.5))
		h.sphere(0.045, Color(1.0, 0.6, 0.6), Vector3(sx * 0.15, 0.15, 0.2), Vector3(1, 0.6, 0.4), Vector3.ZERO, 0)
		h.sphere(0.06, SKIN, Vector3(sx * 0.26, 0.22, 0), Vector3(0.5, 1, 1), Vector3.ZERO, 0)
	h.box(Vector3(0.1, 0.025, 0.02), Color(0.5, 0.2, 0.15), Vector3(0, 0.12, 0.245))
	_parts["head"] = h.commit()
	# arms (pivot at shoulder); the right one carries a litter grabber
	for side in ["l", "r"]:
		var a := ModelBuilder.new()
		a.sphere(0.11, SUIT, Vector3.ZERO)
		a.capsule(0.09, 0.5, SUIT, Vector3(0, -0.24, 0))
		a.sphere(0.1, Color(0.98, 0.6, 0.15), Vector3(0, -0.5, 0.02))
		if side == "r":
			a.cyl(0.022, 0.022, 0.8, Color(0.6, 0.62, 0.65), Vector3(0, -0.62, 0.3), Vector3(1.1, 0, 0))
			a.box(Vector3(0.12, 0.04, 0.1), Color(0.95, 0.75, 0.1), Vector3(0, -0.78, 0.66), Vector3(0.4, 0, 0))
			a.box(Vector3(0.03, 0.1, 0.03), Color(0.3, 0.3, 0.3), Vector3(-0.05, -0.8, 0.72))
			a.box(Vector3(0.03, 0.1, 0.03), Color(0.3, 0.3, 0.3), Vector3(0.05, -0.8, 0.72))
		_parts["arm_" + side] = a.commit()
	# leg (pivot at hip)
	var l := ModelBuilder.new()
	l.capsule(0.11, 0.55, navy, Vector3(0, -0.3, 0))
	l.box(Vector3(0.2, 0.14, 0.32), Color(0.38, 0.24, 0.12), Vector3(0, -0.6, 0.05))
	l.box(Vector3(0.21, 0.04, 0.33), Color(0.2, 0.12, 0.06), Vector3(0, -0.66, 0.05))
	_parts["leg"] = l.commit()


func tick(delta: float) -> void:
	var inp := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var want_dash := Input.is_action_just_pressed("dash")
	var want_ult := Input.is_action_just_pressed("ultimate")
	if game.autotest and not game.showcase:
		inp = _bot_input()
		_bot_t += delta
		want_dash = _bot_t > 3.0
		if want_dash:
			_bot_t = 0.0
		want_ult = true
	var v := Vector3(inp.x, 0, inp.y)
	moving = v.length() > 0.1
	dash_cd = maxf(0.0, dash_cd - delta)
	_iframes = maxf(0.0, _iframes - delta)
	if want_dash and dash_cd <= 0.0 and _dash_t <= 0.0:
		_start_dash(v.normalized() if moving else Vector3(sin(facing), 0, cos(facing)))
	if want_ult and ult >= ULT_MAX:
		ult = 0.0
		game.ultimate_blast()
	if _dash_t > 0.0:
		_dash_t -= delta
		position += _dash_dir * DASH_SPEED * delta
		_body.scale = Vector3(0.85, 0.9, 1.3)
		if _dash_t <= 0.0:
			_body.scale = Vector3.ONE
	else:
		position += v * speed() * delta
	position.x = clampf(position.x, -GameData.ARENA_X, GameData.ARENA_X)
	position.z = clampf(position.z, GameData.ARENA_Z_MIN, GameData.ARENA_Z_MAX)
	if moving:
		facing = lerp_angle(facing, atan2(v.x, v.z), minf(1.0, 14.0 * delta))
	animate(delta, moving)
	_body.rotation.y = facing
	for b in buffs.keys():
		buffs[b] -= delta
		if buffs[b] <= 0.0:
			buffs.erase(b)
	var regen := 0.3 * plv("canteen")
	if regen > 0.0:
		heal(regen * delta)
	if _hurt_flash > 0.0:
		_hurt_flash -= delta
		if _hurt_flash <= 0.0:
			for i in _body_meshes.size():
				_body_meshes[i].material_override = _orig[i]
	# blink while invulnerable (after a revive)
	_body.visible = _iframes <= 0.35 or int(_iframes * 14.0) % 2 == 0


## Autotest pilot: walk to the fullest bin, or to the e-waste point when it is up.
func _bot_input() -> Vector2:
	var target: Vector3 = position
	var best = null
	for b in game.bins:
		if best == null or game.carried[b.mat_type] > game.carried[best.mat_type]:
			best = b
	target = best.position
	var ep = game.sorting.ewaste_point
	if ep != null and game.sorting.ewaste_carried > 0:
		target = ep.position
	var to: Vector3 = target - position
	return Vector2(to.x, to.z).normalized() if to.length() > 1.0 else Vector2.RIGHT


func _start_dash(dir: Vector3) -> void:
	_dash_dir = dir
	_dash_t = DASH_TIME
	dash_cd = DASH_CD * (1.0 - 0.12 * meta("dash"))
	_iframes = maxf(_iframes, DASH_TIME + 0.12)
	facing = atan2(dir.x, dir.z)
	var from := position
	var to := position + dir * DASH_SPEED * DASH_TIME
	game.fx.streak(from, to, Color(0.55, 1.0, 0.7))
	Sfx.play("dash")


## Walk cycle / idle breathing. Also used by the menu backdrop.
func animate(delta: float, walking: bool) -> void:
	_idle_t += delta
	_ring.rotation.y += delta * 0.8
	if walking:
		_walk_t += delta * 11.0 * speed() / BASE_SPEED
		var s := sin(_walk_t)
		_legs[0].rotation.x = s * 0.75
		_legs[1].rotation.x = -s * 0.75
		_arms[0].rotation.x = -s * 0.6
		_arms[1].rotation.x = s * 0.45 - 0.3
		_body.position.y = absf(cos(_walk_t)) * 0.08
		_body.rotation.x = 0.08
		_head.rotation.x = -0.05
	else:
		var k := minf(1.0, 10.0 * delta)
		for i in 2:
			_legs[i].rotation.x = lerpf(_legs[i].rotation.x, 0.0, k)
		_arms[0].rotation.x = lerpf(_arms[0].rotation.x, sin(_idle_t * 2.0) * 0.05, k)
		_arms[1].rotation.x = lerpf(_arms[1].rotation.x, -0.3 + sin(_idle_t * 2.0) * 0.05, k)
		_body.position.y = lerpf(_body.position.y, sin(_idle_t * 2.0) * 0.015, k)
		_body.rotation.x = lerpf(_body.rotation.x, 0.0, k)
		_head.rotation.x = sin(_idle_t * 1.3) * 0.04
	_dust.emitting = walking


# --- stats -----------------------------------------------------------------

func plv(id: String) -> int:
	return passives.get(id, 0)


## Bought menu upgrades (ignored by the autotest so it stays comparable).
func meta(id: String) -> int:
	if game == null or game.autotest:
		return 0
	return Meta.lv(id)


func speed() -> float:
	var flood: float = game.events.player_speed_mult() if game != null and game.events != null else 1.0
	return BASE_SPEED * (1.0 + 0.1 * plv("bike") + 0.04 * meta("speed") + 0.03 * bn("s_speed")) * (1.3 if buffs.has("speed") else 1.0) * flood


func damage_mult() -> float:
	return (1.0 + 0.1 * plv("power") + 0.05 * meta("dmg") + 0.04 * bn("s_dmg")) * (1.4 if buffs.has("damage") else 1.0)


func bn(id: String) -> int:
	return bonus.get(id, 0)


func add_stat(id: String) -> void:
	bonus[id] = bn(id) + 1
	if id == "s_hp":
		max_hp += 8.0
		heal(8.0)


## Rough build strength: every card taken counts, evolutions count extra.
## Used by adaptive difficulty and the final boss's health.
func power_score() -> float:
	var p := 0.0
	for w in weapons:
		p += mini(w.level, GameData.WEAPON_MAX) + (4.0 if w.evolved else 0.0)
	for id in passives:
		p += passives[id]
	for id in bonus:
		p += bonus[id] * 0.5
	return p


func area_mult() -> float:
	return 1.0 + 0.1 * plv("seeds") + 0.04 * bn("s_area")


func armor_mult() -> float:
	return 1.0 - 0.07 * plv("repair")


func carry_cap() -> int:
	return GameData.CARRY_CAP + 5 * meta("carry")


func add_ult(amount: float) -> void:
	ult = minf(ULT_MAX, ult + amount * (1.0 + 0.15 * meta("ult")))


func is_dashing() -> bool:
	return _dash_t > 0.0


func cooldown_mult() -> float:
	return (1.0 - 0.08 * plv("efficiency")) * maxf(0.6, 1.0 - 0.03 * bn("s_cd")) * (0.7 if buffs.has("firerate") else 1.0)


func pickup_radius() -> float:
	return BASE_PICKUP * (1.0 + 0.3 * plv("net") + 0.12 * meta("pickup") + 0.08 * bn("s_pickup"))


func xp_mult() -> float:
	return 1.0 + 0.1 * plv("awareness") + 0.06 * meta("xp")


# --- health / xp -----------------------------------------------------------

func hurt(amount: float) -> void:
	if game.finished or amount <= 0.0 or _iframes > 0.0:
		return
	amount *= armor_mult()
	game.stat_taken += amount
	game.on_player_hurt()
	hp -= amount
	if _hurt_flash <= 0.0:
		var red := MF.mat(Color(1, 0.25, 0.2), 1.0)
		for mi in _body_meshes:
			mi.material_override = red
	_hurt_flash = 0.1
	Sfx.play("hurt")
	game.add_shake(0.15)
	game.hud.hurt_flash()
	if hp <= 0.0:
		if revives > 0:
			revives -= 1
			hp = max_hp * 0.5
			_iframes = 2.5
			game.on_player_revived()
			return
		hp = 0.0
		game.on_player_died()


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


func add_xp(amount: float) -> void:
	xp += amount * xp_mult()
	while xp >= xp_need:
		xp -= xp_need
		level += 1
		xp_need = 6.0 + (level - 1) * 9.0 + pow(level - 1, 2.15)
		game.on_level_up()


func apply_buff(id: String, duration: float) -> void:
	buffs[id] = maxf(buffs.get(id, 0.0), duration)


# --- upgrades --------------------------------------------------------------

func weapon_level(id: String) -> int:
	for w in weapons:
		if w.id == id:
			return w.level
	return 0


func add_or_upgrade_weapon(id: String) -> void:
	for w in weapons:
		if w.id == id:
			w.upgrade()
			return
	if weapons.size() >= GameData.MAX_WEAPONS:
		return
	var w = WEAPON_SCRIPTS[id].new()
	w.id = id
	game.weapon_root.add_child(w)
	w.setup(game, self)
	weapons.append(w)


func add_or_upgrade_passive(id: String) -> void:
	passives[id] = plv(id) + 1
	if id == "canteen":
		max_hp += 20.0
		hp += 20.0


func evolve_weapon(id: String) -> void:
	for w in weapons:
		if w.id == id:
			w.evolve()


func is_evolved(id: String) -> bool:
	for w in weapons:
		if w.id == id:
			return w.evolved
	return false
