extends Node3D
## Things that hurt the player besides contact: enemy projectiles and
## telegraphed ground slams (boss attacks, plastic rain).

const MF = preload("res://scripts/mesh_factory.gd")
const Fx = preload("res://scripts/fx.gd")
const PLAYER_R := 0.45

var game
var _shots: Array = []
var _pool: Array[MeshInstance3D] = []
var _slams: Array = []


func _ready() -> void:
	for i in 90:
		var mi := MF.inst(MF.sphere_mesh(1.0), MF.glow_mat(Color.WHITE, 2.0), self, Vector3.ZERO, false)
		mi.visible = false
		_pool.append(mi)


## Fires a glowing orb travelling flat across the arena.
func shoot(pos: Vector3, vel: Vector3, dmg: float, color: Color, radius := 0.32, life := 4.5) -> void:
	if _pool.is_empty():
		return
	var mi: MeshInstance3D = _pool.pop_back()
	mi.material_override = MF.glow_mat(color, 2.4)
	mi.position = Vector3(pos.x, 0.9, pos.z)
	mi.scale = Vector3.ONE * radius
	mi.visible = true
	_shots.append({"node": mi, "vel": Vector3(vel.x, 0, vel.z), "dmg": dmg, "r": radius, "life": life})


## Projectile ring around `pos` (boss patterns). `offset` rotates the ring.
func ring(pos: Vector3, count: int, speed: float, dmg: float, color: Color, offset := 0.0) -> void:
	for i in count:
		var a := offset + float(i) / count * TAU
		shoot(pos, Vector3(cos(a), 0, sin(a)) * speed, dmg, color)


## Telegraphed area: a disc fills up for `delay` seconds, then hits.
## `on_hit` (optional) runs at impact with the position.
func slam(pos: Vector3, radius: float, delay: float, dmg: float, color: Color, on_hit := Callable()) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = Vector3(pos.x, 0, pos.z)
	Fx.ground(root, {"color": Color(color, 0.85), "inner": 0.9, "softness": 0.06, "intensity": 1.6}, radius, 0.07)
	var fill := Fx.ground(root, {"color": Color(color, 0.45), "falloff": 0.3, "softness": 0.2, "intensity": 1.2}, radius * 0.05, 0.06)
	_slams.append({"root": root, "fill": fill, "pos": root.position, "r": radius, "t": 0.0, "delay": delay, "dmg": dmg, "color": color, "cb": on_hit})


func clear() -> void:
	for s in _shots:
		s.node.visible = false
		_pool.append(s.node)
	_shots.clear()
	for s in _slams:
		s.root.queue_free()
	_slams.clear()


func tick(delta: float) -> void:
	var p: Vector3 = game.player.position
	for i in range(_shots.size() - 1, -1, -1):
		var s: Dictionary = _shots[i]
		var node: MeshInstance3D = s.node
		node.position += s.vel * delta
		s.life -= delta
		var dx := node.position.x - p.x
		var dz := node.position.z - p.z
		var rr: float = s.r + PLAYER_R
		var hit := dx * dx + dz * dz < rr * rr
		if hit:
			game.player.hurt(s.dmg)
		if hit or s.life <= 0.0:
			node.visible = false
			_pool.append(node)
			_shots.remove_at(i)
	for i in range(_slams.size() - 1, -1, -1):
		var s: Dictionary = _slams[i]
		s.t += delta
		var k: float = clampf(s.t / s.delay, 0.0, 1.0)
		s.fill.scale = Vector3(s.r * k, 1, s.r * k)
		if s.t >= s.delay:
			var dx: float = s.pos.x - p.x
			var dz: float = s.pos.z - p.z
			if dx * dx + dz * dz < pow(s.r + PLAYER_R * 0.5, 2):
				game.player.hurt(s.dmg)
			game.fx.shockwave(s.pos, s.color, s.r * 1.3, 0.3, 2.2)
			game.fx.hit(s.pos)
			game.add_shake(0.08)
			if s.cb.is_valid():
				s.cb.call(s.pos)
			s.root.queue_free()
			_slams.remove_at(i)
