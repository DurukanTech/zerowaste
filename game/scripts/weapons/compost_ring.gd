extends "res://scripts/weapons/weapon.gd"
## Compost Ring: damaging, slowing aura around the player.

# radius, damage, tick interval
const STATS := [[2.6, 5.0, 0.5], [3.0, 7.0, 0.5], [3.4, 9.0, 0.45], [3.8, 11.0, 0.4], [4.4, 14.0, 0.35]]

var _disc: MeshInstance3D
var _leaves: Node3D


func _on_level() -> void:
	if _disc == null:
		_disc = MF.inst(MF.cyl_mesh(1.0, 1.0, 0.04), MF.mat(Color(0.4, 0.55, 0.15, 0.35), 0.3, true), self, Vector3.ZERO, false)
		_leaves = Node3D.new()
		add_child(_leaves)
		for i in 10:
			var a := float(i) / 10.0 * TAU
			var leaf := MF.box(_leaves, Vector3(0.12, 0.04, 0.24), Color(0.5, 0.75, 0.2) if i % 2 == 0 else Color(0.5, 0.33, 0.15), Vector3(cos(a), 0.15, sin(a)), false)
			leaf.rotation.y = -a
	var r: float = STATS[level - 1][0]
	_disc.scale = Vector3(r, 1, r)
	_leaves.scale = Vector3(r, 1, r)


func tick(delta: float) -> void:
	var s: Array = STATS[level - 1]
	position = Vector3(player.position.x, 0.06, player.position.z)
	_leaves.rotation.y += delta * 1.2
	timer -= delta
	if timer <= 0.0:
		timer = cd(s[2])
		for e in game.enemies_near(player.position, s[0]):
			e.slow_t = 0.6
			game.damage_enemy(e, s[1])
