extends "res://scripts/weapons/weapon.gd"
## Tote Bag Wave: periodic knockback shockwave.

# radius, damage, cooldown, knockback
const STATS := [[4.5, 14.0, 3.2, 10.0], [5.0, 18.0, 3.0, 11.0], [5.5, 24.0, 2.8, 12.0], [6.0, 30.0, 2.5, 13.0], [7.0, 40.0, 2.1, 15.0], [9.0, 55.0, 1.9, 17.0]]


func tick(delta: float) -> void:
	var s: Array = STATS[level - 1]
	timer -= delta
	if timer > 0.0:
		return
	timer = cd(s[2])
	var r := area(s[0])
	for e in game.enemies_near(player.position, r):
		game.damage_enemy(e, s[1], flat(e.position - player.position).normalized(), s[3])
	# a cotton-colored double ripple
	game.fx.shockwave(player.position, Color(1.0, 0.92, 0.72), r, 0.32, 2.4)
	get_tree().create_timer(0.08).timeout.connect(func():
		game.fx.shockwave(player.position, Color(0.9, 0.75, 0.5), r * 0.75, 0.3, 1.4))
	if evolved:
		# Zero Waste Wave: every material in a wide radius flies to the player
		game.fx.shockwave(player.position, Color(0.62, 1.0, 0.7), r * 2.2, 0.5, 1.8)
		for g in game.gems:
			if game.flat_dist(g.position, player.position) < 30.0:
				g.magnet = true
	Sfx.play("whoosh", -4, 0.1)
