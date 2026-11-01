extends Node3D
## Run controller: world, spawning, enemy manager, pickups, bins, flow.

const MF = preload("res://scripts/mesh_factory.gd")
const WorldBuilder = preload("res://scripts/world_builder.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Gem = preload("res://scripts/gem.gd")
const RecycleBin = preload("res://scripts/recycle_bin.gd")
const HUD = preload("res://scripts/ui/hud.gd")
const LevelUpUI = preload("res://scripts/ui/level_up.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
const EndScreen = preload("res://scripts/ui/end_screen.gd")
const Fx = preload("res://scripts/fx.gd")
const Hazards = preload("res://scripts/hazards.gd")
const Sorting = preload("res://scripts/sorting.gd")
const Quests = preload("res://scripts/quests.gd")
const Events = preload("res://scripts/events.gd")
const BatchRenderer = preload("res://scripts/batch_renderer.gd")
const Models = preload("res://scripts/enemy_models.gd")
const Trailer = preload("res://scripts/trailer.gd")

const CELL := 2.0
const MAX_GEMS := 400
const CAM_OFFSET := Vector3(0, 15.0, 10.5)

var player
var camera: Camera3D
var enemy_root: Node3D
var gem_root: Node3D
var weapon_root: Node3D
var fx_root: Node3D
var fx
var hazards
var sorting
var quests
var events

var enemies: Array = []
var bosses: Array = []
var gems: Array = []
var bins: Array = []
var grid := {}            # int cell key -> Array of indices into the arrays below
var _gpos := PackedVector3Array()   # enemy positions at the start of the frame
var _grad := PackedFloat32Array()   # enemy radii
var _gent: Array = []               # enemy objects
var batches

var elapsed := 0.0
var kills := 0
var finished := false
var boss_spawned := false
var carried := {}
var recycled := {}
var collected := {}
var hud
var level_ui
var pause_ui
var end_ui

var _spawn_acc := 0.0
var _next_elite := 90.0
const ELITE_EVERY := 75.0
var _shake := 0.0
var _dmg_labels: Array[Label3D] = []
var _dmg_tweens: Array = []
var _dmg_next := 0
var _first_pickup_hint := true
var _first_ewaste_hint := true
# autotest balance counters
var stat_chests := {}
var stat_elites := 0
var stat_pool_empty := -1.0
var _stat_k := 0
var _prof_us := {}
var stat_taken := 0.0
var _stat_one := 0

# Headless soak test: `godot --headless --fixed-fps 60 res://scenes/game.tscn -- --autotest`
var autotest := false
var showcase := false
var trailer = null         # `--trailer` gameplay reel director
var _perf_acc := 0.0
var _perf_frames := 0
var _perf_worst := 0.0
var _perf_t := 0.0
var _perf_real := 0


func _ready() -> void:
	randomize()
	Music.set_intense(false)
	autotest = OS.get_cmdline_user_args().has("--autotest")
	showcase = OS.get_cmdline_user_args().has("--showcase")
	for t in GameData.BIN_TYPES:
		carried[t] = 0
		recycled[t] = 0
		collected[t] = 0
	collected["ewaste"] = 0
	var env := WorldBuilder.setup_environment(self)
	WorldBuilder.build_arena(self)
	enemy_root = _make_root("Enemies")
	gem_root = _make_root("Gems")
	weapon_root = _make_root("Weapons")
	fx_root = _make_root("FX")
	fx = Fx.new()
	add_child(fx)
	hazards = Hazards.new()
	hazards.game = self
	add_child(hazards)
	batches = BatchRenderer.new()
	add_child(batches)
	player = Player.new()
	player.game = self
	player.scale = Vector3.ONE * 1.25
	add_child(player)
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.far = 300.0
	add_child(camera)
	camera.position = player.position + CAM_OFFSET
	camera.look_at(player.position + Vector3(0, 0.5, 0))
	sorting = Sorting.new()
	add_child(sorting)
	sorting.setup(self)
	bins = sorting.bins
	quests = Quests.new()
	quests.game = self
	add_child(quests)
	events = Events.new()
	add_child(events)
	events.setup(self, env)
	_setup_damage_labels()
	hud = HUD.new()
	hud.game = self
	add_child(hud)
	level_ui = LevelUpUI.new()
	level_ui.game = self
	add_child(level_ui)
	pause_ui = PauseMenu.new()
	pause_ui.game = self
	add_child(pause_ui)
	end_ui = EndScreen.new()
	add_child(end_ui)
	player.add_or_upgrade_weapon("glass")
	if OS.get_cmdline_user_args().has("--trailer"):
		trailer = Trailer.new()
		trailer.game = self
		add_child(trailer)


func _make_root(n: String) -> Node3D:
	var r := Node3D.new()
	r.name = n
	add_child(r)
	return r


# --- main loop ---------------------------------------------------------------

func _process(delta: float) -> void:
	if finished:
		return
	var t0 := Time.get_ticks_usec()
	delta = minf(delta, 0.05)
	elapsed += delta
	events.tick(delta)
	_spawn_logic(delta)
	player.tick(delta)
	_prof("other", t0)
	var t := Time.get_ticks_usec()
	_update_enemies(delta)
	t = _prof("enemies", t)
	for w in player.weapons:
		w.tick(delta)
	t = _prof("weapons", t)
	hazards.tick(delta)
	_update_gems(delta)
	t = _prof("gems", t)
	sorting.tick(delta)
	quests.tick(delta)
	_cleanup_dead()
	_update_camera(delta)
	t = _prof("other", t)
	_draw_batches()
	t = _prof("draw", t)
	hud.refresh(delta)
	_prof("hud", t)
	if autotest:
		_autotest_report(delta, (Time.get_ticks_usec() - t0) / 1000.0)
		_autotest_shots()


## With `--shots=<dir>` saves screenshots during an autotest run, then quits.
func _autotest_shots() -> void:
	var dir := ""
	var showcase := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			dir = a.substr(8)
		showcase = showcase or a == "--showcase"
	if dir == "":
		return
	var prev := elapsed - get_process_delta_time()
	if showcase:
		# model gallery: every enemy frozen facing the camera, then all weapons
		if prev <= 0.0:
			_spawn_acc = -1000.0
			var kinds := ["bag", "bottle", "rot", "box", "battery", "rot_small", "spray", "foam"]
			for i in kinds.size():
				_gallery(kinds[i], player.position + Vector3(-7.0 + i * 2.0, 0, 3.2))
			_gallery("miniboss", player.position + Vector3(-6.5, 0, -3.5))
			_gallery("boss", player.position + Vector3(6.5, 0, -4.0))
		if elapsed >= 1.7 and prev < 1.7:
			for id in GameData.WEAPONS:
				for i in 3:
					player.add_or_upgrade_weapon(id)
		for mark in [1.6, 3.2]:
			if elapsed >= mark and prev < mark:
				get_viewport().get_texture().get_image().save_png(dir.path_join("showcase_%d.png" % int(mark * 10)))
		if elapsed > 3.3:
			get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--tour"):
		_tour_shots(dir, prev)
		return
	if OS.get_cmdline_user_args().has("--late"):
		_late_shots(dir, prev)
		return
	if elapsed >= 94.0 and prev < 94.0:
		# preview the level-up cards without pausing so they get captured
		level_ui._choices = roll_choices()
		level_ui._build()
		level_ui.visible = true
	if elapsed >= 97.0 and prev < 97.0:
		level_ui.visible = false
	if elapsed >= 120.0 and prev < 120.0:
		pause_ui._build()
		pause_ui.visible = true
	if elapsed >= 122.0 and prev < 122.0:
		pause_ui.visible = false
	if elapsed >= 157.0 and prev < 157.0:
		hud.visible = false
		end_ui.show_result(true, run_stats(), Meta.run_points(run_stats(), true))
	for mark in [20.0, 95.0, 121.0, 140.0, 160.0]:
		if elapsed >= mark and prev < mark:
			get_viewport().get_texture().get_image().save_png(dir.path_join("shot_%d.png" % int(mark)))
	if elapsed > 161.0:
		get_tree().quit()


## `--tour`: no enemies; hops the player around the map and photographs
## each spot (tour_0.png ...), for checking the environment.
const TOUR := [Vector3(0, 0, 0), Vector3(-40, 0, -35), Vector3(40, 0, -35), Vector3(-45, 0, 25), Vector3(45, 0, 25), Vector3(0, 0, 50), Vector3(-70, 0, -10), Vector3(0, 0, -68)]


func _tour_shots(dir: String, prev: float) -> void:
	_spawn_acc = -100000.0
	_next_elite = 100000.0
	for i in TOUR.size():
		var t := 0.4 + i * 0.6
		if elapsed >= t and prev < t:
			player.position = TOUR[i]
			camera.position = player.position + CAM_OFFSET
		if elapsed >= t + 0.45 and prev < t + 0.45:
			get_viewport().get_texture().get_image().save_png(dir.path_join("tour_%d.png" % i))
	if elapsed > 0.4 + TOUR.size() * 0.6:
		get_tree().quit()


## `--late`: jumps to the second half to capture evolutions, map events,
## an elite, the ultimate and boss phase 2.
func _late_shots(dir: String, prev: float) -> void:
	var shot := func(n: String): get_viewport().get_texture().get_image().save_png(dir.path_join(n))
	if prev <= 0.0:
		elapsed = 380.0
		for id in ["glass", "solar", "turbine", "boomerang", "compost", "tote"]:
			for i in GameData.WEAPON_MAX:
				player.add_or_upgrade_weapon(id)
		for id in ["efficiency", "awareness", "power"]:
			player.add_or_upgrade_passive(id)
		spawn_enemy("box", player.position + Vector3(4, 0, 2), -1.0, true)
		return
	if elapsed >= 383.0 and prev < 383.0:
		level_ui._choices = [{"kind": "evolve", "id": "solar", "level": 6}, {"kind": "weapon", "id": "boomerang", "level": 1}, {"kind": "passive", "id": "repair", "level": 1}]
		level_ui._build()
		level_ui.visible = true
	if elapsed >= 383.7 and prev < 383.7:
		shot.call("late_evolve.png")
		level_ui.visible = false
	if elapsed >= 390.0 and prev < 390.0:
		shot.call("late_flood.png")
		player.ult = Player.ULT_MAX
	if elapsed >= 390.3 and prev < 390.3:
		shot.call("late_ult.png")
		elapsed = 598.0
	if elapsed >= 603.0 and prev < 603.0:
		for b in bosses:
			if b.kind == "boss":
				b.hp = b.max_hp * 0.6
	if elapsed >= 607.0 and prev < 607.0:
		shot.call("late_boss.png")
		get_tree().quit()


func _gallery(kind: String, pos: Vector3) -> void:
	var e = spawn_enemy(kind, pos, 500.0)
	e.speed = 0.0
	e.knock_resist = 0.0
	e._charge_t = 999.0
	e._special_t = 999.0


## Autotest profiler: accumulates microseconds per section, returns "now".
func _prof(key: String, since: int) -> int:
	var now := Time.get_ticks_usec()
	if autotest:
		_prof_us[key] = _prof_us.get(key, 0) + now - since
	return now


func _autotest_report(delta: float, ms: float) -> void:
	player.hp = player.max_hp
	_perf_acc += ms
	_perf_frames += 1
	_perf_worst = maxf(_perf_worst, ms)
	_perf_t += delta
	if _perf_t >= 30.0:
		var w := []
		for x in player.weapons:
			w.append("%s%d" % [x.id, x.level])
		# real frames per wall-clock second (meaningful in windowed runs)
		var now := Time.get_ticks_msec()
		var fps := _perf_frames * 1000.0 / maxf(1.0, now - _perf_real) if _perf_real > 0 else 0.0
		_perf_real = now
		print("[autotest] t=%s lv=%d enemies=%d gems=%d kills=%d logic_ms avg=%.2f worst=%.2f fps=%.0f weapons=%s" % [
			int(elapsed), player.level, enemies.size(), gems.size(), kills, _perf_acc / _perf_frames, _perf_worst, fps, w])
		var parts := []
		for k in _prof_us:
			parts.append("%s=%.2f" % [k, _prof_us[k] / 1000.0 / maxi(1, _perf_frames)])
		print("[perf] t=%d ms/frame %s | draw_calls=%d objects=%d prims=%dk" % [int(elapsed), " ".join(parts),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000])
		_prof_us.clear()
		print("[balance] t=%d passives=%s chests=%s elites_killed=%d pool_empty_at=%.0f oneshot=%d%% dmg_taken=%d" % [int(elapsed), player.passives, stat_chests, stat_elites, stat_pool_empty, 100 * _stat_one / maxi(1, _stat_k), int(stat_taken)])
		stat_taken = 0.0
		_stat_k = 0
		_stat_one = 0
		_perf_t = 0.0
		_perf_acc = 0.0
		_perf_frames = 0
		_perf_worst = 0.0


func _update_camera(delta: float) -> void:
	var target: Vector3 = player.position + CAM_OFFSET
	camera.position = camera.position.lerp(target, minf(1.0, 8.0 * delta))
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 2.0


func add_shake(amount: float) -> void:
	_shake = minf(0.5, maxf(_shake, amount))


# --- spawning ----------------------------------------------------------------

func _spawn_logic(delta: float) -> void:
	var m := elapsed / 60.0
	var rate := 1.2 + m * 1.6 + m * m * 0.06
	if boss_spawned:
		rate *= 0.5
	# GDScript runs slower in the browser, so the web build keeps a lower cap
	var cap := 220.0 if OS.has_feature("web") else 320.0
	var max_alive := int(minf(60.0 + m * 32.0, cap))
	_spawn_acc += rate * delta
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		if enemies.size() < max_alive:
			var kind := _pick_kind(m)
			if kind == "foam":
				# styrofoam arrives in packs
				var at := spawn_pos()
				for i in 5:
					spawn_enemy("foam", at + _rand_ring(1.5))
			else:
				spawn_enemy(kind, spawn_pos())
	if elapsed >= _next_elite and not boss_spawned:
		_next_elite += ELITE_EVERY
		var ek := _pick_kind(m)
		if ek == "foam" or ek == "rot_small":
			ek = "box"
		spawn_enemy(ek, spawn_pos(), -1.0, true)
		hud.banner(Loc.t("elite_spawn"), Color(1.0, 0.8, 0.3))


func _pick_kind(m: float) -> String:
	var w := {"bag": maxf(0.25, 1.0 - m * 0.08)}
	if m >= 0.75:
		w["bottle"] = 0.55
	if m >= 2.0:
		w["rot"] = 0.4
	if m >= 3.0:
		w["box"] = 0.25 + (m - 3.0) * 0.05
	if m >= 3.0:
		w["spray"] = 0.12 + (m - 3.0) * 0.02
	if m >= 4.0:
		w["battery"] = 0.1 + (m - 4.0) * 0.02
	if m >= 4.5:
		w["foam"] = 0.05
	var total := 0.0
	for k in w:
		total += w[k]
	var r := randf() * total
	for k in w:
		r -= w[k]
		if r <= 0.0:
			return k
	return "bag"


## Enemy health multiplier: time curve that steepens after minute 5, times
## an adaptive factor that follows how strong the player's build is.
func hp_scale_at(m: float) -> float:
	var late := maxf(0.0, m - 5.0)
	return (1.0 + m * 0.28 + m * m * 0.012 + late * late * 0.12) * adapt_mult()


func dmg_scale_at(m: float) -> float:
	var late := maxf(0.0, m - 5.0)
	return 1.0 + m * 0.08 + late * late * 0.03


## Build power vs. what is expected at this point of the run (~4.5 cards/min).
func adapt_mult() -> float:
	var expected := 2.0 + 4.5 * elapsed / 60.0
	var ratio: float = player.power_score() / expected
	return clampf(1.0 + 0.7 * (ratio - 1.0), 0.85, 1.6)


func spawn_pos() -> Vector3:
	var best := Vector3.ZERO
	for i in 10:
		var a := randf() * TAU
		var d := randf_range(24.0, 28.0)
		var p := clamp_arena(player.position + Vector3(cos(a) * d, 0, sin(a) * d))
		best = p
		if flat_dist(p, player.position) > 18.0:
			return p
	return best


func spawn_ring(kind: String, count: int, r: float) -> void:
	for i in count:
		var a := float(i) / count * TAU
		spawn_enemy(kind, clamp_arena(player.position + Vector3(cos(a), 0, sin(a)) * r))


func spawn_enemy(kind: String, pos: Vector3, hp_override := -1.0, elite := false):
	var m := elapsed / 60.0
	var e = Enemy.new()
	e.use_batch = true
	var hp_scale := hp_override if hp_override > 0.0 else hp_scale_at(m)
	if kind == "miniboss":
		hp_scale = clampf(player.power_score() / 24.0, 0.75, 1.4)
	elif kind == "boss":
		# sized to the build so the fight lasts about a minute either way
		hp_scale = clampf(player.power_score() / 62.0, 0.7, 1.5)
	e.setup(kind, hp_scale, dmg_scale_at(m), elite)
	if autotest and e.is_boss:
		print("[autotest] %s hp=%d power=%.0f" % [kind, e.max_hp, player.power_score()])
	enemy_root.add_child(e)
	e.position = clamp_arena(pos)
	enemies.append(e)
	# rise out of the ground; bosses get a slower, heavier entrance
	var grow := 1.0 if e.is_boss else 0.3
	e.scale = Vector3(0.1, 0.1, 0.1)
	e.create_tween().tween_property(e, "scale", Vector3.ONE, grow).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if e.is_boss:
		fx.big_burst(e.position, Color(0.75, 0.3, 0.9), 30)
	if e.is_boss:
		bosses.append(e)
	return e


# --- enemy manager -----------------------------------------------------------

## Packs a grid cell into one int (dictionary lookups on ints are much
## cheaper than on Vector2i).
static func _key(ix: int, iz: int) -> int:
	return (ix + 4096) * 8192 + (iz + 4096)


func _update_enemies(delta: float) -> void:
	grid.clear()
	var n := enemies.size()
	_gpos.resize(n)
	_grad.resize(n)
	_gent.resize(n)
	var m := 0
	for e in enemies:
		if e.dead or e.is_boss:
			continue
		var p: Vector3 = e.position
		_gpos[m] = p
		_grad[m] = e.radius
		_gent[m] = e
		var k := _key(floori(p.x / CELL), floori(p.z / CELL))
		var arr = grid.get(k)
		if arr == null:
			grid[k] = [m]
		else:
			arr.append(m)
		m += 1
	var ppos: Vector3 = player.position
	var smog: float = events.enemy_speed_mult()
	# separation runs on half the crowd each frame (alternating), twice as strong
	var parity := Engine.get_process_frames() % 2
	var idx := 0
	for e in enemies:
		if e.dead:
			continue
		idx += 1
		e.think(delta, self)
		var ep: Vector3 = e.position
		var to_p: Vector3 = ppos - ep
		to_p.y = 0.0
		var dist := to_p.length()
		var dir := to_p / maxf(dist, 0.001)
		var vel: Vector3
		if e.move_override != null:
			vel = e.move_override
		else:
			vel = dir * e.speed * e.speed_mult * smog
		var sep := Vector3.ZERO
		if not e.is_boss and idx % 2 == parity:
			var er: float = e.radius
			var cx := floori(ep.x / CELL)
			var cz := floori(ep.z / CELL)
			for ix in range(cx - 1, cx + 2):
				for iz in range(cz - 1, cz + 2):
					var arr = grid.get(_key(ix, iz))
					if arr == null:
						continue
					for j in arr:
						var op := _gpos[j]
						var dx := ep.x - op.x
						var dz := ep.z - op.z
						var l2 := dx * dx + dz * dz
						var rr := er + _grad[j]
						if l2 < rr * rr and l2 > 0.0001:
							var l := sqrt(l2)
							var push := (rr - l) / l
							sep.x += dx * push
							sep.z += dz * push
			for b in bosses:
				var d: Vector3 = ep - b.position
				d.y = 0.0
				var rr: float = er + b.radius
				var l := d.length()
				if l < rr and l > 0.001:
					sep += d / l * (rr - l) * 2.0
		ep += (vel + e.knock) * delta + sep * 0.6
		e.knock = e.knock.lerp(Vector3.ZERO, minf(1.0, 8.0 * delta))
		e.position = clamp_arena(ep)
		if dist > 0.01 and e.speed > 0.0:
			e.rotation.y = lerp_angle(e.rotation.y, atan2(dir.x, dir.z), minf(1.0, 10.0 * delta))
		# contact damage
		if dist < e.radius + Player.RADIUS:
			if e.kind == "battery":
				_explode(e)
			else:
				player.hurt(e.damage * delta)
		elif dist > 45.0 and not e.is_boss:
			e.position = spawn_pos()


## Regular enemies and materials are drawn through MultiMeshes; a hit
## enemy moves to the "flash" batch of its kind for the flash duration.
func _draw_batches() -> void:
	batches.begin()
	var vc: Material = MF.vc_mat()
	var vca: Material = MF.vc_mat(true)
	var flash: Material = MF.flash_mat()
	var glow: Material = MF.vc_mat(false, 4.0)
	# only what the camera can see (it looks down at the player from +Z)
	var pp: Vector3 = player.position
	var x0 := pp.x - 25.0
	var x1 := pp.x + 25.0
	var z0 := pp.z - 21.0
	var z1 := pp.z + 15.0
	for e in enemy_root.get_children():
		if not e.batched:
			continue
		var ep: Vector3 = e.position
		if ep.x < x0 or ep.x > x1 or ep.z < z0 or ep.z > z1:
			continue
		var model: Dictionary = e.draw_model
		if model.is_empty():
			model = Models.get_model(e.kind)
			e.draw_model = model
			e.draw_keys = [e.kind + "|o", e.kind + "|of", e.kind + "|a", e.kind + "|af", e.kind + "|g"]
		var keys: Array = e.draw_keys
		var xf: Transform3D = e.transform * e._body.transform
		var fl: bool = e._flashing
		if model.opaque:
			batches.add(keys[1] if fl else keys[0], model.opaque, flash if fl else vc, xf)
		if model.alpha:
			batches.add(keys[3] if fl else keys[2], model.alpha, flash if fl else vca, xf)
		if model.glow and e.glow_on:
			batches.add(keys[4], model.glow, glow, xf)
		batches.blob(ep, e.blob_r * e.scale.x)
	for g in gems:
		var gp: Vector3 = g.position
		if gp.x < x0 or gp.x > x1 or gp.z < z0 or gp.z > z1:
			continue
		if g.use_batch and g.mat_type != "chest":
			batches.add(g.draw_key, g.mesh_for(), g.draw_mat, g.mesh_transform())
	batches.end()


func _explode(e) -> void:
	e.dead = true
	player.hurt(e.damage)
	add_shake(0.35)
	Sfx.play("explode")
	fx.big_burst(e.position, Color(1.0, 0.55, 0.15), 24)


func enemies_near(pos: Vector3, r: float) -> Array:
	var out := []
	var reach := r + 0.7  # max regular enemy radius
	var x0 := floori((pos.x - reach) / CELL)
	var x1 := floori((pos.x + reach) / CELL)
	var z0 := floori((pos.z - reach) / CELL)
	var z1 := floori((pos.z + reach) / CELL)
	for ix in range(x0, x1 + 1):
		for iz in range(z0, z1 + 1):
			var arr = grid.get(_key(ix, iz))
			if arr == null:
				continue
			for j in arr:
				var e = _gent[j]
				if e.dead:
					continue
				var rr: float = r + e.radius
				if _flat_dist_sq(e.position, pos) < rr * rr:
					out.append(e)
	for b in bosses:
		if not b.dead:
			var rr: float = r + b.radius
			if _flat_dist_sq(b.position, pos) < rr * rr:
				out.append(b)
	return out


func nearest_enemy(pos: Vector3, max_dist: float):
	var best = null
	var best_d := max_dist * max_dist
	# search outward in rings of cells for speed
	var cx := floori(pos.x / CELL)
	var cz := floori(pos.z / CELL)
	var max_ring := int(ceil(max_dist / CELL))
	for ring in range(0, max_ring + 1):
		for ix in range(cx - ring, cx + ring + 1):
			for iz in range(cz - ring, cz + ring + 1):
				if absi(ix - cx) != ring and absi(iz - cz) != ring:
					continue
				var arr = grid.get(_key(ix, iz))
				if arr == null:
					continue
				for j in arr:
					var e = _gent[j]
					if e.dead:
						continue
					var d := _flat_dist_sq(e.position, pos)
					if d < best_d:
						best_d = d
						best = e
		# cells in ring k+1 are at least k*CELL away, so stop once that exceeds the best hit
		if best != null and ring * CELL >= sqrt(best_d):
			break
	for b in bosses:
		if not b.dead:
			var d := _flat_dist_sq(b.position, pos)
			if d < best_d:
				best_d = d
				best = b
	return best


func damage_enemy(e, amount: float, knock_dir := Vector3.ZERO, knock_force := 0.0) -> void:
	if e.dead:
		return
	amount *= player.damage_mult()
	var full_hp: bool = e.hp >= e.max_hp
	e.hp -= amount
	if e.hp <= 0.0 and not e.is_boss:
		_stat_k += 1
		if full_hp:
			_stat_one += 1
	e.hit_flash()
	fx.hit(e.position)
	if knock_force > 0.0:
		e.knock += knock_dir * knock_force * e.knock_resist
	_show_damage(e.position, amount, e.is_boss)
	Sfx.play("hit")
	if e.hp <= 0.0:
		_kill(e)


func _kill(e) -> void:
	e.dead = true
	var pos: Vector3 = e.position
	match e.kind:
		"miniboss":
			if autotest:
				print("[autotest] miniboss killed t=%.1f" % elapsed)
			for i in 22:
				spawn_gem(pos + _rand_ring(2.5), GameData.BIN_TYPES.pick_random(), 5.0)
			spawn_gem(pos, "heal", 40.0)
			hud.banner(Loc.t("boss_down"), Color(0.6, 1, 0.6))
			hud.clear_boss(e)
			add_shake(0.4)
			Sfx.play("explode")
			fx.big_burst(pos, Color(0.6, 1.0, 0.5), 50)
		"boss":
			add_shake(0.6)
			Sfx.play("explode")
			fx.big_burst(pos, Color(1, 0.85, 0.3), 60)
			hud.clear_boss(e)
			_finish.call_deferred(true)
		_:
			kills += 1
			quests.on_kill()
			player.add_ult(0.12)
			fx.death(pos, GameData.MATERIALS[e.material_type].color)
			spawn_gem(pos, e.material_type, float(e.xp))
			if e.elite:
				stat_elites += 1
				spawn_gem(pos + _rand_ring(0.8), "chest", 0.0)
				fx.big_burst(pos, Color(1.0, 0.8, 0.3), 24, false)
			if e.kind == "rot":
				for i in 2:
					spawn_enemy("rot_small", pos + _rand_ring(0.6))
			if randf() < 0.006:
				spawn_gem(pos + _rand_ring(0.5), "heal", 25.0)


func _cleanup_dead() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if e.dead:
			enemies.remove_at(i)
			if e.is_boss:
				bosses.erase(e)
			# quick shrink "pop" before freeing
			var tw = e.create_tween()
			tw.tween_property(e, "scale", Vector3(1.3, 0.1, 1.3), 0.12)
			tw.tween_callback(e.queue_free)


# --- pickups -----------------------------------------------------------------

func spawn_gem(pos: Vector3, mat_type: String, value: float) -> void:
	if gems.size() >= MAX_GEMS:
		var old = gems.pop_front()
		if old.mat_type == "chest":
			give_chest("elite")
		player.add_xp(old.value)
		old.queue_free()
	var g = Gem.new()
	g.use_batch = true
	g.setup(mat_type, value)
	gem_root.add_child(g)
	g.position = Vector3(pos.x, 0, pos.z)
	gems.append(g)


func _update_gems(delta: float) -> void:
	var pr: float = player.pickup_radius()
	var pr2 := pr * pr
	var ppos: Vector3 = player.position
	for i in range(gems.size() - 1, -1, -1):
		var g = gems[i]
		var to: Vector3 = ppos - g.position
		to.y = 0.0
		var d2 := to.length_squared()
		if not g.magnet and d2 < pr2:
			g.magnet = true
		if g.magnet:
			g.pull_speed += 40.0 * delta
			var d := sqrt(d2)
			if d < 0.6:
				_collect(g)
				gems.remove_at(i)
				continue
			g.position += to / d * minf(d, (g.pull_speed + player.speed()) * delta)
		g.animate(delta)


func _collect(g) -> void:
	var t: String = g.mat_type
	if t == "heal":
		player.heal(g.value)
		Sfx.play("select")
	elif t == "chest":
		give_chest("elite")
	else:
		player.add_xp(g.value)
		Sfx.play("pickup")
		if carried.has(t):
			collected[t] += 1
			carried[t] = mini(player.carry_cap(), carried[t] + 1)
			if _first_pickup_hint:
				_first_pickup_hint = false
				hud.toast(Loc.t("bin_hint"), GameData.MATERIALS[t].color)
		elif t == "ewaste":
			collected["ewaste"] += 1
			sorting.collect_ewaste()
			if _first_ewaste_hint:
				_first_ewaste_hint = false
				hud.toast(Loc.t("ewaste_hint") + "\n" + GameData.fact_text(10), GameData.MATERIALS.ewaste.color)
	g.queue_free()


# --- flow --------------------------------------------------------------------

func on_level_up() -> void:
	Sfx.play("levelup")
	fx.level_up(player.position)
	level_ui.queue_level_up()


func roll_choices() -> Array:
	var out := []
	# a ready evolution always takes the first card
	for id in evolutions_ready():
		out.append({"kind": "evolve", "id": id, "level": 6})
		break
	var pool := []
	var full_w: bool = player.weapons.size() >= GameData.MAX_WEAPONS
	var full_p: bool = player.passives.size() >= GameData.MAX_PASSIVES
	for id in GameData.WEAPONS:
		var lv: int = player.weapon_level(id)
		if lv < GameData.WEAPON_MAX and not player.is_evolved(id) and not (lv == 0 and full_w):
			pool.append({"kind": "weapon", "id": id, "level": lv + 1, "w": 1.6 if lv > 0 else 1.0})
	for id in GameData.PASSIVES:
		var lv: int = player.plv(id)
		if lv < GameData.PASSIVE_MAX and not (lv == 0 and full_p):
			# partners of maxed weapons are more likely, to steer toward evolutions
			var partner := false
			for w in player.weapons:
				if w.level >= 5 and not w.evolved and GameData.EVOLUTIONS[w.id].passive == id:
					partner = true
			pool.append({"kind": "passive", "id": id, "level": lv + 1, "w": 2.5 if partner and lv == 0 else 1.0})
	while out.size() < 3 and not pool.is_empty():
		var total := 0.0
		for c in pool:
			total += c.w
		var r := randf() * total
		for i in pool.size():
			r -= pool[i].w
			if r <= 0.0 or i == pool.size() - 1:
				out.append(pool[i])
				pool.remove_at(i)
				break
	# once the real cards run out, fill up with endless small boosts
	var stats: Array = GameData.STAT_CARDS.keys()
	stats.shuffle()
	while out.size() < 3 and not stats.is_empty():
		var sid: String = stats.pop_back()
		out.append({"kind": "stat", "id": sid, "level": player.bn(sid) + 1})
	if out.is_empty():
		out.append({"kind": "heal", "id": "heal", "level": 0})
		if stat_pool_empty < 0.0:
			stat_pool_empty = elapsed
	return out


## Weapons at level 5 whose partner passive is owned.
func evolutions_ready() -> Array:
	var out := []
	if elapsed < GameData.EVOLVE_AFTER:
		return out
	var slots_full: bool = player.passives.size() >= GameData.MAX_PASSIVES
	for w in player.weapons:
		if w.level < GameData.WEAPON_MAX or w.evolved:
			continue
		# a full passive bar can't take the partner, so mastery alone unlocks it
		if player.plv(GameData.EVOLUTIONS[w.id].passive) > 0 or slots_full:
			out.append(w.id)
	return out


func apply_choice(c: Dictionary) -> void:
	match c.kind:
		"stat":
			player.add_stat(c.id)
		"evolve":
			player.evolve_weapon(c.id)
			hud.banner(Loc.t("evolved") + " " + Loc.upper(Loc.pick(GameData.EVOLUTIONS[c.id].name)), Color(1.0, 0.85, 0.35))
			Sfx.play("win")
		"weapon":
			player.add_or_upgrade_weapon(c.id)
		"passive":
			player.add_or_upgrade_passive(c.id)
		"heal":
			player.heal(30.0)


func on_player_died() -> void:
	_finish.call_deferred(false)


func on_player_hurt() -> void:
	quests.on_hurt()


func on_player_revived() -> void:
	hud.banner(Loc.t("revived"), Color(0.5, 0.9, 1.0))
	Sfx.play("levelup")
	fx.big_burst(player.position, Color(0.5, 0.9, 1.0), 40)
	for e in enemies_near(player.position, 9.0):
		if not e.is_boss:
			damage_enemy(e, 9999.0)
	hazards.clear()


## Reward crate: an extra upgrade pick without a level.
func give_chest(src := "") -> void:
	stat_chests[src] = stat_chests.get(src, 0) + 1
	Sfx.play("levelup")
	fx.level_up(player.position)
	level_ui.queue_level_up("chest")


func on_boss_phase(e) -> void:
	if autotest:
		print("[autotest] %s phase %d t=%.1f" % [e.kind, e.phase, elapsed])
	add_shake(0.35)
	Sfx.play("warning")
	fx.big_burst(e.position, Color(1.0, 0.4, 0.3), 30)
	var key := "phase_mini" if e.kind == "miniboss" else "phase_%d" % e.phase
	hud.banner(Loc.t(key), Color(1.0, 0.5, 0.35))


## Space: the Recycling Blast. Wipes the area, pulls materials, heals a bit.
func ultimate_blast() -> void:
	var pos: Vector3 = player.position
	var dmg: float = 160.0 + 14.0 * player.level
	for e in enemies_near(pos, 16.0):
		var amount := dmg
		if e.is_boss:
			amount = dmg * 0.6 + e.max_hp * 0.04
		damage_enemy(e, amount / player.damage_mult(), flat_dir(e.position - pos), 18.0)
	for g in gems:
		if flat_dist(g.position, pos) < 32.0:
			g.magnet = true
	player.heal(15.0)
	hazards.clear()
	var cols := [Color(0.62, 1.0, 0.7), Color(1.0, 0.85, 0.3), Color(0.35, 0.75, 1.0), Color(1.0, 0.82, 0.1)]
	for i in cols.size():
		get_tree().create_timer(i * 0.09, false).timeout.connect(func():
			fx.shockwave(pos, cols[i], 16.0 - i * 2.5, 0.55, 2.8))
	fx.big_burst(pos, Color(0.62, 1.0, 0.7), 60)
	fx.flash_light(pos + Vector3(0, 3, 0), Color(0.7, 1.0, 0.8), 6.0, 0.6)
	add_shake(0.5)
	Sfx.play("ult")
	hud.ult_flash()


func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	Music.set_intense(false)
	if autotest:
		print("[autotest] finished win=%s t=%.1f lv=%d kills=%d quests=%d ewaste=%d points=%d" % [win, elapsed, player.level, kills, quests.completed, sorting.ewaste_delivered, Meta.run_points(run_stats(), win)])
	level_ui.close()
	await get_tree().create_timer(1.2 if win else 0.6).timeout
	get_tree().paused = true
	Sfx.play("win" if win else "lose")
	hud.visible = false
	var stats := run_stats()
	var earned: int = Meta.run_points(stats, win) if autotest or trailer != null else Meta.record_run(stats, win)
	end_ui.show_result(win, stats, earned)


func run_stats() -> Dictionary:
	return {
		"time": elapsed, "kills": kills, "level": player.level,
		"recycled": recycled, "collected": collected,
		"ewaste_delivered": sorting.ewaste_delivered, "quests": quests.completed,
	}


# --- helpers / fx --------------------------------------------------------------

func clamp_arena(p: Vector3, margin := 0.0) -> Vector3:
	return Vector3(
		clampf(p.x, -GameData.ARENA_X + margin, GameData.ARENA_X - margin),
		0.0,
		clampf(p.z, GameData.ARENA_Z_MIN + margin, GameData.ARENA_Z_MAX - margin))


func flat_dir(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z).normalized()


func flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _flat_dist_sq(a: Vector3, b: Vector3) -> float:
	var dx := a.x - b.x
	var dz := a.z - b.z
	return dx * dx + dz * dz


func _rand_ring(r: float) -> Vector3:
	var a := randf() * TAU
	return Vector3(cos(a), 0, sin(a)) * randf_range(r * 0.3, r)


func _setup_damage_labels() -> void:
	for i in 32:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.font_size = 60
		l.outline_size = 14
		l.pixel_size = 0.01
		l.visible = false
		fx_root.add_child(l)
		_dmg_labels.append(l)
		_dmg_tweens.append(null)


func _show_damage(pos: Vector3, amount: float, big: bool) -> void:
	var i := _dmg_next
	_dmg_next = (_dmg_next + 1) % _dmg_labels.size()
	var l := _dmg_labels[i]
	if _dmg_tweens[i]:
		_dmg_tweens[i].kill()
	l.text = str(int(round(amount)))
	l.modulate = Color(1, 0.85, 0.3) if big or amount >= 30.0 else Color(1, 1, 1)
	l.scale = Vector3.ONE * (1.4 if big else 1.0)
	l.outline_modulate = Color(0, 0, 0, 1)
	l.position = pos + Vector3(randf_range(-0.3, 0.3), 1.6, 0)
	l.visible = true
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.2, 0.45).set_ease(Tween.EASE_OUT)
	# the outline has its own color, so fade both
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.15)
	tw.parallel().tween_property(l, "outline_modulate:a", 0.0, 0.3).set_delay(0.15)
	tw.tween_callback(func(): l.visible = false)
	_dmg_tweens[i] = tw

