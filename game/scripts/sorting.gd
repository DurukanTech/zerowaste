extends Node3D
## The recycling layer: color bins, deposits with a combo streak, and the
## timed e-waste collection point.

const MF = preload("res://scripts/mesh_factory.gd")
const ModelBuilder = preload("res://scripts/model_builder.gd")
const Fx = preload("res://scripts/fx.gd")
const RecycleBin = preload("res://scripts/recycle_bin.gd")

const COMBO_WINDOW := 25.0
const COMBO_MIN := 5        # materials needed for a deposit to count toward the streak
const COMBO_MAX := 6
const EWASTE_CAP := 20
const EWASTE_FIRST := 95.0
const EWASTE_EVERY := 105.0
const EWASTE_LIFE := 45.0
const EWASTE_RADIUS := 2.6

var game
var bins: Array = []
var combo := 0
var combo_t := 0.0
var ewaste_carried := 0
var ewaste_delivered := 0
var ewaste_point: Node3D = null
var ewaste_left := 0.0

var _ewaste_next := EWASTE_FIRST
var _ep_ring: ShaderMaterial
var _ep_t := 0.0

static var _kiosk: Mesh


func setup(g) -> void:
	game = g
	var offsets := [Vector3(-9, 0, -7), Vector3(9, 0, -7), Vector3(-9, 0, 7), Vector3(9, 0, 7)]
	for i in GameData.BIN_TYPES.size():
		var b = RecycleBin.new()
		game.add_child(b)
		b.setup(GameData.BIN_TYPES[i])
		b.position = offsets[i]
		bins.append(b)


func combo_mult() -> float:
	return 1.0 + 0.2 * (clampi(combo, 1, COMBO_MAX) - 1)


func tick(delta: float) -> void:
	if combo_t > 0.0:
		combo_t -= delta
		if combo_t <= 0.0:
			combo = 0
	for b in bins:
		b.tick(delta)
		b.set_active(game.carried[b.mat_type] > 0)
		if b.busy:
			continue
		var t: String = b.mat_type
		if game.carried[t] > 0 and game.flat_dist(b.position, game.player.position) < RecycleBin.DEPOSIT_RADIUS:
			_deposit(b)
	_tick_ewaste(delta)


func _deposit(b) -> void:
	var t: String = b.mat_type
	var n: int = game.carried[t]
	game.carried[t] = 0
	game.recycled[t] += n
	var col: Color = GameData.MATERIALS[t].color
	if n >= COMBO_MIN:
		combo = combo + 1 if combo_t > 0.0 else 1
		combo_t = COMBO_WINDOW
	var mult := combo_mult() if combo > 0 else 1.0
	var p = game.player
	p.add_xp(n * 1.2 * mult)
	p.add_ult(n * 1.6 * mult)
	var buff: String = GameData.MATERIALS[t].buff
	var dur := clampf(4.0 + n * 0.6, 5.0, 25.0) * (0.8 + 0.2 * mult)
	if buff == "heal":
		p.heal(minf(60.0, n * 2.0 * mult))
	else:
		p.apply_buff(buff, dur)
	var msg := Loc.t("deposit").format({"n": n, "mat": Loc.pick(GameData.MATERIALS[t].name)})
	msg += "  →  " + Loc.t("buff_" + buff) + ("" if buff == "heal" else " (%ds)" % int(dur))
	if combo >= 2 and n >= COMBO_MIN:
		msg = Loc.t("combo") + " x%d!  " % combo + msg
		game.hud.combo_pop(combo)
	game.hud.toast(msg + "\n" + Loc.t("did_you_know") + " " + GameData.material_fact(t), col)
	Sfx.play("deposit")
	b.burst()
	game.fx.shockwave(b.position, col, 4.0 + combo * 0.6, 0.4, 2.5)
	game.quests.on_deposit(t, n)
	b.relocate(new_spot(b, 18.0, 32.0))


## A spot near the player, kept away from the other bins.
func new_spot(moving, near: float, far: float) -> Vector3:
	var best := Vector3.ZERO
	var best_score := -1.0
	for i in 16:
		var a := randf() * TAU
		var d := randf_range(near, far)
		var p: Vector3 = game.clamp_arena(game.player.position + Vector3(cos(a) * d, 0, sin(a) * d), 4.0)
		var score := 1000.0
		for o in bins:
			if o != moving:
				score = minf(score, game.flat_dist(o.position, p))
		if score > best_score:
			best_score = score
			best = p
		if score > 12.0:
			break
	return best


# --- e-waste point --------------------------------------------------------------

func collect_ewaste() -> void:
	ewaste_carried = mini(EWASTE_CAP, ewaste_carried + 1)


func _tick_ewaste(delta: float) -> void:
	if ewaste_point == null:
		if game.elapsed >= _ewaste_next and not game.boss_spawned:
			_ewaste_next = game.elapsed + EWASTE_EVERY
			_open_point()
		return
	_ep_t += delta
	ewaste_left -= delta
	_ep_ring.set_shader_parameter("intensity", 1.2 + sin(_ep_t * 5.0) * 0.5 if ewaste_carried > 0 else 0.7)
	ewaste_point.get_child(0).rotation.y = sin(_ep_t * 1.5) * 0.15
	if ewaste_carried > 0 and game.flat_dist(ewaste_point.position, game.player.position) < EWASTE_RADIUS:
		_deliver()
	if ewaste_left <= 0.0:
		_close_point()


