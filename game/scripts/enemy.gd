extends Node3D
## A waste monster. Movement & collisions are driven centrally by game.gd;
## this script holds state, builds visuals and runs boss behaviour.

const MF = preload("res://scripts/mesh_factory.gd")

var kind := ""
var hp := 1.0
var max_hp := 1.0
var speed := 1.0
var speed_mult := 1.0
var damage := 1.0
var xp := 1
var material_type := "plastic"
var radius := 0.5
var knock_resist := 1.0
var knock := Vector3.ZERO
var is_boss := false
var dead := false
var slow_t := 0.0
var move_override = null  # Vector3 while charging

var _flash := 0.0
var _flashing := false
var _body: Node3D
var _flash_meshes: Array[MeshInstance3D] = []
var _orig_mats: Array[Material] = []
var _anim_t := 0.0
var _special_t := 0.0
var _charge_state := 0  # 0 chase, 1 telegraph, 2 charge
var _charge_t := 0.0
var _charge_dir := Vector3.ZERO


func setup(k: String, hp_scale: float, dmg_scale: float) -> void:
	kind = k
	var d: Dictionary = GameData.ENEMIES[k]
	max_hp = d.hp * hp_scale
	hp = max_hp
	speed = d.speed * randf_range(0.92, 1.08)
	damage = d.damage * dmg_scale
	xp = d.xp
	material_type = d.material
	radius = d.radius
	knock_resist = d.knock
	is_boss = k == "miniboss" or k == "boss"
	_anim_t = randf() * TAU
	_special_t = 2.0
	_charge_t = 4.0
	_body = Node3D.new()
	add_child(_body)
	_build_visual()
	for c in _body.get_children():
		if c is MeshInstance3D:
			_flash_meshes.append(c)
			_orig_mats.append(c.material_override)


func _build_visual() -> void:
	match kind:
		"bag":
			MF.sphere(_body, 0.42, Color(0.96, 0.95, 0.88, 0.9), Vector3(0, 0.75, 0), true, 0.7)
			MF.box(_body, Vector3(0.12, 0.25, 0.06), Color(0.96, 0.95, 0.88), Vector3(-0.17, 1.15, 0), false)
			MF.box(_body, Vector3(0.12, 0.25, 0.06), Color(0.96, 0.95, 0.88), Vector3(0.17, 1.15, 0), false)
			MF.eyes(_body, 0.82, 0.36, 0.13, 0.065)
		"bottle":
			MF.cyl(_body, 0.26, 0.26, 0.85, Color(0.25, 0.75, 0.4, 0.85), Vector3(0, 0.45, 0))
			MF.cyl(_body, 0.1, 0.24, 0.32, Color(0.25, 0.75, 0.4, 0.85), Vector3(0, 1.03, 0))
			MF.cyl(_body, 0.11, 0.11, 0.1, Color(0.15, 0.35, 0.9), Vector3(0, 1.22, 0), false)
			MF.eyes(_body, 0.6, 0.24, 0.1, 0.06)
		"rot", "rot_small":
			var s := 1.0 if kind == "rot" else 0.6
			MF.sphere(_body, 0.55 * s, Color(0.42, 0.4, 0.14), Vector3(0, 0.45 * s, 0), true, 0.85 * s)
			MF.sphere(_body, 0.2 * s, Color(0.85, 0.2, 0.15), Vector3(0.3 * s, 0.75 * s, -0.1), false)
			MF.box(_body, Vector3(0.5, 0.12, 0.14) * s, Color(0.95, 0.85, 0.25), Vector3(-0.2 * s, 0.82 * s, 0.05), false)
			MF.eyes(_body, 0.55 * s, 0.48 * s, 0.17 * s, 0.08 * s, Color(0.95, 0.95, 0.6))
		"box":
			MF.box(_body, Vector3(1.0, 0.85, 1.0), Color(0.78, 0.6, 0.38), Vector3(0, 0.5, 0))
			var flap := MF.box(_body, Vector3(1.0, 0.06, 0.45), Color(0.7, 0.52, 0.32), Vector3(0, 0.98, 0.35), false)
			flap.rotation_degrees.x = -35
			MF.box(_body, Vector3(0.5, 0.08, 0.02), Color(0.2, 0.12, 0.05), Vector3(0, 0.4, 0.51), false)
			MF.eyes(_body, 0.65, 0.51, 0.22, 0.08)
		"battery":
			MF.cyl(_body, 0.2, 0.2, 0.55, Color(0.12, 0.12, 0.14), Vector3(0, 0.4, 0))
			MF.cyl(_body, 0.205, 0.205, 0.2, Color(1.0, 0.45, 0.1), Vector3(0, 0.6, 0))
			MF.cyl(_body, 0.07, 0.07, 0.1, Color(0.8, 0.8, 0.8), Vector3(0, 0.75, 0), false)
			MF.eyes(_body, 0.45, 0.2, 0.08, 0.05, Color(1, 0.9, 0.2))
		"miniboss":
			var cols := [Color(0.78, 0.6, 0.38), Color(0.96, 0.95, 0.88), Color(0.25, 0.75, 0.4), Color(0.42, 0.4, 0.14), Color(0.2, 0.5, 1.0), Color(1.0, 0.82, 0.1)]
			MF.sphere(_body, 1.6, Color(0.35, 0.33, 0.28), Vector3(0, 1.2, 0), true, 2.6)
			for i in 14:
				var a := float(i) / 14.0 * TAU
				var h := randf_range(0.5, 2.3)
				var p := Vector3(cos(a) * 1.3, h, sin(a) * 1.3) * randf_range(0.8, 1.05)
				if i % 2 == 0:
					var b := MF.box(_body, Vector3.ONE * randf_range(0.4, 0.7), cols[i % cols.size()], p)
					b.rotation = Vector3(randf(), randf(), randf())
				else:
					MF.sphere(_body, randf_range(0.25, 0.4), cols[i % cols.size()], p)
			MF.eyes(_body, 1.8, 1.45, 0.45, 0.22, Color(1, 0.3, 0.2))
			_add_name_label(3.4)
		"boss":
			var suit := Color(0.32, 0.25, 0.4)
			MF.box(_body, Vector3(2.6, 2.8, 1.8), suit, Vector3(0, 2.4, 0))
			MF.box(_body, Vector3(0.9, 1.2, 0.9), Color(0.2, 0.16, 0.25), Vector3(-0.7, 0.6, 0))
			MF.box(_body, Vector3(0.9, 1.2, 0.9), Color(0.2, 0.16, 0.25), Vector3(0.7, 0.6, 0))
			MF.sphere(_body, 0.95, Color(0.85, 0.7, 0.55), Vector3(0, 4.5, 0))
			# top hat & tie: the classic tycoon silhouette
			MF.cyl(_body, 0.7, 0.7, 1.0, Color(0.08, 0.08, 0.1), Vector3(0, 5.6, 0))
			MF.cyl(_body, 1.1, 1.1, 0.1, Color(0.08, 0.08, 0.1), Vector3(0, 5.1, 0))
			MF.box(_body, Vector3(0.4, 1.6, 0.1), Color(0.9, 0.15, 0.15), Vector3(0, 2.8, 0.92))
			# arms holding shopping bags
			MF.box(_body, Vector3(0.6, 2.2, 0.6), suit, Vector3(-1.7, 2.6, 0))
			MF.box(_body, Vector3(0.6, 2.2, 0.6), suit, Vector3(1.7, 2.6, 0))
			MF.box(_body, Vector3(1.0, 1.1, 0.5), Color(1.0, 0.82, 0.1), Vector3(-1.8, 1.1, 0.2))
			MF.box(_body, Vector3(1.0, 1.1, 0.5), Color(0.96, 0.95, 0.88), Vector3(1.8, 1.1, 0.2))
			MF.eyes(_body, 4.6, 0.85, 0.32, 0.13, Color(0.9, 0.1, 0.1))
			_add_name_label(6.8)


