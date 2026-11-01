extends CanvasLayer
## Web shader warm-up. The browser (GLES3 through ANGLE) compiles each
## material variant the first time it is drawn, which froze the first
## seconds of a run for 3-4 s at a time. Behind a short "Preparing" screen
## this draws one of everything a run shows (every enemy and elite, bosses,
## materials, all weapons and their evolutions, effects, hazards, cards),
## then clears it all and hands over a fresh run.
##
## Runs in web builds, or anywhere with `-- --warmup`.

const UI = preload("res://scripts/ui/ui_kit.gd")

const KINDS := ["bag", "bottle", "rot", "box", "battery", "rot_small", "spray", "foam"]
const STAGE_FRAMES := 8
const TICK := 0.25          # weapon step per frame, so cooldowns fire right away

var game
var _frame := 0
var _gallery: Array = []
var _bar: ProgressBar


static func wanted() -> bool:
	return OS.has_feature("web") or OS.get_cmdline_user_args().has("--warmup")


func _ready() -> void:
	layer = 90
	var bg := ColorRect.new()
	bg.color = UI.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var c := UI.centered()
	add_child(c)
	var v := UI.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var t := UI.label(Loc.t("preparing"), 40, UI.MINT, 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := UI.label(Loc.t("preparing_hint"), 18, UI.MUTED, 0)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(360, 10)
	_bar.show_percentage = false
	_bar.max_value = 5.0
	_bar.add_theme_stylebox_override("background", UI.style(Color(1, 1, 1, 0.1), 5))
	_bar.add_theme_stylebox_override("fill", UI.style(UI.MINT, 5))
	v.add_child(UI.gap(8))
	v.add_child(_bar)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), true)


## Called from game._process instead of the normal update.
func step() -> void:
	var stage := _frame / STAGE_FRAMES
	if _frame % STAGE_FRAMES == 0:
		_bar.value = stage
		match stage:
			0: _show_world()
			1: _weapons(["glass", "boomerang", "compost", "turbine", "solar", "tote"])
			2: _evolve()
			3: _swap_weapons(["tree", "water"])
			4: _evolve()
			5: _finish()
	_frame += 1
	if stage < 5:
		for w in game.player.weapons:
			w.tick(TICK)
		game.hazards.tick(1.0 / 60.0)


func _show_world() -> void:
	var p: Vector3 = game.player.position
	for i in KINDS.size():
		var a := float(i) / KINDS.size() * TAU
		_freeze(game.spawn_enemy(KINDS[i], p + Vector3(cos(a) * 4.5, 0, sin(a) * 3.5)))
		_freeze(game.spawn_enemy(KINDS[i], p + Vector3(cos(a) * 7.5, 0, sin(a) * 5.5), -1.0, true))
	var mb = game.spawn_enemy("miniboss", p + Vector3(-6, 0, -2))
	var bb = game.spawn_enemy("boss", p + Vector3(6, 0, -2))
	_freeze(mb)
	_freeze(bb)
	game.hud.set_boss(bb)
	var gems: Array = GameData.MATERIALS.keys() + ["chest", "heal"]
	for i in gems.size():
		game.spawn_gem(p + Vector3(-4.0 + i * 1.1, 0, 2.5), gems[i], 1.0)
	var fx = game.fx
	fx.hit(p + Vector3(2, 0, 1))
	fx.death(p + Vector3(-2, 0, 1), Color(1, 0.8, 0.2))
	fx.big_burst(p + Vector3(0, 0, -3), Color(0.6, 1, 0.5), 20, false)
	fx.level_up(p)
	fx.streak(p, p + Vector3(3, 0, 0), Color(0.55, 1.0, 0.7))
	game.hazards.shoot(p + Vector3(3, 0.6, 2), Vector3.LEFT * 0.1, 0.0, Color(1, 0.4, 0.3))
	game.hazards.ring(p + Vector3(-3, 0, -3), 6, 0.1, 0.0, Color(0.9, 0.5, 1.0))
	game.hazards.slam(p + Vector3(3, 0, -2), 1.5, 5.0, 0.0, Color(1.0, 0.82, 0.1))
	game.events._add_puddle(p + Vector3(-3, 0, 2), 2.0)
	game._show_damage(p + Vector3(1, 0, 0), 42.0, false)
	game._show_damage(p + Vector3(-1, 0, 0), 420.0, true)
	game.sorting._open_point()
	game.sorting.ewaste_point.position = p + Vector3(0, 0, -5)


func _freeze(e) -> void:
	e.max_hp = 1e12
	e.hp = 1e12
	e.speed = 0.0
	e.knock_resist = 0.0
	e._charge_t = 999.0
	e._special_t = 999.0
	_gallery.append(e)


func _weapons(ids: Array) -> void:
	for id in ids:
		for i in GameData.WEAPON_MAX:
			game.player.add_or_upgrade_weapon(id)
	# the level-up cards and their icons
	game.level_ui._choices = game.roll_choices()
	game.level_ui._build()
	game.level_ui.visible = true


func _evolve() -> void:
	for w in game.player.weapons:
		if not w.evolved:
			w.evolve()
	game.level_ui.visible = false


func _swap_weapons(ids: Array) -> void:
	_drop_weapons()
	_weapons(ids)


func _drop_weapons() -> void:
	for w in game.player.weapons:
		w.queue_free()
	# projectiles live under their weapon, so they go with it
	game.player.weapons.clear()


## Clear everything and hand back a fresh run.
func _finish() -> void:
	_drop_weapons()
	game.level_ui.visible = false
	for e in game.enemies:
		e.queue_free()
	for b in game.bosses:
		game.hud.clear_boss(b)
	game.enemies.clear()
	game.bosses.clear()
	for g in game.gems:
		g.queue_free()
	game.gems.clear()
	game.hazards.clear()
	for pd in game.events._puddles:
		pd.node.queue_free()
	game.events._puddles.clear()
	game.sorting._close_point()
	game.sorting.ewaste_point = null
	if game.hud._banner_tween:
		game.hud._banner_tween.kill()
	game.hud._banner_box.modulate.a = 0.0
	var pl = game.player
	pl.level = 1
	pl.xp = 0.0
	pl.hp = pl.max_hp
	pl.ult = 0.0
	game.kills = 0
	game.elapsed = 0.0
	game._spawn_acc = 0.0
	pl.add_or_upgrade_weapon("glass")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), false)
	game.warmup = null
	print("[warmup] done in %d frames" % _frame)
	var tw := create_tween()
	for n in get_children():
		tw.parallel().tween_property(n, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)
