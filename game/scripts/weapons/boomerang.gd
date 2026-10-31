extends "res://scripts/weapons/weapon.gd"
## Reuse Boomerang: flies out, returns, pierces everything both ways.

# count, damage, range, cooldown
const STATS := [[1, 10.0, 8.0, 1.8], [1, 15.0, 8.5, 1.7], [2, 15.0, 9.0, 1.6], [2, 21.0, 9.5, 1.5], [3, 26.0, 10.0, 1.3]]
const SPEED := 15.0

var _rangs: Array = []


func tick(delta: float) -> void:
	var s: Array = STATS[level - 1]
	timer -= delta
	if timer <= 0.0:
		timer = cd(s[3])
		var target = game.nearest_enemy(player.position, 14.0)
		var dir: Vector3
		if target:
			dir = flat(target.position - player.position).normalized()
		else:
			dir = Vector3(sin(player.facing), 0, cos(player.facing))
		var n: int = s[0]
		for i in n:
			_throw(dir.rotated(Vector3.UP, float(i) / n * TAU), s[2])
		Sfx.play("whoosh", -14, 0.1)
	for i in range(_rangs.size() - 1, -1, -1):
		var r: Dictionary = _rangs[i]
		var node: Node3D = r.node
		node.rotation.y += delta * 18.0
		if not r.returning:
			node.position += r.dir * SPEED * delta
			r.dist += SPEED * delta
			if r.dist >= r.range:
				r.returning = true
				r.hit.clear()
		else:
			var to := flat(player.position - node.position)
			var d := to.length()
			if d < 0.7:
				node.queue_free()
				_rangs.remove_at(i)
				continue
			node.position += to / d * SPEED * 1.15 * delta
		for e in game.enemies_near(node.position, 0.6):
			if not r.hit.has(e):
				r.hit[e] = true
				game.damage_enemy(e, s[1], flat(e.position - node.position).normalized(), 3.0)


func _throw(dir: Vector3, rng: float) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = player.position + Vector3(0, 0.9, 0)
	var c := Color(1.0, 0.55, 0.2)
	var a := MF.box(node, Vector3(0.7, 0.08, 0.18), c, Vector3(0.25, 0, 0), false)
	a.rotation.y = 0.5
	var b := MF.box(node, Vector3(0.7, 0.08, 0.18), Color(0.2, 0.75, 0.7), Vector3(-0.25, 0, 0), false)
	b.rotation.y = -0.5
	_rangs.append({"node": node, "dir": dir, "dist": 0.0, "range": rng, "returning": false, "hit": {}})
