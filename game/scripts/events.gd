extends Node3D
## Run timeline: scripted waves, bosses and climate map events
## (plastic rain, flood puddles, smog).

const Fx = preload("res://scripts/fx.gd")

const RAIN_TIME := 18.0
const FLOOD_TIME := 30.0
const SMOG_TIME := 24.0

var game
var env: Environment
var active := ""          # current map event id ("" when none)
var active_left := 0.0

var _timeline: Array = []
var _rain_t := 0.0
var _puddles: Array = []
var _smog := 0.0          # 0..1 blend


func setup(g, environment: Environment) -> void:
	game = g
	env = environment
	_timeline = [
		{"t": 150.0, "id": "swarm"},
		{"t": 215.0, "id": "plastic_rain"},
		{"t": 290.0, "id": "warn_mini"},
		{"t": 300.0, "id": "miniboss"},
		{"t": 385.0, "id": "flood"},
		{"t": 450.0, "id": "ring"},
		{"t": 515.0, "id": "smog"},
		{"t": 590.0, "id": "warn_boss"},
		{"t": GameData.RUN_TIME, "id": "boss"},
	]


func player_speed_mult() -> float:
	if _puddles.is_empty():
		return 1.0
	for p in _puddles:
		if game.flat_dist(p.pos, game.player.position) < p.r:
			return 0.55
	return 1.0


func enemy_speed_mult() -> float:
	return 1.0 + 0.25 * _smog


func tick(delta: float) -> void:
	while not _timeline.is_empty() and game.elapsed >= _timeline[0].t:
		_fire(_timeline.pop_front().id)
	if active != "":
		active_left -= delta
		if active_left <= 0.0:
			active = ""
	if active == "plastic_rain":
		_rain_t -= delta
		if _rain_t <= 0.0:
			_rain_t = 0.45
			var a := randf() * TAU
			var pos: Vector3 = game.clamp_arena(game.player.position + Vector3(cos(a), 0, sin(a)) * randf_range(0.0, 10.0))
			game.hazards.slam(pos, 1.5, 1.1, 10.0, Color(1.0, 0.82, 0.1), _rain_hit)
	_tick_puddles(delta)
	var smog_target := 1.0 if active == "smog" else 0.0
	_smog = move_toward(_smog, smog_target, delta * 0.4)
	if env:
		env.fog_enabled = _smog > 0.01
		env.fog_density = 0.026 * _smog
		env.fog_light_color = Color(0.55, 0.52, 0.45)
		env.adjustment_saturation = 1.06 - 0.45 * _smog
	game.hud.set_smog(_smog)


func _fire(id: String) -> void:
	var hud = game.hud
	match id:
		"swarm":
			hud.banner(Loc.t("warn_swarm"), Color(1, 0.95, 0.7))
			game.spawn_ring("bag", 26, 15.0)
		"ring":
			hud.banner(Loc.t("warn_ring"), Color(1, 0.95, 0.7))
			game.spawn_ring("bottle", 16, 15.0)
			game.spawn_ring("box", 14, 17.0)
		"warn_mini":
			hud.banner(Loc.t("warn_mini"), Color(1, 0.6, 0.3))
			Sfx.play("warning")
		"miniboss":
			var mb = game.spawn_enemy("miniboss", game.spawn_pos(), 1.0)
			hud.set_boss(mb)
			if game.autotest:
				print("[autotest] miniboss spawned t=%.1f" % game.elapsed)
		"warn_boss":
			hud.banner(Loc.t("warn_boss"), Color(1, 0.35, 0.3))
			Sfx.play("warning")
		"boss":
			game.boss_spawned = true
			Music.set_intense(true)
			var b = game.spawn_enemy("boss", game.spawn_pos(), 1.0)
			hud.set_boss(b)
			game.add_shake(0.4)
		"plastic_rain", "flood", "smog":
			_start_map_event(id)


func _start_map_event(id: String) -> void:
	active = id
	active_left = {"plastic_rain": RAIN_TIME, "flood": FLOOD_TIME, "smog": SMOG_TIME}[id]
	game.hud.banner(Loc.t("ev_" + id), Color(0.75, 0.9, 1.0))
	game.hud.toast(Loc.t("ev_" + id + "_hint") + "\n" + Loc.t("did_you_know") + " " + GameData.fact_text({"plastic_rain": 26, "flood": 27, "smog": 25}[id]), Color(0.6, 0.8, 1.0))
	Sfx.play("warning")
	if id == "flood":
		for i in 7:
			var a := randf() * TAU
			var pos: Vector3 = game.clamp_arena(game.player.position + Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 11.0), 4.0)
			_add_puddle(pos, randf_range(3.0, 4.5))


func _rain_hit(pos: Vector3) -> void:
	if randf() < 0.4:
		game.spawn_enemy("bag", pos)
	else:
		game.spawn_gem(pos, "plastic", 1.0)


func _add_puddle(pos: Vector3, r: float) -> void:
	var node := Fx.ground(self, {"color": Color(0.25, 0.55, 1.0, 0.75), "swirl": 0.25, "softness": 0.3, "falloff": 0.25, "intensity": 1.3}, r, 0.05)
	node.position = Vector3(pos.x, 0.05, pos.z)
	node.scale = Vector3(0.1, 1, 0.1)
	node.create_tween().tween_property(node, "scale", Vector3(r, 1, r), 1.2).set_ease(Tween.EASE_OUT)
	_puddles.append({"node": node, "pos": node.position, "r": r, "life": FLOOD_TIME})


func _tick_puddles(delta: float) -> void:
	for i in range(_puddles.size() - 1, -1, -1):
		var p: Dictionary = _puddles[i]
		p.life -= delta
		p.node.rotation.y += delta * 0.2
		if p.life <= 0.0:
			var node: Node3D = p.node
			var tw := node.create_tween()
			tw.tween_property(node, "scale", Vector3(0.05, 1, 0.05), 0.8)
			tw.tween_callback(node.queue_free)
			_puddles.remove_at(i)
