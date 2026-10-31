extends Node3D
## A waste monster. Movement & collisions are driven centrally by game.gd;
## this script holds state, builds visuals and runs boss behaviour.

const MF = preload("res://scripts/mesh_factory.gd")
const Models = preload("res://scripts/enemy_models.gd")

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
var _flash_cd := 0.0
var _flashing := false
var _body: Node3D
var _base_scale := 1.0
var _flash_meshes: Array[MeshInstance3D] = []
var _orig_mats: Array[Material] = []
var _glow: MeshInstance3D
var _arms: Array[Node3D] = []
var _flies: Node3D
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


func _add_model(parent: Node3D, model_kind: String, shadows := true) -> void:
	var m := Models.get_model(model_kind)
	if m.opaque:
		_track(MF.inst(m.opaque, MF.vc_mat(), parent, Vector3.ZERO, shadows))
	if m.alpha:
		_track(MF.inst(m.alpha, MF.vc_mat(true), parent, Vector3.ZERO, shadows))
	if m.glow:
		_glow = MF.inst(m.glow, MF.vc_mat(false, 4.0), parent, Vector3.ZERO, false)


func _track(mi: MeshInstance3D) -> void:
	_flash_meshes.append(mi)
	_orig_mats.append(mi.material_override)


func _build_visual() -> void:
	# regular monsters are drawn a bit larger than their hit radius for readability
	if not is_boss:
		_base_scale = 0.75 if kind == "rot_small" else 1.25
		_body.scale = Vector3.ONE * _base_scale
	_add_model(_body, kind)
	match kind:
		"miniboss":
			_flies = Node3D.new()
			_body.add_child(_flies)
			for i in 6:
				MF.sphere(_flies, 0.07, Color(0.05, 0.05, 0.05), Vector3.ZERO, false)
			_add_name_label(3.6)
		"boss":
			for side in [-1.0, 1.0]:
				var pivot := Node3D.new()
				pivot.position = Vector3(side * 1.75, 3.6, 0)
				_body.add_child(pivot)
				_add_model(pivot, "boss_arm_l" if side < 0 else "boss_arm_r")
				_arms.append(pivot)
			_add_name_label(7.2)


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
	# rate-limited so constantly-hit bosses don't stay lit up permanently
	if _flash_cd > 0.0:
		return
	_flash = 0.06
	_flash_cd = 0.16
	if not _flashing:
		_flashing = true
		var white := MF.flash_mat()
		for mi in _flash_meshes:
			mi.material_override = white


func think(delta: float, game) -> void:
	_flash_cd -= delta
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
	var s := _base_scale
	match kind:
		"bag":
			_body.position.y = sin(_anim_t * 4.0) * 0.15 + 0.1
			_body.rotation.z = sin(_anim_t * 3.0) * 0.25
			_body.rotation.x = 0.15
		"bottle", "battery":
			_body.rotation.z = sin(_anim_t * 9.0) * 0.14
			_body.position.y = absf(sin(_anim_t * 9.0)) * 0.06
			if _glow:
				_glow.visible = int(_anim_t * 10.0) % 2 == 0
		"rot", "rot_small":
			var q := sin(_anim_t * 6.0) * 0.08
			_body.scale = Vector3(s * (1.0 + q), s * (1.0 - q), s)
		"box":
			_body.position.y = absf(sin(_anim_t * 5.0)) * 0.18
			_body.rotation.z = sin(_anim_t * 5.0) * 0.06
		"miniboss":
			_body.rotation.y = sin(_anim_t * 0.8) * 0.25
			_body.scale = Vector3(1.0 + sin(_anim_t * 2.0) * 0.03, 1.0 - sin(_anim_t * 2.0) * 0.03, 1.0)
			for i in _flies.get_child_count():
				var a := _anim_t * (2.0 + i * 0.3) + i * 1.3
				_flies.get_child(i).position = Vector3(cos(a) * 2.0, 2.6 + sin(a * 1.7) * 0.4, sin(a) * 2.0)
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
			# heavy stomp walk with swinging shopping bags
			var w := sin(_anim_t * 3.0)
			_body.position.y = absf(w) * 0.2
			_body.rotation.z = w * 0.04
			_arms[0].rotation.x = w * 0.5
			_arms[1].rotation.x = -w * 0.5
			if _charge_t <= 0.0:
				_charge_state = 1
				_charge_t = 0.8
				Sfx.play("warning", -6)
		1:
			# telegraph: raise the bags, shake & flash
			_body.position.x = sin(_anim_t * 60.0) * 0.12
			for arm in _arms:
				arm.rotation.x = lerpf(arm.rotation.x, -2.4, 0.2)
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
			_body.rotation.x = 0.25
			for arm in _arms:
				arm.rotation.x = 1.2
			if _charge_t <= 0.0:
				_charge_state = 0
				_charge_t = 4.5 if enraged else 6.0
				move_override = null
				_body.position.x = 0
				_body.rotation.x = 0
