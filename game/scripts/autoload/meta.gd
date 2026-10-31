extends Node
## Persistent progression: recycling points, bought upgrades, best results.
## Stored as JSON in user:// (IndexedDB on the web build).

signal changed

const PATH := "user://save.json"

var points := 0
var levels := {}  # upgrade id -> level
var best := {"time": 0.0, "kills": 0, "sorted": 0, "wins": 0, "runs": 0}
var volume := {"Music": 0.7, "SFX": 0.8}   # linear 0..1 per audio bus


func _ready() -> void:
	_load()
	for bus in volume:
		_apply_volume(bus)


func set_volume(bus: String, v: float) -> void:
	volume[bus] = clampf(v, 0.0, 1.0)
	_apply_volume(bus)
	_save()


func _apply_volume(bus: String) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	var v: float = volume[bus]
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


func lv(id: String) -> int:
	return int(levels.get(id, 0))


func cost(id: String) -> int:
	return GameData.meta_cost(id, lv(id))


func can_buy(id: String) -> bool:
	return lv(id) < GameData.META[id].max and points >= cost(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	points -= cost(id)
	levels[id] = lv(id) + 1
	_save()
	changed.emit()
	return true


func refund_all() -> void:
	for id in levels:
		for i in levels[id]:
			points += GameData.meta_cost(id, i)
	levels.clear()
	_save()
	changed.emit()


## Points for a finished run (also shown on the end screen).
static func run_points(stats: Dictionary, win: bool) -> int:
	var sorted := 0
	for t in GameData.BIN_TYPES:
		sorted += int(stats.recycled[t])
	var p := int(sorted / 2) + int(stats.kills / 50) + int(stats.level) + int(stats.get("ewaste_delivered", 0)) * 2 + int(stats.get("quests", 0)) * 10
	if win:
		p += 100
	return p


func record_run(stats: Dictionary, win: bool) -> int:
	var earned := run_points(stats, win)
	points += earned
	var sorted := 0
	for t in GameData.BIN_TYPES:
		sorted += int(stats.recycled[t])
	best.runs = int(best.runs) + 1
	best.time = maxf(float(best.time), float(stats.time))
	best.kills = maxi(int(best.kills), int(stats.kills))
	best.sorted = maxi(int(best.sorted), sorted)
	if win:
		best.wins = int(best.wins) + 1
	_save()
	changed.emit()
	return earned


func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"points": points, "levels": levels, "best": best, "volume": volume}))


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		points = int(data.get("points", 0))
		var l = data.get("levels", {})
		if l is Dictionary:
			for id in l:
				if GameData.META.has(id):
					levels[id] = clampi(int(l[id]), 0, GameData.META[id].max)
		var vol = data.get("volume", {})
		if vol is Dictionary:
			for k in volume:
				if vol.has(k):
					volume[k] = clampf(float(vol[k]), 0.0, 1.0)
		var b = data.get("best", {})
		if b is Dictionary:
			for k in best:
				if b.has(k):
					best[k] = b[k]
