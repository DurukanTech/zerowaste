extends Node3D
## Run controller: world, spawning, enemy manager, pickups, bins, flow.

const MF = preload("res://scripts/mesh_factory.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Gem = preload("res://scripts/gem.gd")
const RecycleBin = preload("res://scripts/recycle_bin.gd")
const HUD = preload("res://scripts/ui/hud.gd")
const LevelUpUI = preload("res://scripts/ui/level_up.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
const EndScreen = preload("res://scripts/ui/end_screen.gd")

const CELL := 2.0
const MAX_GEMS := 400
const CAM_OFFSET := Vector3(0, 17.0, 11.5)

var player
var camera: Camera3D
var enemy_root: Node3D
var gem_root: Node3D
var weapon_root: Node3D
var fx_root: Node3D

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
var _events: Array = []
var _shake := 0.0
var _dmg_labels: Array[Label3D] = []
var _dmg_tweens: Array = []
var _dmg_next := 0
var _first_pickup_hint := true
var _first_ewaste_hint := true

# Headless soak test: `godot --headless --fixed-fps 60 res://scenes/game.tscn -- --autotest`
var autotest := false
var _perf_acc := 0.0
var _perf_frames := 0
var _perf_worst := 0.0
var _perf_t := 0.0


func _ready() -> void:
	randomize()
	autotest = OS.get_cmdline_user_args().has("--autotest")
	for t in GameData.BIN_TYPES:
		carried[t] = 0
		recycled[t] = 0
		collected[t] = 0
	collected["ewaste"] = 0
	_setup_environment()
	_build_arena()
	enemy_root = _make_root("Enemies")
	gem_root = _make_root("Gems")
	weapon_root = _make_root("Weapons")
	fx_root = _make_root("FX")
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
	_spawn_bins()
	_setup_damage_labels()
	_events = [
		{"t": 150.0, "id": "swarm"},
		{"t": 290.0, "id": "warn_mini"},
		{"t": 300.0, "id": "miniboss"},
		{"t": 450.0, "id": "ring"},
		{"t": 590.0, "id": "warn_boss"},
		{"t": GameData.RUN_TIME, "id": "boss"},
	]
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
	_run_events()
	_spawn_logic(delta)
	player.tick(delta)
	_update_enemies(delta)
	for w in player.weapons:
		w.tick(delta)
	_update_gems(delta)
	_update_bins(delta)
	_cleanup_dead()
	_update_camera(delta)
	hud.refresh(delta)
	if autotest:
		_autotest_report(delta, (Time.get_ticks_usec() - t0) / 1000.0)
		_autotest_shots()


## With `--shots=<dir>` saves screenshots during an autotest run, then quits.
func _autotest_shots() -> void:
	var dir := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			dir = a.substr(8)
	if dir == "":
		return
	var prev := elapsed - get_process_delta_time()
	if elapsed >= 94.0 and prev < 94.0:
		# preview the level-up cards without pausing so they get captured
		level_ui._choices = roll_choices()
		level_ui._build()
		level_ui.visible = true
	if elapsed >= 97.0 and prev < 97.0:
		level_ui.visible = false
	for mark in [20.0, 95.0, 160.0]:
		if elapsed >= mark and prev < mark:
			get_viewport().get_texture().get_image().save_png(dir.path_join("shot_%d.png" % int(mark)))
	if elapsed > 161.0:
		get_tree().quit()


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
		print("[autotest] t=%s lv=%d enemies=%d gems=%d kills=%d sorted=%s logic_ms avg=%.2f worst=%.2f weapons=%s" % [
			int(elapsed), player.level, enemies.size(), gems.size(), kills, recycled, _perf_acc / _perf_frames, _perf_worst, w])
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

func _run_events() -> void:
	while not _events.is_empty() and elapsed >= _events[0].t:
		var ev: Dictionary = _events.pop_front()
		match ev.id:
			"swarm":
				hud.banner(Loc.t("warn_swarm"), Color(1, 0.95, 0.7))
				_spawn_ring("bag", 26, 15.0)
			"ring":
				hud.banner(Loc.t("warn_ring"), Color(1, 0.95, 0.7))
				_spawn_ring("bottle", 16, 15.0)
				_spawn_ring("box", 14, 17.0)
			"warn_mini":
				hud.banner(Loc.t("warn_mini"), Color(1, 0.6, 0.3))
				Sfx.play("warning")
			"miniboss":
				var mb = spawn_enemy("miniboss", _spawn_pos(), 1.0)
				hud.set_boss(mb)
				if autotest:
					print("[autotest] miniboss spawned t=%.1f" % elapsed)
			"warn_boss":
				hud.banner(Loc.t("warn_boss"), Color(1, 0.35, 0.3))
				Sfx.play("warning")
			"boss":
				boss_spawned = true
				var b = spawn_enemy("boss", _spawn_pos(), 1.0)
				hud.set_boss(b)
				add_shake(0.4)


func _spawn_logic(delta: float) -> void:
	var m := elapsed / 60.0
	var rate := 1.2 + m * 1.4
	if boss_spawned:
		rate *= 0.5
	# GDScript runs slower in the browser, so the web build keeps a lower cap
	var cap := 220.0 if OS.has_feature("web") else 320.0
	var max_alive := int(minf(60.0 + m * 32.0, cap))
	_spawn_acc += rate * delta
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		if enemies.size() < max_alive:
			spawn_enemy(_pick_kind(m), _spawn_pos())


func _pick_kind(m: float) -> String:
	var w := {"bag": maxf(0.25, 1.0 - m * 0.08)}
	if m >= 0.75:
		w["bottle"] = 0.55
	if m >= 2.0:
		w["rot"] = 0.4
	if m >= 3.0:
		w["box"] = 0.25 + (m - 3.0) * 0.05
	if m >= 4.0:
		w["battery"] = 0.1 + (m - 4.0) * 0.02
	var total := 0.0
	for k in w:
		total += w[k]
	var r := randf() * total
	for k in w:
		r -= w[k]
		if r <= 0.0:
			return k
	return "bag"


func _spawn_pos() -> Vector3:
	var best := Vector3.ZERO
	for i in 10:
		var a := randf() * TAU
		var d := randf_range(24.0, 28.0)
		var p := _clamp_arena(player.position + Vector3(cos(a) * d, 0, sin(a) * d))
		best = p
		if _flat_dist(p, player.position) > 18.0:
			return p
	return best


func _spawn_ring(kind: String, count: int, r: float) -> void:
	for i in count:
		var a := float(i) / count * TAU
		spawn_enemy(kind, _clamp_arena(player.position + Vector3(cos(a), 0, sin(a)) * r))


func spawn_enemy(kind: String, pos: Vector3, hp_override := -1.0):
	var m := elapsed / 60.0
	var e = Enemy.new()
	var hp_scale := hp_override if hp_override > 0.0 else 1.0 + m * 0.22
	if kind == "miniboss" or kind == "boss":
		hp_scale = 1.0
	e.setup(kind, hp_scale, 1.0 + m * 0.08)
	enemy_root.add_child(e)
	e.position = _clamp_arena(pos)
	enemies.append(e)
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
			vel = dir * e.speed * e.speed_mult
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
		e.position = _clamp_arena(e.position)
		if dist > 0.01:
			e.rotation.y = lerp_angle(e.rotation.y, atan2(dir.x, dir.z), minf(1.0, 10.0 * delta))
		# contact damage
		if dist < e.radius + Player.RADIUS:
			if e.kind == "battery":
				_explode(e)
			else:
				player.hurt(e.damage * delta)
		elif dist > 45.0 and not e.is_boss:
			e.position = _spawn_pos()


func _explode(e) -> void:
	e.dead = true
	player.hurt(e.damage)
	add_shake(0.35)
	Sfx.play("explode", -2, 0.1)
	_spawn_burst(e.position, Color(1.0, 0.5, 0.1), 20)


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
			hud.set_boss(null)
			add_shake(0.4)
			Sfx.play("explode")
		"boss":
			add_shake(0.6)
			Sfx.play("explode")
			_spawn_burst(pos + Vector3(0, 2, 0), Color(1, 0.85, 0.3), 40)
			hud.set_boss(null)
			_finish.call_deferred(true)
		_:
			kills += 1
			spawn_gem(pos, e.material_type, float(e.xp))
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
	else:
		player.add_xp(g.value)
		Sfx.play("pickup", -16, 0.04)
		if carried.has(t):
			collected[t] += 1
			carried[t] = mini(GameData.CARRY_CAP, carried[t] + 1)
			if _first_pickup_hint:
				_first_pickup_hint = false
				hud.toast(Loc.t("bin_hint"), GameData.MATERIALS[t].color)
		elif t == "ewaste":
			collected["ewaste"] += 1
			if _first_ewaste_hint:
				_first_ewaste_hint = false
				hud.toast(Loc.t("ewaste_hint") + "\n" + GameData.fact_text(10), GameData.MATERIALS.ewaste.color)
	g.queue_free()


# --- bins --------------------------------------------------------------------

func _spawn_bins() -> void:
	var offsets := [Vector3(-9, 0, -7), Vector3(9, 0, -7), Vector3(-9, 0, 7), Vector3(9, 0, 7)]
	for i in GameData.BIN_TYPES.size():
		var b = RecycleBin.new()
		add_child(b)
		b.setup(GameData.BIN_TYPES[i])
		b.position = offsets[i]
		bins.append(b)


func _update_bins(delta: float) -> void:
	for b in bins:
		b.tick(delta)
		if b.busy:
			continue
		var t: String = b.mat_type
		if carried[t] > 0 and _flat_dist(b.position, player.position) < RecycleBin.DEPOSIT_RADIUS:
			_deposit(b)


func _deposit(b) -> void:
	var t: String = b.mat_type
	var n: int = carried[t]
	carried[t] = 0
	recycled[t] += n
	player.add_xp(n * 1.5)
	var buff: String = GameData.MATERIALS[t].buff
	var dur := clampf(4.0 + n * 0.6, 5.0, 25.0)
	if buff == "heal":
		player.heal(minf(50.0, n * 2.0))
	else:
		player.apply_buff(buff, dur)
	var msg := Loc.t("deposit").format({"n": n, "mat": Loc.pick(GameData.MATERIALS[t].name)})
	msg += "  →  " + Loc.t("buff_" + buff) + ("" if buff == "heal" else " (%ds)" % int(dur))
	hud.toast(msg + "\n" + Loc.t("did_you_know") + " " + GameData.material_fact(t), GameData.MATERIALS[t].color)
	Sfx.play("deposit", -2)
	b.burst()
	b.relocate(_new_bin_pos(b))


func _new_bin_pos(moving) -> Vector3:
	var best := Vector3.ZERO
	var best_score := -1.0
	for i in 16:
		var a := randf() * TAU
		var d := randf_range(18.0, 32.0)
		var p := _clamp_arena(player.position + Vector3(cos(a) * d, 0, sin(a) * d), 4.0)
		var score := 1000.0
		for o in bins:
			if o != moving:
				score = minf(score, _flat_dist(o.position, p))
		if score > best_score:
			best_score = score
			best = p
		if score > 12.0:
			break
	return best


# --- flow --------------------------------------------------------------------

func on_level_up() -> void:
	Sfx.play("levelup", -3)
	level_ui.queue_level_up()


func roll_choices() -> Array:
	var pool := []
	for id in GameData.WEAPONS:
		var lv: int = player.weapon_level(id)
		if lv < 5:
			pool.append({"kind": "weapon", "id": id, "level": lv + 1, "w": 1.6 if lv > 0 else 1.0})
	for id in GameData.PASSIVES:
		var lv: int = player.plv(id)
		if lv < 5:
			pool.append({"kind": "passive", "id": id, "level": lv + 1, "w": 1.0})
	var out := []
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


func apply_choice(c: Dictionary) -> void:
	match c.kind:
		"weapon":
			player.add_or_upgrade_weapon(c.id)
		"passive":
			player.add_or_upgrade_passive(c.id)
		"heal":
			player.heal(30.0)


func on_player_died() -> void:
	_finish.call_deferred(false)


func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	if autotest:
		print("[autotest] finished win=%s t=%.1f lv=%d kills=%d" % [win, elapsed, player.level, kills])
	level_ui.close()
	await get_tree().create_timer(1.2 if win else 0.6).timeout
	get_tree().paused = true
	Sfx.play("win" if win else "lose")
	end_ui.show_result(win, {
		"time": elapsed, "kills": kills, "level": player.level,
		"recycled": recycled, "collected": collected,
	})


# --- helpers / fx --------------------------------------------------------------

func _clamp_arena(p: Vector3, margin := 0.0) -> Vector3:
	return Vector3(
		clampf(p.x, -GameData.ARENA_X + margin, GameData.ARENA_X - margin),
		0.0,
		clampf(p.z, GameData.ARENA_Z_MIN + margin, GameData.ARENA_Z_MAX - margin))


func _flat_dist(a: Vector3, b: Vector3) -> float:
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
	l.position = pos + Vector3(randf_range(-0.3, 0.3), 1.6, 0)
	l.visible = true
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.2, 0.45).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.45).set_delay(0.15)
	tw.tween_callback(func(): l.visible = false)
	_dmg_tweens[i] = tw


