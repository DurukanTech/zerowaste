extends Node3D
## Base class for all weapons. Ticked by game.gd after enemies move.
## Levels 1-8 come from level-up cards (6-8 scale damage and cooldown of the
## level-5 row); evolving swaps in the evolved row and keeps those bonuses.

const MF = preload("res://scripts/mesh_factory.gd")

var id := ""
var level := 1
var evolved := false
var game
var player
var timer := 0.0


func setup(g, p) -> void:
	game = g
	player = p
	_on_level()


func tick(_delta: float) -> void:
	pass


func upgrade() -> void:
	level = mini(level + 1, GameData.WEAPON_MAX)
	_on_level()


func evolve() -> void:
	evolved = true
	level = GameData.WEAPON_MAX + 1
	_on_level()
	_on_evolve()
	game.fx.big_burst(player.position, GameData.WEAPONS[id].color, 40)


func _on_level() -> void:
	pass


## Optional one-off visual change when evolving.
func _on_evolve() -> void:
	pass


## Stats for the current level. `table` has 6 rows (levels 1-5 + evolved);
## levels above 5 add +18% damage and -6% cooldown each.
func row(table: Array, dmg_i: int, cd_i: int) -> Array:
	var r: Array = table[5] if evolved else table[mini(level, 5) - 1]
	var extra := mini(level, GameData.WEAPON_MAX) - 5
	if extra <= 0:
		return r
	r = r.duplicate()
	r[dmg_i] *= 1.0 + 0.18 * extra
	if cd_i >= 0:
		r[cd_i] *= 1.0 - 0.06 * extra
	return r


## Cooldown scaled by the player's cooldown multiplier.
func cd(base: float) -> float:
	return base * player.cooldown_mult()


## Radius / size scaled by the player's area multiplier.
func area(base: float) -> float:
	return base * player.area_mult()


func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
