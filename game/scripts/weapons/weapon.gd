extends Node3D
## Base class for all weapons. Ticked by game.gd after enemies move.
## Levels 1-5 come from level-up cards; level 6 is the evolved form.

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
	level = mini(level + 1, 5)
	_on_level()


func evolve() -> void:
	evolved = true
	level = 6
	_on_level()
	_on_evolve()
	game.fx.big_burst(player.position, GameData.WEAPONS[id].color, 40)


func _on_level() -> void:
	pass


## Optional one-off visual change when evolving.
func _on_evolve() -> void:
	pass


## Cooldown scaled by the player's cooldown multiplier.
func cd(base: float) -> float:
	return base * player.cooldown_mult()


## Radius / size scaled by the player's area multiplier.
func area(base: float) -> float:
	return base * player.area_mult()


func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
