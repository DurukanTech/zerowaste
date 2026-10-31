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
var grid := {}

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
var _shake := 0.0
var _dmg_labels: Array[Label3D] = []
var _dmg_tweens: Array = []
var _dmg_next := 0
var _first_pickup_hint := true
var _first_ewaste_hint := true

# Headless soak test: `godot --headless --fixed-fps 60 res://scenes/game.tscn -- --autotest`
var autotest := false
var showcase := false
var _perf_acc := 0.0
var _perf_frames := 0
var _perf_worst := 0.0
var _perf_t := 0.0
var _perf_real := 0


func _ready() -> void:
	randomize()
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
	_update_enemies(delta)
	for w in player.weapons:
		w.tick(delta)
	hazards.tick(delta)
	_update_gems(delta)
	sorting.tick(delta)
	quests.tick(delta)
	_cleanup_dead()
	_update_camera(delta)
	hud.refresh(delta)
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


## `--late`: jumps to the second half to capture evolutions, map events,
## an elite, the ultimate and boss phase 2.
func _late_shots(dir: String, prev: float) -> void:
	var shot := func(n: String): get_viewport().get_texture().get_image().save_png(dir.path_join(n))
	if prev <= 0.0:
		elapsed = 380.0
		for id in ["glass", "solar", "turbine", "boomerang", "compost", "tote"]:
			for i in 5:
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
				spawn_enemy(kind, spawn_pos(), -1.0, m >= 1.5 and randf() < _elite_chance(m))


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


func _elite_chance(m: float) -> float:
	return minf(0.006 + m * 0.0012, 0.018)


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
	var hp_scale := hp_override if hp_override > 0.0 else 1.0 + m * 0.28 + m * m * 0.012
	if kind == "miniboss" or kind == "boss":
		hp_scale = 1.0
	e.setup(kind, hp_scale, 1.0 + m * 0.08, elite)
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

func _cell(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.z / CELL))


func _update_enemies(delta: float) -> void:
	grid.clear()
	for e in enemies:
		if e.dead or e.is_boss:
			continue
		var k := _cell(e.position)
		var arr = grid.get(k)
		if arr == null:
			grid[k] = [e]
		else:
			arr.append(e)
	var ppos: Vector3 = player.position
	var smog: float = events.enemy_speed_mult()
	for e in enemies:
		if e.dead:
			continue
		e.think(delta, self)
		var to_p: Vector3 = ppos - e.position
		to_p.y = 0.0
		var dist := to_p.length()
		var dir := to_p / maxf(dist, 0.001)
		var vel: Vector3
		if e.move_override != null:
			vel = e.move_override
		else:
			vel = dir * e.speed * e.speed_mult * smog
		var sep := Vector3.ZERO
		if not e.is_boss:
			var c := _cell(e.position)
			for ix in range(c.x - 1, c.x + 2):
				for iz in range(c.y - 1, c.y + 2):
					var arr = grid.get(Vector2i(ix, iz))
					if arr == null:
						continue
					for o in arr:
						if o == e:
							continue
						var d: Vector3 = e.position - o.position
						d.y = 0.0
						var rr: float = e.radius + o.radius
						var l2 := d.length_squared()
						if l2 < rr * rr and l2 > 0.0001:
							var l := sqrt(l2)
							sep += d / l * (rr - l)
			for b in bosses:
				var d: Vector3 = e.position - b.position
				d.y = 0.0
				var rr: float = e.radius + b.radius
				var l := d.length()
				if l < rr and l > 0.001:
					sep += d / l * (rr - l) * 2.0
		e.position += (vel + e.knock) * delta + sep * 0.35
		e.knock = e.knock.lerp(Vector3.ZERO, minf(1.0, 8.0 * delta))
		e.position = clamp_arena(e.position)
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


func _explode(e) -> void:
	e.dead = true
	player.hurt(e.damage)
	add_shake(0.35)
	Sfx.play("explode", -2, 0.1)
	fx.big_burst(e.position, Color(1.0, 0.55, 0.15), 24)


