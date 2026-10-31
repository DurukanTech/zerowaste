extends "res://scripts/weapons/weapon.gd"
## Solar Beam: strikes random enemies near the player from the sky.

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
		_strike(pool[i].position, s)
	Sfx.play("zap", -8, 0.1)


func _strike(pos: Vector3, s: Array) -> void:
	for e in game.enemies_near(pos, s[3]):
		game.damage_enemy(e, s[1])
	var fx := Node3D.new()
	add_child(fx)
	fx.position = Vector3(pos.x, 0, pos.z)
	MF.inst(MF.cyl_mesh(0.4, 0.4, 24.0), MF.mat(Color(1.0, 0.92, 0.4, 0.7), 2.5, true), fx, Vector3(0, 12, 0), false)
	var disc := MF.inst(MF.cyl_mesh(1.0, 1.0, 0.05), MF.mat(Color(1.0, 0.85, 0.3, 0.6), 2.0, true), fx, Vector3(0, 0.05, 0), false)
	disc.scale = Vector3(s[3], 1, s[3])
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector3(0.05, 1, 0.05), 0.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(fx.queue_free)
