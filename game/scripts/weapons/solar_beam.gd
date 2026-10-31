extends "res://scripts/weapons/weapon.gd"
## Solar Beam: strikes random enemies near the player from the sky.

const Fx = preload("res://scripts/fx.gd")

# strikes, damage, cooldown, aoe radius
const STATS := [[1, 25.0, 2.2, 1.4], [2, 25.0, 2.0, 1.4], [2, 35.0, 1.8, 1.6], [3, 35.0, 1.6, 1.6], [4, 48.0, 1.3, 1.9]]


func tick(delta: float) -> void:
	var s: Array = STATS[level - 1]
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
	for e in game.enemies_near(pos, s[3]):
		game.damage_enemy(e, s[1])
	var fx := Node3D.new()
	add_child(fx)
	fx.position = Vector3(pos.x, 0, pos.z)
	var beam := Node3D.new()
	fx.add_child(beam)
	MF.inst(MF.cyl_mesh(0.22, 0.32, 26.0), MF.glow_mat(Color(1.0, 0.97, 0.8, 0.9), 3.0), beam, Vector3(0, 13, 0), false)
	MF.inst(MF.cyl_mesh(0.6, 0.9, 26.0), MF.glow_mat(Color(1.0, 0.8, 0.3, 0.25), 2.0), beam, Vector3(0, 13, 0), false)
	var disc := Fx.ground(fx, {"color": Color(1.0, 0.85, 0.35, 0.9), "falloff": 0.8, "softness": 0.4, "intensity": 2.5}, s[3] * 1.3, 0.06)
	var dm: ShaderMaterial = disc.material_override
	game.fx.shockwave(pos, Color(1.0, 0.85, 0.35), s[3] * 1.6, 0.3, 2.0)
	if light:
		game.fx.flash_light(pos + Vector3(0, 1.5, 0), Color(1.0, 0.85, 0.5), 2.5, 0.3)
	var tw := fx.create_tween().set_parallel()
	tw.tween_property(beam, "scale", Vector3(0.02, 1, 0.02), 0.3).set_ease(Tween.EASE_IN)
	tw.tween_method(func(v: float): dm.set_shader_parameter("intensity", v), 2.5, 0.0, 0.4)
	tw.chain().tween_callback(fx.queue_free)