func _spawn_burst(pos: Vector3, color: Color, amount: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 9.0
	p.gravity = Vector3(0, -15, 0)
	p.mesh = MF.box_mesh(Vector3(0.2, 0.2, 0.2))
	p.material_override = MF.mat(color, 1.0)
	fx_root.add_child(p)
	p.position = pos + Vector3(0, 0.6, 0)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


# --- world -------------------------------------------------------------------

func _setup_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.8, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.82, 0.9)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 0.8
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)


func _build_arena() -> void:
	var world := _make_root("World")
	var x0 := GameData.ARENA_X + 6.0
	# grass park
	var grass := MeshInstance3D.new()
	var gm := PlaneMesh.new()
	gm.size = Vector2(x0 * 2.0, GameData.ARENA_Z_MAX - GameData.ARENA_Z_MIN + 12.0)
	grass.mesh = gm
	grass.position = Vector3(0, 0, (GameData.ARENA_Z_MAX + GameData.ARENA_Z_MIN) * 0.5 - 4.0)
	grass.material_override = _checker_material(Color(0.3, 0.52, 0.22), Color(0.27, 0.48, 0.2), 4.0)
	world.add_child(grass)
	# beach strip
	var sand := MeshInstance3D.new()
	var sm := PlaneMesh.new()
	sm.size = Vector2(x0 * 2.0 + 60.0, 12.0)
	sand.mesh = sm
	sand.position = Vector3(0, 0.01, GameData.ARENA_Z_MAX + 2.0)
	sand.material_override = _checker_material(Color(0.93, 0.85, 0.62), Color(0.9, 0.82, 0.58), 3.0)
	world.add_child(sand)
	# Mediterranean sea
	var sea := MeshInstance3D.new()
	var wm := PlaneMesh.new()
	wm.size = Vector2(x0 * 2.0 + 120.0, 80.0)
	sea.mesh = wm
	sea.position = Vector3(0, -0.15, GameData.ARENA_Z_MAX + 48.0)
	sea.material_override = _water_material()
	world.add_child(sea)
	# outer ground so camera never sees the void
	var outer := MeshInstance3D.new()
	var om := PlaneMesh.new()
	om.size = Vector2(400, 400)
	outer.mesh = om
	outer.position = Vector3(0, -0.3, -120)
	outer.material_override = MF.mat(Color(0.33, 0.55, 0.27))
	world.add_child(outer)
	# paths: a cross of paving through the park
	MF.box(world, Vector3(4.0, 0.04, GameData.ARENA_Z_MAX - GameData.ARENA_Z_MIN), Color(0.62, 0.56, 0.48), Vector3(0, 0.02, (GameData.ARENA_Z_MAX + GameData.ARENA_Z_MIN) * 0.5), false)
	MF.box(world, Vector3(GameData.ARENA_X * 2.0, 0.04, 4.0), Color(0.62, 0.56, 0.48), Vector3(0, 0.02, -10), false)
	# fountain at the crossing
	MF.cyl(world, 3.0, 3.2, 0.6, Color(0.85, 0.85, 0.82), Vector3(0, 0.3, -10))
	MF.cyl(world, 2.6, 2.6, 0.05, Color(0.35, 0.7, 0.95), Vector3(0, 0.62, -10), false)
	MF.cyl(world, 0.3, 0.4, 1.6, Color(0.85, 0.85, 0.82), Vector3(0, 1.2, -10))
	# northern edge: white houses with terracotta roofs
	var x := -GameData.ARENA_X - 4.0
	while x < GameData.ARENA_X + 4.0:
		var w := randf_range(5.0, 8.0)
		var h := randf_range(4.0, 8.0)
		var zc := GameData.ARENA_Z_MIN - 6.0 + randf_range(-1.0, 1.0)
		MF.box(world, Vector3(w, h, 6.0), Color(0.96, 0.94, 0.9), Vector3(x + w * 0.5, h * 0.5, zc))
		MF.inst(MF.prism_mesh(Vector3(w + 0.4, 1.8, 6.4)), MF.mat(Color(0.8, 0.38, 0.22)), world, Vector3(x + w * 0.5, h + 0.9, zc))
		for wi in int(w / 2.0):
			MF.box(world, Vector3(0.8, 1.0, 0.05), Color(0.3, 0.55, 0.75), Vector3(x + 1.2 + wi * 2.0, h * 0.6, zc + 3.03), false)
		x += w + randf_range(0.5, 1.5)
	# east / west: rows of pines
	for side in [-1.0, 1.0]:
		var z := GameData.ARENA_Z_MIN
		while z < GameData.ARENA_Z_MAX:
			_pine(world, Vector3(side * (GameData.ARENA_X + randf_range(3.0, 6.0)), 0, z))
			z += randf_range(3.0, 5.0)
	# palms along the beach
	var px := -GameData.ARENA_X
	while px < GameData.ARENA_X:
		_palm(world, Vector3(px, 0, GameData.ARENA_Z_MAX - 2.0 + randf_range(-1.0, 1.0)))
		px += randf_range(6.0, 10.0)
	# scattered park props
	for i in 70:
		var p := Vector3(randf_range(-GameData.ARENA_X, GameData.ARENA_X), 0, randf_range(GameData.ARENA_Z_MIN, GameData.ARENA_Z_MAX - 6.0))
		if absf(p.x) < 4.0 or absf(p.z + 10.0) < 4.0:
			continue
		match i % 5:
			0, 1:
				_palm(world, p)
			2:
				_tree(world, p)
			3:
				_bench(world, p)
			4:
				_flowers(world, p)


