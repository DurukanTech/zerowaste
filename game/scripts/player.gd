extends Node3D
## The Zero Waste Volunteer: movement, stats, XP, buffs, weapon ownership.

const MF = preload("res://scripts/mesh_factory.gd")
const WEAPON_SCRIPTS := {
	"glass": preload("res://scripts/weapons/glass_shards.gd"),
	"boomerang": preload("res://scripts/weapons/boomerang.gd"),
	"compost": preload("res://scripts/weapons/compost_ring.gd"),
	"turbine": preload("res://scripts/weapons/wind_turbine.gd"),
	"solar": preload("res://scripts/weapons/solar_beam.gd"),
	"tote": preload("res://scripts/weapons/tote_wave.gd"),
}
const RADIUS := 0.45
const BASE_SPEED := 6.5
const BASE_PICKUP := 2.6

var game
var max_hp := 100.0
var hp := 100.0
var level := 1
var xp := 0.0
var xp_need := 5.0
var weapons: Array = []
var passives := {}
var buffs := {}  # buff id -> seconds left
var facing := 0.0
var moving := false

var _body: Node3D
var _body_meshes: Array[MeshInstance3D] = []
var _orig: Array[Material] = []
var _hurt_flash := 0.0
var _walk_t := 0.0


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var suit := Color(0.18, 0.62, 0.38)
	MF.cyl(_body, 0.32, 0.36, 0.9, suit, Vector3(0, 0.75, 0))
	MF.sphere(_body, 0.3, Color(0.95, 0.78, 0.62), Vector3(0, 1.45, 0))
	MF.cyl(_body, 0.32, 0.32, 0.12, Color(0.98, 0.82, 0.1), Vector3(0, 1.68, 0))  # cap
	MF.box(_body, Vector3(0.36, 0.06, 0.25), Color(0.98, 0.82, 0.1), Vector3(0, 1.64, 0.25))  # visor
	MF.box(_body, Vector3(0.5, 0.6, 0.28), Color(0.15, 0.4, 0.85), Vector3(0, 0.95, -0.38))  # backpack
	MF.box(_body, Vector3(0.62, 0.08, 0.02), Color(1, 1, 0.6), Vector3(0, 0.8, 0.35), false)  # reflective stripe
	MF.cyl(_body, 0.11, 0.11, 0.45, Color(0.2, 0.25, 0.3), Vector3(-0.15, 0.22, 0))
	MF.cyl(_body, 0.11, 0.11, 0.45, Color(0.2, 0.25, 0.3), Vector3(0.15, 0.22, 0))
	MF.eyes(_body, 1.48, 0.27, 0.1, 0.045)
	for c in _body.get_children():
		if c is MeshInstance3D:
			_body_meshes.append(c)
			_orig.append(c.material_override)
	# soft shadow blob for readability
	var blob := MF.inst(MF.cyl_mesh(0.6, 0.6, 0.02), MF.mat(Color(0, 0, 0, 0.3), 0.0, true), self, Vector3(0, 0.02, 0), false)
	blob.name = "Blob"


func tick(delta: float) -> void:
	var inp := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if game.autotest:
		# wander towards the bin that matches the most carried material
		var best = null
		for b in game.bins:
			if best == null or game.carried[b.mat_type] > game.carried[best.mat_type]:
				best = b
		var to: Vector3 = best.position - position
		inp = Vector2(to.x, to.z).normalized() if to.length() > 1.0 else Vector2.RIGHT
	var v := Vector3(inp.x, 0, inp.y)
	moving = v.length() > 0.1
	position += v * speed() * delta
	position.x = clampf(position.x, -GameData.ARENA_X, GameData.ARENA_X)
	position.z = clampf(position.z, GameData.ARENA_Z_MIN, GameData.ARENA_Z_MAX)
	if moving:
		facing = lerp_angle(facing, atan2(v.x, v.z), minf(1.0, 14.0 * delta))
		_walk_t += delta * 12.0
		_body.position.y = absf(sin(_walk_t)) * 0.12
		_body.rotation.z = sin(_walk_t) * 0.06
	else:
		_body.position.y = lerpf(_body.position.y, 0.0, 10.0 * delta)
		_body.rotation.z = 0.0
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


# --- stats -----------------------------------------------------------------

func plv(id: String) -> int:
	return passives.get(id, 0)


func speed() -> float:
	return BASE_SPEED * (1.0 + 0.1 * plv("bike")) * (1.3 if buffs.has("speed") else 1.0)


func damage_mult() -> float:
	return (1.0 + 0.1 * plv("power")) * (1.4 if buffs.has("damage") else 1.0)


func cooldown_mult() -> float:
	return (1.0 - 0.08 * plv("efficiency")) * (0.7 if buffs.has("firerate") else 1.0)


func pickup_radius() -> float:
	return BASE_PICKUP * (1.0 + 0.3 * plv("net"))


func xp_mult() -> float:
	return 1.0 + 0.1 * plv("awareness")


# --- health / xp -----------------------------------------------------------

func hurt(amount: float) -> void:
	if game.finished or amount <= 0.0:
		return
	hp -= amount
	if _hurt_flash <= 0.0:
		var red := MF.mat(Color(1, 0.25, 0.2), 1.0)
		for mi in _body_meshes:
			mi.material_override = red
	_hurt_flash = 0.1
	Sfx.play("hurt", -6, 0.22)
	game.add_shake(0.15)
	if hp <= 0.0:
		hp = 0.0
		game.on_player_died()


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


func add_xp(amount: float) -> void:
	xp += amount * xp_mult()
	while xp >= xp_need:
		xp -= xp_need
		level += 1
		xp_need = 5.0 + (level - 1) * 8.0 + pow(level - 1, 1.9)
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