func enemies_near(pos: Vector3, r: float) -> Array:
	var out := []
	var reach := r + 0.7  # max regular enemy radius
	var c0 := _cell(pos - Vector3(reach, 0, reach))
	var c1 := _cell(pos + Vector3(reach, 0, reach))
	for ix in range(c0.x, c1.x + 1):
		for iz in range(c0.y, c1.y + 1):
			var arr = grid.get(Vector2i(ix, iz))
			if arr == null:
				continue
			for e in arr:
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
	var c := _cell(pos)
	var max_ring := int(ceil(max_dist / CELL))
	for ring in range(0, max_ring + 1):
		for ix in range(c.x - ring, c.x + ring + 1):
			for iz in range(c.y - ring, c.y + ring + 1):
				if absi(ix - c.x) != ring and absi(iz - c.y) != ring:
					continue
				var arr = grid.get(Vector2i(ix, iz))
				if arr == null:
					continue
				for e in arr:
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
	e.hp -= amount
	e.hit_flash()
	fx.hit(e.position)
	if knock_force > 0.0:
		e.knock += knock_dir * knock_force * e.knock_resist
	_show_damage(e.position, amount, e.is_boss)
	Sfx.play("hit", -14, 0.05)
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
			give_chest()
		player.add_xp(old.value)
		old.queue_free()
	var g = Gem.new()
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
		Sfx.play("select", -4)
	elif t == "chest":
		give_chest()
	else:
		player.add_xp(g.value)
		Sfx.play("pickup", -16, 0.04)
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
	Sfx.play("levelup", -3)
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
		if lv < 5 and not (lv == 0 and full_w):
			pool.append({"kind": "weapon", "id": id, "level": lv + 1, "w": 1.6 if lv > 0 else 1.0})
	for id in GameData.PASSIVES:
		var lv: int = player.plv(id)
		if lv < 5 and not (lv == 0 and full_p):
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
	if out.is_empty():
		out.append({"kind": "heal", "id": "heal", "level": 0})
	return out


## Weapons at level 5 whose partner passive is owned.
func evolutions_ready() -> Array:
	var out := []
	if elapsed < GameData.EVOLVE_AFTER:
		return out
	for w in player.weapons:
		if w.level >= 5 and not w.evolved and player.plv(GameData.EVOLUTIONS[w.id].passive) > 0:
			out.append(w.id)
	return out


func apply_choice(c: Dictionary) -> void:
	match c.kind:
		"evolve":
			player.evolve_weapon(c.id)
			hud.banner(Loc.t("evolved") + " " + Loc.upper(Loc.pick(GameData.EVOLUTIONS[c.id].name)), Color(1.0, 0.85, 0.35))
			Sfx.play("win", -6)
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
func give_chest() -> void:
	Sfx.play("levelup", -4)
	fx.level_up(player.position)
	level_ui.queue_level_up("chest")


func on_boss_phase(e) -> void:
	if autotest:
		print("[autotest] %s phase %d t=%.1f" % [e.kind, e.phase, elapsed])
	add_shake(0.35)
	Sfx.play("warning", -2)
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
	Sfx.play("explode", 0)
	Sfx.play("levelup", -4)
	hud.ult_flash()


func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	if autotest:
		print("[autotest] finished win=%s t=%.1f lv=%d kills=%d quests=%d ewaste=%d points=%d" % [win, elapsed, player.level, kills, quests.completed, sorting.ewaste_delivered, Meta.run_points(run_stats(), win)])
	level_ui.close()
	await get_tree().create_timer(1.2 if win else 0.6).timeout
	get_tree().paused = true
	Sfx.play("win" if win else "lose")
	hud.visible = false
	var stats := run_stats()
	var earned: int = Meta.run_points(stats, win) if autotest else Meta.record_run(stats, win)
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