func _open_point() -> void:
	ewaste_point = Node3D.new()
	game.add_child(ewaste_point)
	ewaste_point.position = new_spot(null, 16.0, 26.0)
	var vis := Node3D.new()
	ewaste_point.add_child(vis)
	MF.inst(_kiosk_mesh(), MF.vc_mat(), vis)
	MF.inst(MF.prism_mesh(Vector3(0.3, 0.5, 0.06)), MF.glow_mat(Color(1.0, 0.75, 0.2), 3.0), vis, Vector3(0, 1.55, 0.42), false).rotation.z = PI
	var c := GameData.MATERIALS.ewaste.color
	var ring := Fx.ground(ewaste_point, {"color": Color(1.0, 0.7, 0.2), "inner": 0.86, "softness": 0.1, "dashes": 12.0, "spin": -2.0, "intensity": 1.2}, EWASTE_RADIUS, 0.06)
	_ep_ring = ring.material_override
	Fx.ground(ewaste_point, {"color": Color(c, 0.35), "falloff": 1.0, "intensity": 0.8}, EWASTE_RADIUS * 0.9, 0.05)
	MF.inst(MF.cyl_mesh(0.1, 0.5, 30.0), MF.glow_mat(Color(1.0, 0.7, 0.2, 0.2), 1.6), ewaste_point, Vector3(0, 15.0, 0), false)
	var l := Label3D.new()
	l.text = Loc.upper(Loc.t("ewaste_point"))
	l.font_size = 52
	l.outline_size = 12
	l.pixel_size = 0.01
	l.modulate = Color(1.0, 0.8, 0.4)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = Vector3(0, 3.2, 0)
	ewaste_point.add_child(l)
	ewaste_left = EWASTE_LIFE
	ewaste_point.scale = Vector3(0.05, 0.05, 0.05)
	ewaste_point.create_tween().tween_property(ewaste_point, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	game.hud.banner(Loc.t("ewaste_open"), Color(1.0, 0.8, 0.4))
	Sfx.play("warning")


func _close_point() -> void:
	var p := ewaste_point
	ewaste_point = null
	var tw := p.create_tween()
	tw.tween_property(p, "scale", Vector3(0.05, 0.05, 0.05), 0.3)
	tw.tween_callback(p.queue_free)


func _deliver() -> void:
	var n := ewaste_carried
	ewaste_carried = 0
	ewaste_delivered += n
	var p = game.player
	p.add_xp(n * 4.0)
	p.add_ult(n * 4.0)
	p.heal(n * 1.5)
	if n >= 4:
		game.give_chest("ewaste")
	game.fx.big_burst(ewaste_point.position, Color(1.0, 0.75, 0.25), 30)
	game.hud.toast(Loc.t("ewaste_done").format({"n": n}) + "\n" + Loc.t("did_you_know") + " " + GameData.material_fact("ewaste"), Color(1.0, 0.75, 0.25))
	Sfx.play("deposit")
	game.quests.on_ewaste(n)
	_close_point()


static func _kiosk_mesh() -> Mesh:
	if _kiosk == null:
		var mb := ModelBuilder.new()
		var body := Color(0.32, 0.34, 0.38)
		var orange := Color(1.0, 0.6, 0.15)
		mb.box(Vector3(1.4, 1.9, 1.0), body, Vector3(0, 0.95, 0))
		mb.box(Vector3(1.46, 0.16, 1.06), orange, Vector3(0, 1.95, 0))
		mb.box(Vector3(1.46, 0.12, 1.06), orange, Vector3(0, 0.25, 0))
		mb.box(Vector3(1.0, 0.7, 0.03), Color(0.95, 0.95, 0.95), Vector3(0, 1.2, 0.51))
		# battery icon on the front plate
		mb.box(Vector3(0.24, 0.42, 0.03), Color(0.15, 0.15, 0.17), Vector3(-0.22, 1.18, 0.53))
		mb.box(Vector3(0.1, 0.06, 0.03), Color(0.15, 0.15, 0.17), Vector3(-0.22, 1.42, 0.53))
		mb.box(Vector3(0.2, 0.12, 0.035), orange, Vector3(-0.22, 1.08, 0.535))
		# slot + phone/plug icon
		mb.box(Vector3(0.24, 0.4, 0.03), Color(0.2, 0.45, 0.85), Vector3(0.22, 1.18, 0.53))
		mb.box(Vector3(0.7, 0.07, 0.05), Color(0.08, 0.08, 0.08), Vector3(0, 0.7, 0.52))
		mb.box(Vector3(1.5, 0.06, 1.1), Color(0.2, 0.2, 0.22), Vector3(0, 2.06, 0))
		_kiosk = mb.commit()
	return _kiosk
