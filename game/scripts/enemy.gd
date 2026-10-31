extends Node3D
## A waste monster. Movement & collisions are driven centrally by game.gd;
## this script holds state, builds visuals and runs boss behaviour.

const MF = preload("res://scripts/mesh_factory.gd")
const Models = preload("res://scripts/enemy_models.gd")
const Fx = preload("res://scripts/fx.gd")

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
var elite := false
var phase := 1
var dead := false
var slow_t := 0.0
var move_override = null  # Vector3 while charging
var use_batch := false  # set by game.gd; the menu backdrop draws its own meshes
var batched := false    # drawn by the game's BatchRenderer instead of own meshes
var glow_on := true
var draw_model := {}     # cached by game._draw_batches
var draw_keys: Array = []
var blob_r := 0.0        # blob shadow radius

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
var _spiral_t := 3.0
var _slam_t := 2.0


func setup(k: String, hp_scale: float, dmg_scale: float, is_elite := false) -> void:
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
	_special_t = 2.0 if k != "spray" else randf_range(1.5, 3.0)
	_charge_t = 4.0
	_body = Node3D.new()
	add_child(_body)
	_build_visual()
	if is_elite and not is_boss:
		_make_elite()
	blob_r = radius * 1.6 * (1.4 if elite else 1.0)


## Elite variant: much tougher, bigger, golden aura, drops a reward crate.
func _make_elite() -> void:
	elite = true
	max_hp *= GameData.ELITE_HP
	hp = max_hp
	damage *= GameData.ELITE_DMG
	xp *= 4
	radius *= 1.3
	knock_resist *= 0.4
	speed *= 1.1
	_base_scale *= GameData.ELITE_SCALE
	_body.scale = Vector3.ONE * _base_scale
	Fx.ground(self, {"color": Color(1.0, 0.8, 0.25, 0.9), "inner": 0.7, "softness": 0.25, "dashes": 6.0, "spin": 3.0, "intensity": 1.6}, radius * 2.0, 0.05)
	var sparks := Fx.burst(Color(1.0, 0.85, 0.35), 8, 0.9, Vector2(0.5, 1.5), 0.07, true, 1.5)
	sparks.one_shot = false
	sparks.explosiveness = 0.0
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = radius
	sparks.position.y = 0.6
	add_child(sparks)
	# the enemy is not in the tree yet; world-space particles need a transform
	sparks.set_deferred("emitting", true)


func _add_model(parent: Node3D, model_kind: String, shadows := true) -> void:
	if use_batch and not is_boss:
		# regular monsters are drawn in bulk (see game._draw_batches)
		batched = true
		return
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


func is_flashing() -> bool:
	return _flashing


## World transform of the animated body (for batched drawing).
func body_transform() -> Transform3D:
	return transform * _body.transform


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
	# pure animation is skipped for monsters well outside the camera view
	if kind in ["bag", "bottle", "battery", "rot", "rot_small", "box"]:
		var pp: Vector3 = game.player.position
		if absf(position.x - pp.x) > 24.0 or absf(position.z - pp.z) > 20.0:
			return
	if kind == "miniboss" or kind == "boss":
		var p := 1
		if kind == "boss":
			p = 3 if hp < max_hp * 0.33 else (2 if hp < max_hp * 0.66 else 1)
		elif hp < max_hp * 0.5:
			p = 2
		if p != phase:
			phase = p
			game.on_boss_phase(self)
	match kind:
		"bag":
			_body.position.y = sin(_anim_t * 4.0) * 0.15 + 0.1
			_body.rotation.z = sin(_anim_t * 3.0) * 0.25
			_body.rotation.x = 0.15
		"bottle", "battery":
			_body.rotation.z = sin(_anim_t * 9.0) * 0.14
			_body.position.y = absf(sin(_anim_t * 9.0)) * 0.06
			glow_on = int(_anim_t * 10.0) % 2 == 0
			if _glow:
				_glow.visible = glow_on
		"rot", "rot_small":
			var q := sin(_anim_t * 6.0) * 0.08
			_body.scale = Vector3(s * (1.0 + q), s * (1.0 - q), s)
		"box":
			_body.position.y = absf(sin(_anim_t * 5.0)) * 0.18
			_body.rotation.z = sin(_anim_t * 5.0) * 0.06
		"spray":
			_spray_think(delta, game)
		"foam":
			# skittering zig-zag chase
			_body.position.y = absf(sin(_anim_t * 14.0)) * 0.12
			var to: Vector3 = game.player.position - position
			to.y = 0.0
			var dir := to.normalized()
			var side := Vector3(-dir.z, 0, dir.x) * sin(_anim_t * 5.0) * 0.9
			move_override = (dir + side).normalized() * speed * speed_mult
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
			if phase >= 2:
				# enraged: trash slams around the player + rings of junk
				_charge_t -= delta
				if _charge_t <= 0.0:
					_charge_t = 4.0
					for i in 3:
						var off := Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5)) if i > 0 else Vector3.ZERO
						game.hazards.slam(game.player.position + off, 2.2, 1.1, 16.0, Color(1.0, 0.55, 0.2))
					game.hazards.ring(position, 12, 7.0, 10.0, Color(0.75, 0.6, 0.3), randf() * TAU)
		"boss":
			_boss_think(delta, game)


## Ranged aerosol: keeps its distance, strafes and puffs toxic clouds.
func _spray_think(delta: float, game) -> void:
	var to: Vector3 = game.player.position - position
	to.y = 0.0
	var d := to.length()
	var dir := to / maxf(d, 0.001)
	var side := Vector3(-dir.z, 0, dir.x) * (1.0 if int(_anim_t * 0.3) % 2 == 0 else -1.0)
	if d < 6.5:
		move_override = (-dir * 0.8 + side * 0.4).normalized() * speed * speed_mult
	elif d < 10.0:
		move_override = side * speed * 0.6 * speed_mult
	else:
		move_override = null
	_special_t -= delta
	_body.rotation.z = sin(_anim_t * 7.0) * 0.08
	if _special_t < 0.45:
		# wind-up shake before a puff
		_body.position.x = sin(_anim_t * 70.0) * 0.05
	if _special_t <= 0.0:
		_special_t = randf_range(2.4, 3.2)
		_body.position.x = 0.0
		if d < 16.0:
			game.hazards.shoot(position + dir * 0.6, dir * 7.5, damage * 1.3, Color(0.7, 1.0, 0.3), 0.35)


func _boss_think(delta: float, game) -> void:
	var enraged := phase >= 3
	speed_mult = 1.35 if enraged else 1.0
	if phase >= 2:
		# phase 2+: spirals of receipts and bills
		_spiral_t -= delta
		if _spiral_t <= 0.0:
			_spiral_t = 4.5 if enraged else 5.5
			for w in 3:
				game.get_tree().create_timer(w * 0.35, false).timeout.connect(func():
					if not dead:
						game.hazards.ring(position, 14, 8.0, 12.0, Color(1.0, 0.85, 0.3), w * 0.22 + _anim_t))
	if enraged:
		# phase 3: a line of slams marching toward the player
		_slam_t -= delta
		if _slam_t <= 0.0:
			_slam_t = 3.6
			var to: Vector3 = game.player.position - position
			to.y = 0.0
			var dir := to.normalized()
			for i in 5:
				var at: Vector3 = position + dir * (3.0 + i * 2.6)
				game.get_tree().create_timer(i * 0.12, false).timeout.connect(func():
					if not dead:
						game.hazards.slam(at, 1.9, 0.9, 20.0, Color(0.85, 0.35, 0.9)))
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
