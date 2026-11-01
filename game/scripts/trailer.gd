extends CanvasLayer
## `--trailer`: a scripted ~90 s gameplay reel for Movie Maker capture.
## Drives the player along routes through the themed zones, jumps the run
## clock between beats (early waves, plastic rain, miniboss, flood +
## evolution, final boss) and covers each jump with a quick fade.
##
##   godot --path game --write-movie reel.avi --resolution 1920x1080 res://scenes/game.tscn -- --trailer

const UI = preload("res://scripts/ui/ui_kit.gd")
const Player = preload("res://scripts/player.gd")

## Beats: video time, run clock, start position, route, timeline events kept.
const BEATS := [
	{"at": 0.0, "clock": 45.0, "pos": Vector3(0, 0, 2), "route": [Vector3(-9, 0, -4), Vector3(9, 0, -7), Vector3(9, 0, 7), Vector3(22, 0, -26), Vector3(42, 0, -46), Vector3(55, 0, -58)], "keep": []},
	{"at": 15.5, "clock": 212.0, "pos": Vector3(-28, 0, -38), "route": [Vector3(-44, 0, -54), Vector3(-62, 0, -46), Vector3(-52, 0, -38), Vector3(-36, 0, -62), Vector3(-28, 0, -44)], "keep": ["swarm"]},
	{"at": 31.5, "clock": 296.5, "pos": Vector3(-28, 0, 6), "route": [Vector3(-40, 0, 20), Vector3(-58, 0, 16), Vector3(-60, 0, 0), Vector3(-44, 0, -6), Vector3(-30, 0, 2)], "keep": ["warn_mini"]},
	{"at": 50.5, "clock": 384.0, "pos": Vector3(30, 0, 0), "route": [Vector3(46, 0, 10), Vector3(62, 0, 20), Vector3(44, 0, 26), Vector3(30, 0, 14)], "keep": []},
	{"at": 64.5, "clock": 593.0, "pos": Vector3(-30, 0, 47), "route": [Vector3(-10, 0, 49), Vector3(14, 0, 46), Vector3(30, 0, 49), Vector3(10, 0, 44), Vector3(-14, 0, 48)], "keep": ["warn_boss"]},
]
const FADE := 0.4
const MINI_KILL_AT := 48.5
const BOSS_KILL_AT := 87.0
const QUIT_AT := 93.5

var game
var vt := 0.0            # video time (counts while paused, e.g. on cards)
var _beat := -1
var _route: Array = []
var _ri := 0
var _dash_t := 0.0
var _ult := false
var _fade: ColorRect
var _title: Control
var _cards = null        # level-up UI waiting for a held pick
var _cards_at := 0.0
var _held := 0
var _hold_evolve := false
var _stats_done := false
var _boss_seen := {}     # boss -> video time it appeared


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_title = _title_card()
	add_child(_title)


func _title_card() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := UI.dim(0.5)
	root.add_child(dim)
	var c := UI.centered()
	root.add_child(c)
	var v := UI.vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var t := UI.label(Loc.t("title_1") + " " + Loc.t("title_2"), 84, UI.MINT, 12)
	t.add_theme_font_override("font", UI.font(0.6, 3))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := UI.label(Loc.t("tagline"), 28, UI.SUN, 8)
	s.add_theme_font_override("font", UI.font(0.3, 4))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	return root


func _process(delta: float) -> void:
	vt += delta
	for i in BEATS.size():
		if i > _beat and vt >= BEATS[i].at:
			_start_beat(i)
	# fade around each cut, title over the opening and the ending
	var a := 0.0
	for i in range(1, BEATS.size()):
		a = maxf(a, 1.0 - absf(vt - BEATS[i].at) / FADE)
	if vt > QUIT_AT - 2.5:
		a = maxf(a, (vt - (QUIT_AT - 2.5)) / 1.0)
	_fade.color.a = clampf(a, 0.0, 1.0)
	var ta := 1.0 - clampf((vt - 2.6) / 0.8, 0.0, 1.0)
	if vt > QUIT_AT - 2.0:
		ta = clampf((vt - (QUIT_AT - 2.0)) / 0.6, 0.0, 1.0)
	_title.modulate.a = ta
	_title.visible = ta > 0.0
	if _cards != null and vt - _cards_at > 1.4:
		_cards._pick(0)
		_cards = null
	if vt >= QUIT_AT:
		get_tree().quit()
		return
	if game.finished and not _stats_done:
		_stats_done = true
		_sorted_stats()
	if game.finished or get_tree().paused:
		return
	_script(delta)