func _pine(parent: Node3D, p: Vector3) -> void:
	MF.cyl(parent, 0.18, 0.25, 1.2, Color(0.45, 0.3, 0.18), p + Vector3(0, 0.6, 0))
	MF.cyl(parent, 0.0, 1.4, 2.4, Color(0.15, 0.42, 0.22), p + Vector3(0, 2.2, 0))
	MF.cyl(parent, 0.0, 1.0, 1.8, Color(0.18, 0.48, 0.25), p + Vector3(0, 3.3, 0))


func _palm(parent: Node3D, p: Vector3) -> void:
	var trunk := MF.cyl(parent, 0.14, 0.24, 4.0, Color(0.6, 0.45, 0.28), p + Vector3(0, 2.0, 0))
	trunk.rotation.z = randf_range(-0.12, 0.12)
	var top := p + Vector3(-sin(trunk.rotation.z) * 2.0, 4.0, 0)
	for k in 6:
		var leaf := MF.box(parent, Vector3(0.5, 0.06, 2.0), Color(0.2, 0.6, 0.25), top, true)
		leaf.rotation = Vector3(0.45, float(k) / 6.0 * TAU, 0)
		leaf.position += Vector3(sin(leaf.rotation.y), -0.3, cos(leaf.rotation.y)) * 0.8
	MF.sphere(parent, 0.18, Color(0.45, 0.32, 0.15), top + Vector3(0.15, -0.2, 0), false)


