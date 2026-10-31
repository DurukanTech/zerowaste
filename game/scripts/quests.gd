extends Node
## Short in-run objectives. Completing one opens a reward crate (bonus
## upgrade card) and charges the ultimate.

const FIRST := 60.0
const GAP := 32.0

var game
var active := {}        # {} when no quest is running
var completed := 0
var _next := FIRST
var _last_kind := ""


func tick(delta: float) -> void:
	if active.is_empty():
		if game.elapsed >= _next and game.elapsed < GameData.RUN_TIME - 15.0:
			_start()
		return
	active.left -= delta
	if active.kind == "nohit":
		active.progress = minf(active.goal, active.progress + delta)
	if active.kind == "combo":
		active.progress = maxf(active.progress, game.sorting.combo)
	if active.progress >= active.goal:
		_complete()
	elif active.left <= 0.0:
		game.hud.toast(Loc.t("quest_failed"), Color(1, 0.5, 0.4))
		_end()


func _start() -> void:
	var m: float = game.elapsed / 60.0
	var kinds := ["sort", "kills", "nohit", "combo"]
	if game.sorting.ewaste_point != null and game.sorting.ewaste_left > 25.0:
		kinds.append("ewaste")
		kinds.append("ewaste")
	kinds.erase(_last_kind)
	var kind: String = kinds.pick_random()
	_last_kind = kind
	var q := {"kind": kind, "progress": 0.0, "mat": ""}
	match kind:
		"sort":
			q.mat = GameData.BIN_TYPES.pick_random()
			q.goal = float(int(10 + m * 2.5))
			q.time = 75.0
		"kills":
			q.goal = float(int(50 + m * 45) / 10 * 10)
			q.time = 40.0
		"nohit":
			q.goal = 20.0
			q.time = 60.0
		"combo":
			q.goal = 3.0
			q.time = 100.0
		"ewaste":
			q.goal = 4.0
			q.time = game.sorting.ewaste_left
	q.left = q.time
	active = q
	game.hud.quest_started()
	Sfx.play("select", -8)


func text() -> String:
	if active.is_empty():
		return ""
	var t := Loc.t("quest_" + active.kind)
	return t.format({"n": int(active.goal), "mat": Loc.pick(GameData.MATERIALS[active.mat].name) if active.mat != "" else ""})


func _complete() -> void:
	completed += 1
	game.player.add_ult(25.0)
	game.give_chest()
	game.hud.toast(Loc.t("quest_done"), Color(0.62, 1.0, 0.7))
	Sfx.play("levelup", -6)
	_end()


func _end() -> void:
	active = {}
	_next = game.elapsed + GAP


# --- hooks ------------------------------------------------------------------------

func on_deposit(t: String, n: int) -> void:
	if active.get("kind") == "sort" and active.mat == t:
		active.progress += n


func on_kill() -> void:
	if active.get("kind") == "kills":
		active.progress += 1


func on_hurt() -> void:
	if active.get("kind") == "nohit":
		active.progress = 0.0


func on_ewaste(n: int) -> void:
	if active.get("kind") == "ewaste":
		active.progress += n