func _add_name_label(h: float) -> void:
	var l := Label3D.new()
	l.text = Loc.pick(GameData.ENEMIES[kind].name)
	l.font_size = 64
	l.outline_size = 14
	l.modulate = Color(1, 0.85, 0.3)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = Vector3(0, h, 0)
	l.pixel_size = 0.01
	add_child(l)


func hit_flash() -> void:
	_flash = 0.08
	if not _flashing:
		_flashing = true
		var white := MF.mat(Color(1, 1, 1), 1.5)
		for mi in _flash_meshes:
			mi.material_override = white


func think(delta: float, game) -> void:
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			_flashing = false
			for i in _flash_meshes.size():
				_flash_meshes[i].material_override = _orig_mats[i]
	if slow_t > 0.0:
		slow_t -= delta
		speed_mult = 0.6
	else:
		speed_mult = 1.0
	_anim_t += delta
	match kind:
		"bag":
			_body.position.y = sin(_anim_t * 4.0) * 0.15 + 0.1
			_body.rotation.z = sin(_anim_t * 3.0) * 0.25
		"bottle", "battery":
			_body.rotation.z = sin(_anim_t * 9.0) * 0.12
		"rot", "rot_small":
			_body.scale = Vector3(1.0 + sin(_anim_t * 6.0) * 0.08, 1.0 - sin(_anim_t * 6.0) * 0.08, 1.0)
		"box":
			_body.position.y = absf(sin(_anim_t * 5.0)) * 0.15
		"miniboss":
			_body.rotation.y += delta * 0.4
			_special_t -= delta
			if _special_t <= 0.0:
				_special_t = 3.5
				for i in 4:
					var a := randf() * TAU
					game.spawn_enemy("bag", position + Vector3(cos(a), 0, sin(a)) * (radius + 1.0))
		"boss":
			_boss_think(delta, game)


func _boss_think(delta: float, game) -> void:
	var enraged := hp < max_hp * 0.5
	speed_mult = 1.35 if enraged else 1.0
	_special_t -= delta
	if _special_t <= 0.0:
		_special_t = 5.0
		var minion := "battery" if enraged else "bag"
		for i in 6:
			var a := float(i) / 6.0 * TAU
			game.spawn_enemy(minion, position + Vector3(cos(a), 0, sin(a)) * (radius + 1.5))
	_charge_t -= delta
	match _charge_state:
		0:
			_body.position.y = absf(sin(_anim_t * 3.0)) * 0.2
			if _charge_t <= 0.0:
				_charge_state = 1
				_charge_t = 0.8
				Sfx.play("warning", -6)
		1:
			# telegraph: shake & flash red
			_body.position.x = sin(_anim_t * 60.0) * 0.12
			if int(_anim_t * 12.0) % 2 == 0:
				hit_flash()
			move_override = Vector3.ZERO
			if _charge_t <= 0.0:
				_charge_state = 2
				_charge_t = 0.7
				var to: Vector3 = game.player.position - position
				to.y = 0
				_charge_dir = to.normalized()
				Sfx.play("whoosh", 0.0)
		2:
			move_override = _charge_dir * (17.0 if enraged else 14.0)
			if _charge_t <= 0.0:
				_charge_state = 0
				_charge_t = 4.5 if enraged else 6.0
				move_override = null
				_body.position.x = 0
