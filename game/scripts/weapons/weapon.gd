extends Node3D
## Base class for all weapons. Ticked by game.gd after enemies move.

const MF = preload("res://scripts/mesh_factory.gd")

var id := ""
var level := 1
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


func _on_level() -> void:
	pass


## Cooldown scaled by the player's cooldown multiplier.
func cd(base: float) -> float:
	return base * player.cooldown_mult()


func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