func _tree(parent: Node3D, p: Vector3) -> void:
	MF.cyl(parent, 0.2, 0.28, 1.6, Color(0.45, 0.3, 0.18), p + Vector3(0, 0.8, 0))
	MF.sphere(parent, 1.2, Color(0.3, 0.58, 0.25), p + Vector3(0, 2.3, 0))
	MF.sphere(parent, 0.8, Color(0.35, 0.65, 0.28), p + Vector3(0.6, 2.9, 0.2))


func _bench(parent: Node3D, p: Vector3) -> void:
	var b := Node3D.new()
	parent.add_child(b)
	b.position = p
	b.rotation.y = randf() * TAU
	MF.box(b, Vector3(1.8, 0.1, 0.5), Color(0.6, 0.4, 0.22), Vector3(0, 0.5, 0))
	MF.box(b, Vector3(1.8, 0.4, 0.08), Color(0.6, 0.4, 0.22), Vector3(0, 0.8, -0.24))
	MF.box(b, Vector3(0.1, 0.5, 0.4), Color(0.2, 0.2, 0.22), Vector3(-0.8, 0.25, 0))
	MF.box(b, Vector3(0.1, 0.5, 0.4), Color(0.2, 0.2, 0.22), Vector3(0.8, 0.25, 0))


func _flowers(parent: Node3D, p: Vector3) -> void:
	MF.cyl(parent, 1.2, 1.3, 0.3, Color(0.5, 0.35, 0.2), p + Vector3(0, 0.15, 0))
	var cols := [Color(0.95, 0.3, 0.4), Color(1, 0.85, 0.2), Color(0.7, 0.4, 0.95), Color(1, 1, 1)]
	for k in 6:
		var a := float(k) / 6.0 * TAU
		MF.sphere(parent, 0.22, cols[k % cols.size()], p + Vector3(cos(a) * 0.7, 0.45, sin(a) * 0.7), false)