## Teleport + new run clock, covered by the fade.
func _start_beat(i: int) -> void:
	_beat = i
	var b: Dictionary = BEATS[i]
	game.elapsed = b.clock
	game._next_elite = b.clock + 40.0
	game._spawn_acc = 0.0
	var tl: Array = []
	for ev in game.events._timeline:
		if ev.t >= b.clock or b.keep.has(ev.id):
			tl.append(ev)
	game.events._timeline = tl
	game.events.active = ""
	for e in game.enemies:
		if not e.is_boss:
			e.dead = true
	for g in game.gems:
		g.queue_free()
	game.gems.clear()
	var p = game.player
	p.position = b.pos
	game.camera.position = p.position + game.CAM_OFFSET
	_route = b.route
	_ri = 0
	match i:
		0:
			_loadout({"glass": 3, "boomerang": 2}, {})
			for t in GameData.BIN_TYPES:
				game.carried[t] = 5
			game.spawn_ring("bag", 14, 12.0)
		1:
			_loadout({"glass": 5, "boomerang": 4, "compost": 4, "turbine": 3, "tote": 2}, {"power": 2, "bike": 1})
			game.spawn_ring("bottle", 18, 13.0)
		2:
			_loadout({"glass": 6, "boomerang": 6, "compost": 5, "turbine": 5, "tote": 4, "solar": 3}, {"power": 3, "bike": 2, "efficiency": 2})
		3:
			_loadout({"glass": 7, "boomerang": 7, "compost": 6, "turbine": 6, "tote": 5, "solar": GameData.WEAPON_MAX}, {"power": 4, "bike": 3, "efficiency": 3, "awareness": 1})
			game.spawn_ring("box", 16, 14.0)
		4:
			for id in ["glass", "boomerang", "compost", "turbine", "tote", "solar"]:
				_loadout({id: GameData.WEAPON_MAX}, {})
			_loadout({}, {"power": 5, "bike": 4, "efficiency": 5, "awareness": 3, "canteen": 3, "net": 3})
			for id in ["glass", "boomerang", "turbine"]:
				if not p.is_evolved(id):
					p.evolve_weapon(id)
			game.spawn_ring("bottle", 20, 14.0)
	p.hp = p.max_hp


func _loadout(weapons: Dictionary, passives: Dictionary) -> void:
	var p = game.player
	for id in weapons:
		while p.weapon_level(id) < weapons[id] and not p.is_evolved(id):
			p.add_or_upgrade_weapon(id)
	for id in passives:
		while p.plv(id) < passives[id]:
			p.add_or_upgrade_passive(id)


## Per-beat staging while the game runs.
func _script(delta: float) -> void:
	var p = game.player
	p.hp = maxf(p.hp, p.max_hp * 0.45)
	_ult = false
	_dash_t += delta
	if _once(54.0):
		# a ready evolution (solar is maxed and its partner owned) on the card
		_hold_evolve = true
		game.on_level_up()
	if _once(57.5):
		game.spawn_enemy("box", p.position + Vector3(7, 0, -5), -1.0, true)
		game.hud.banner(Loc.t("elite_spawn"), Color(1.0, 0.8, 0.3))
	for at in [44.0, 61.0, 80.5]:
		if _once(at):
			p.ult = Player.ULT_MAX
			_ult = true
	for b in game.bosses:
		if b.dead:
			continue
		if not _boss_seen.has(b):
			# bring the boss into frame right away
			_boss_seen[b] = vt
			b.position = game.clamp_arena(p.position + Vector3(5, 0, -11))
		var kill_at := MINI_KILL_AT if b.kind == "miniboss" else BOSS_KILL_AT
		var s: float = _boss_seen[b]
		var frac := clampf(1.0 - (vt - s) / maxf(0.1, kill_at - s), 0.02, 1.0)
		b.hp = minf(b.hp, b.max_hp * frac)
		if vt >= kill_at:
			game.damage_enemy(b, b.hp + 10.0)


func _once(t: float) -> bool:
	return vt >= t and vt - get_process_delta_time() < t


## The clock jumps skip most bin trips, so fill in a typical sorting record
## for the results screen.
func _sorted_stats() -> void:
	for t in GameData.BIN_TYPES:
		game.recycled[t] = maxi(game.recycled[t], int(game.collected[t] * 0.82))
	game.sorting.ewaste_delivered = maxi(game.sorting.ewaste_delivered, int(game.collected["ewaste"] * 0.7))


## Walk the route with a little weave, so it reads like a person playing.
func move_input() -> Vector2:
	var p = game.player
	if _route.is_empty():
		return Vector2.ZERO
	var target: Vector3 = _route[_ri]
	var to: Vector3 = target - p.position
	to.y = 0.0
	if to.length() < 2.0:
		_ri = (_ri + 1) % _route.size()
	var dir := Vector2(to.x, to.z).normalized()
	var weave := sin(vt * 1.7) * 0.45
	return (dir + Vector2(-dir.y, dir.x) * weave).normalized()


func want_dash() -> bool:
	if _dash_t > 3.4:
		_dash_t = 0.0
		return true
	return false


func want_ult() -> bool:
	return _ult


## Level-up cards: hold the first ones and the evolution on screen,
## pick the rest instantly so the reel keeps moving.
func on_cards(lu) -> void:
	if _hold_evolve or (_held < 1 and vt > 5.0):
		_hold_evolve = false
		_held += 1
		_cards = lu
		_cards_at = vt
	else:
		lu._pick.call_deferred(randi() % lu._choices.size())
