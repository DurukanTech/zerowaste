extends "res://scripts/weapons/weapon.gd"
## Fires glass shards at the nearest enemy.

# count, damage, pierce, cooldown
const STATS := [[1, 9.0, 1, 0.9], [2, 9.0, 1, 0.9], [2, 9.0, 2, 0.85], [3, 13.0, 2, 0.8], [3, 13.0, 3, 0.6]]
const SPEED := 20.0
const LIFE := 1.1

var _shots: Array = []


func tick(delta: float) -> void:
	var s: Array = STATS[level - 1]
	timer -= delta
	if timer <= 0.0:
		var target = game.nearest_enemy(player.position, 17.0)
		if target:
			timer = cd(s[3])
			var dir := flat(target.position - player.position).normalized()
			var n: int = s[0]
			for i in n:
				_fire(dir.rotated(Vector3.UP, (i - (n - 1) / 2.0) * 0.16), s)
			Sfx.play("shoot", -10, 0.06)
		else:
			timer = 0.1
	for i in range(_shots.size() - 1, -1, -1):
		var sh: Dictionary = _shots[i]
		var node: Node3D = sh.node
		node.position += sh.vel * delta
		sh.life -= delta
		var done: bool = sh.life <= 0.0
		if not done:
			for e in game.enemies_near(node.position, 0.35):
				if sh.hit.has(e):
					continue
				sh.hit[e] = true
				game.damage_enemy(e, s[1], sh.vel.normalized(), 2.0)
				sh.pierce -= 1
				if sh.pierce <= 0:
					done = true
					break
		if done:
			node.queue_free()
			_shots.remove_at(i)


func _fire(dir: Vector3, s: Array) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = player.position + Vector3(0, 0.8, 0) + dir * 0.5
	node.rotation.y = atan2(dir.x, dir.z)
	var m := MF.inst(MF.prism_mesh(Vector3(0.22, 0.6, 0.08)), MF.mat(Color(0.6, 1.0, 0.8, 0.9), 1.6), node, Vector3.ZERO, false)
	m.rotation_degrees.x = 90
	_shots.append({"node": node, "vel": dir * SPEED, "life": LIFE, "pierce": s[2], "hit": {}})
