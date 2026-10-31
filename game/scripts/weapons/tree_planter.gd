extends "res://scripts/weapons/weapon.gd"
## Sapling Planter: plants saplings near the player that grow and shoot
## leaves at nearby waste until they wither.

const ModelBuilder = preload("res://scripts/model_builder.gd")
const Fx = preload("res://scripts/fx.gd")

# max saplings, leaf damage, fire interval, lifetime, range
const STATS := [[1, 8.0, 0.9, 7.0, 7.0], [2, 8.0, 0.9, 7.0, 7.0], [2, 11.0, 0.9, 9.0, 7.5], [3, 11.0, 0.7, 9.0, 8.0], [4, 15.0, 0.7, 10.0, 8.5], [5, 20.0, 0.45, 12.0, 10.0]]
const PLANT_CD := 3.2
const LEAF_SPEED := 15.0

static var _meshes := {}

var _trees: Array = []
var _leaves: Array = []


static func _tree_mesh(big: bool) -> Mesh:
	var key := "big" if big else "small"
	if not _meshes.has(key):
		var mb := ModelBuilder.new()
		var bark := Color(0.45, 0.3, 0.18)
		if big:
			mb.cyl(0.14, 0.22, 1.6, bark, Vector3(0, 0.8, 0))
			mb.sphere(0.95, Color(0.22, 0.6, 0.22), Vector3(0, 2.0, 0), Vector3(1, 0.85, 1))
			mb.sphere(0.7, Color(0.3, 0.72, 0.26), Vector3(0.45, 2.45, 0.2))
			mb.sphere(0.6, Color(0.26, 0.66, 0.24), Vector3(-0.5, 2.3, -0.25))
			for i in 6:
				var a := float(i) / 6.0 * TAU
				mb.sphere(0.1, Color(1.0, 0.55, 0.15), Vector3(cos(a) * 0.8, 1.9 + sin(i * 1.3) * 0.3, sin(a) * 0.8))
		else:
			mb.cyl(0.06, 0.1, 0.8, bark, Vector3(0, 0.4, 0))
			mb.sphere(0.45, Color(0.3, 0.72, 0.28), Vector3(0, 1.0, 0), Vector3(1, 0.9, 1))
			mb.sphere(0.3, Color(0.38, 0.8, 0.32), Vector3(0.22, 1.22, 0.1))
			mb.prism(Vector3(0.18, 0.25, 0.04), Color(0.5, 0.9, 0.4), Vector3(-0.3, 1.25, 0), Vector3(0, 0, 0.6))
		_meshes[key] = mb.commit()
	return _meshes[key]


static func _leaf_mesh() -> Mesh:
	if not _meshes.has("leaf"):
		var mb := ModelBuilder.new()
		mb.sphere(0.16, Color(0.5, 0.95, 0.35), Vector3.ZERO, Vector3(0.55, 0.2, 1.2), Vector3.ZERO, 0)
		_meshes["leaf"] = mb.commit()
	return _meshes["leaf"]


func tick(delta: float) -> void:
	var s: Array = row(STATS, 1, 2)
	timer -= delta
	if timer <= 0.0 and _trees.size() < s[0]:
		timer = cd(PLANT_CD)
		_plant(s)
	for i in range(_trees.size() - 1, -1, -1):
		var t: Dictionary = _trees[i]
		t.life -= delta
		t.fire -= delta
		t.node.rotation.y += delta * 0.3
		if t.fire <= 0.0:
			t.fire = cd(s[2])
			var target = game.nearest_enemy(t.node.position, area(s[4]))
			if target:
				var shots := 3 if evolved else 1
				for k in shots:
					var dir := flat(target.position - t.node.position).normalized().rotated(Vector3.UP, (k - (shots - 1) * 0.5) * 0.25)
					_shoot(t.node.position + Vector3(0, 1.4 if not evolved else 2.2, 0), dir, s[1])
		if t.life <= 0.0:
			var node: Node3D = t.node
			var tw := node.create_tween()
			tw.tween_property(node, "scale", Vector3(0.05, 0.05, 0.05), 0.35).set_ease(Tween.EASE_IN)
			tw.tween_callback(node.queue_free)
			_trees.remove_at(i)
	for i in range(_leaves.size() - 1, -1, -1):
		var l: Dictionary = _leaves[i]
		var node: Node3D = l.node
		node.position += l.vel * delta
		node.rotation.y += delta * 9.0
		l.life -= delta
		var done: bool = l.life <= 0.0
		if not done:
			var hits = game.enemies_near(node.position, 0.4)
			if not hits.is_empty():
				game.damage_enemy(hits[0], l.dmg, l.vel.normalized(), 1.5)
				done = true
		if done:
			node.queue_free()
			_leaves.remove_at(i)


func _plant(s: Array) -> void:
	var a := randf() * TAU
	var pos: Vector3 = player.position + Vector3(cos(a), 0, sin(a)) * randf_range(2.0, 4.0)
	var node := Node3D.new()
	add_child(node)
	node.position = Vector3(pos.x, 0, pos.z)
	MF.inst(_tree_mesh(evolved), MF.vc_mat(), node)
	Fx.ground(node, {"color": Color(0.45, 0.9, 0.35, 0.5), "inner": 0.75, "softness": 0.25, "intensity": 0.9}, 0.9 if not evolved else 1.4, 0.04)
	node.scale = Vector3(0.1, 0.1, 0.1)
	node.create_tween().tween_property(node, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	game.fx.shockwave(node.position, Color(0.5, 0.9, 0.35), 1.6, 0.3, 1.4)
	_trees.append({"node": node, "life": s[3], "fire": 0.4})


func _shoot(from: Vector3, dir: Vector3, dmg: float) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = from
	MF.inst(_leaf_mesh(), MF.vc_mat(false, 1.2), node, Vector3.ZERO, false)
	_leaves.append({"node": node, "vel": dir * LEAF_SPEED, "life": 0.9, "dmg": dmg})


func _on_evolve() -> void:
	# replace the saplings with grown trees
	for t in _trees:
		t.node.queue_free()
	_trees.clear()
	timer = 0.0