func _checker_material(a: Color, b: Color, tile: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform vec4 color_a : source_color;
uniform vec4 color_b : source_color;
uniform float tile = 4.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 c = floor(wpos.xz / tile);
	float k = mod(c.x + c.y, 2.0);
	float n = fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
	ALBEDO = mix(color_a.rgb, color_b.rgb, k) * (0.96 + n * 0.08);
	ROUGHNESS = 1.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("color_a", a)
	m.set_shader_parameter("color_b", b)
	m.set_shader_parameter("tile", tile)
	return m


func _water_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float w1 = sin(wpos.x * 0.45 + TIME * 1.4) * 0.5 + 0.5;
	float w2 = sin(wpos.z * 0.6 - TIME * 1.1 + wpos.x * 0.2) * 0.5 + 0.5;
	vec3 deep = vec3(0.05, 0.38, 0.62);
	vec3 shallow = vec3(0.2, 0.7, 0.85);
	float shore = clamp(1.0 - (wpos.z - 64.0) / 12.0, 0.0, 1.0);
	vec3 col = mix(deep, shallow, shore * 0.7 + w1 * w2 * 0.25);
	col += vec3(0.6) * step(0.97, w1 * w2) * 0.4;
	ALBEDO = col;
	ROUGHNESS = 0.15;
	SPECULAR = 0.7;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
