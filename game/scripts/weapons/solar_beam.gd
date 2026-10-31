extends "res://scripts/weapons/weapon.gd"
## Solar Beam: strikes random enemies near the player from the sky.

const Fx = preload("res://scripts/fx.gd")

var _patches: Array = []

# strikes, damage, cooldown, aoe radius
const STATS := [[1, 25.0, 2.2, 1.4], [2, 25.0, 2.0, 1.4], [2, 35.0, 1.8, 1.6], [3, 35.0, 1.6, 1.6], [4, 48.0, 1.3, 1.9], [6, 60.0, 1.0, 2.2]]


func tick(delta: float) -> void:
	var s: Array = STATS[level - 1]
	_tick_patches(delta)
	timer -= delta
	if timer > 0.0:
		return
	var pool: Array = game.enemies_near(player.position, 14.0)
	if pool.is_empty():
		timer = 0.2
		return
	timer = cd(s[2])
	pool.shuffle()
	for i in mini(s[0], pool.size()):
		_strike(pool[i].position, s, i == 0)
	Sfx.play("zap", -8, 0.1)


func _strike(pos: Vector3, s: Array, light: bool) -> void:
	var r := area(s[3])
	for e in game.enemies_near(pos, r):
		game.damage_enemy(e, s[1])
	if evolved:
		_add_patch(pos, r)
	var fx := Node3D.new()
	add_child(fx)
	fx.position = Vector3(pos.x, 0, pos.z)
	var beam := Node3D.new()
	fx.add_child(beam)
	MF.inst(MF.cyl_mesh(0.22, 0.32, 26.0), MF.glow_mat(Color(1.0, 0.97, 0.8, 0.9), 3.0), beam, Vector3(0, 13, 0), false)
	MF.inst(MF.cyl_mesh(0.6, 0.9, 26.0), MF.glow_mat(Color(1.0, 0.8, 0.3, 0.25), 2.0), beam, Vector3(0, 13, 0), false)
	var disc := Fx.ground(fx, {"color": Color(1.0, 0.85, 0.35, 0.9), "falloff": 0.8, "softness": 0.4, "intensity": 2.5}, r * 1.3, 0.06)
	var dm: ShaderMaterial = disc.material_override
	game.fx.shockwave(pos, Color(1.0, 0.85, 0.35), r * 1.6, 0.3, 2.0)
	if light:
		game.fx.flash_light(pos + Vector3(0, 1.5, 0), Color(1.0, 0.85, 0.5), 2.5, 0.3)
	var tw := fx.create_tween().set_parallel()
	tw.tween_property(beam, "scale", Vector3(0.02, 1, 0.02), 0.3).set_ease(Tween.EASE_IN)
	tw.tween_method(func(v: float): dm.set_shader_parameter("intensity", v), 2.5, 0.0, 0.4)
	tw.chain().tween_callback(fx.queue_free)


## Solar Farm: every strike leaves a burning patch of light for a few seconds.
func _add_patch(pos: Vector3, r: float) -> void:
	var m := Fx.ground(self, {"color": Color(1.0, 0.7, 0.2, 0.6), "swirl": 0.5, "softness": 0.5, "intensity": 1.4}, r * 1.2, 0.05)
	m.position = Vector3(pos.x, 0.05, pos.z)
	_patches.append({"node": m, "pos": pos, "r": r * 1.2, "life": 2.6, "tick": 0.0})


func _tick_patches(delta: float) -> void:
	for i in range(_patches.size() - 1, -1, -1):
		var p: Dictionary = _patches[i]
		p.life -= delta
		p.tick -= delta
		if p.tick <= 0.0:
			p.tick = 0.4
			for e in game.enemies_near(p.pos, p.r):
				game.damage_enemy(e, 9.0)
		p.node.material_override.set_shader_parameter("intensity", clampf(p.life, 0.0, 1.0) * 1.4)
		p.node.rotation.y += delta
		if p.life <= 0.0:
			p.node.queue_free()
			_patches.remove_at(i)
