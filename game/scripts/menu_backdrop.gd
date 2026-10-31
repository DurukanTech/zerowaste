extends Node3D
## Live 3D diorama behind the main menu: the volunteer, the four bins and
## waste monsters circling on the coast at golden hour.

const MF = preload("res://scripts/mesh_factory.gd")
const WorldBuilder = preload("res://scripts/world_builder.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Gem = preload("res://scripts/gem.gd")
const RecycleBin = preload("res://scripts/recycle_bin.gd")

const CENTER := Vector3(6, 0, 42)
const CAM_DIST := 15.0
const CAM_HEIGHT := 6.5

var _cam: Camera3D
var _player: Node3D
var _blades: Node3D
var _bins: Array = []
var _walkers: Array = []  # {node, angle, radius, speed}
var _gems: Array = []
var _t := 0.0


func _ready() -> void:
	WorldBuilder.setup_environment(self, true)
	WorldBuilder.build_arena(self, CENTER, 24.0)

	_player = Player.new()
	_player.scale = Vector3.ONE * 1.5
	add_child(_player)
	_player.position = CENTER

	# wind turbine blades orbiting the hero
	_blades = Node3D.new()
	add_child(_blades)
	_blades.position = CENTER
	for i in 3:
		var b := Node3D.new()
		_blades.add_child(b)
		var a := float(i) / 3.0 * TAU
		b.position = Vector3(cos(a) * 2.6, 1.1, sin(a) * 2.6)
		for k in 3:
			var blade := MF.box(b, Vector3(0.12, 0.05, 0.75), Color(0.97, 0.98, 1.0), Vector3.ZERO, false)
			blade.rotation.y = float(k) / 3.0 * TAU
			blade.position = Vector3(sin(blade.rotation.y), 0, cos(blade.rotation.y)) * 0.38

	for i in GameData.BIN_TYPES.size():
		var bin = RecycleBin.new()
		add_child(bin)
		bin.setup(GameData.BIN_TYPES[i])
		bin.set_label_visible(false)  # the menu legend already names them
		var a := -PI * 0.5 + (float(i) - 1.5) * 0.5
		bin.position = CENTER + Vector3(cos(a), 0, sin(a)) * 6.5
		bin.rotation.y = -a - PI * 0.5
		_bins.append(bin)

	var kinds := ["bag", "bag", "bag", "bottle", "bottle", "rot", "rot", "box", "box", "battery", "bag", "bottle", "rot", "bag"]
	for i in kinds.size():
		var e = Enemy.new()
		e.setup(kinds[i], 1.0, 1.0)
		add_child(e)
		var w := {"node": e, "angle": float(i) / kinds.size() * TAU + randf() * 0.3, "radius": randf_range(9.0, 13.0), "speed": randf_range(0.12, 0.22)}
		_walkers.append(w)

	for i in 16:
		var g = Gem.new()
		g.setup(GameData.BIN_TYPES[i % 4], 1.0)
		add_child(g)
		var a := randf() * TAU
		g.position = CENTER + Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 8.5)
		_gems.append(g)

	_cam = Camera3D.new()
	_cam.fov = 48.0
	_cam.far = 400.0
	add_child(_cam)
	_cam.current = true
	_update_camera()


func _process(delta: float) -> void:
	_t += delta
	_update_camera()
	_blades.rotation.y += delta * 1.6
	for b in _blades.get_children():
		b.rotation.y += delta * 14.0
	for bin in _bins:
		bin.tick(delta)
	for g in _gems:
		g.animate(delta)
	var nearest: Node3D = null
	var nd := INF
	for w in _walkers:
		w.angle += w.speed * delta
		var e: Node3D = w.node
		var r: float = w.radius + sin(_t * 0.7 + w.angle * 3.0) * 1.2
		e.position = CENTER + Vector3(cos(w.angle), 0, sin(w.angle)) * r
		# face the hero, they are closing in
		var to := CENTER - e.position
		e.rotation.y = atan2(to.x, to.z)
		e.think(delta, null)
		if r < nd:
			nd = r
			nearest = e
	if nearest:
		var to := nearest.position - CENTER
		_player.rotation.y = lerp_angle(_player.rotation.y, atan2(to.x, to.z), minf(1.0, 3.0 * delta))
	_player.animate(delta, false)


func _update_camera() -> void:
	# slow orbit; the look target is shifted left so the hero sits on the
	# right third of the screen, clear of the menu column
	var a := _t * 0.05 + 0.4
	var cam_pos := CENTER + Vector3(sin(a) * CAM_DIST, CAM_HEIGHT, cos(a) * CAM_DIST)
	var fwd := (CENTER - cam_pos)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	_cam.position = cam_pos
	_cam.look_at(CENTER + Vector3(0, 1.4, 0) - right * 2.6)
