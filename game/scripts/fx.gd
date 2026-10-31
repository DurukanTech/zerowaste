extends Node3D
## Visual effects: one flat "ground fx" shader (rings, discs, swirls, glows)
## plus pooled particle bursts, so frequent effects never allocate.

const MF = preload("res://scripts/mesh_factory.gd")

const GROUND_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 color : source_color = vec4(1.0);
uniform float inner = 0.0;
uniform float softness = 0.15;
uniform float swirl = 0.0;
uniform float dashes = 0.0;
uniform float spin = 1.0;
uniform float falloff = 0.0;
uniform float intensity = 1.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	if (d > 1.0) discard;
	float a = 1.0 - smoothstep(1.0 - softness, 1.0, d);
	if (inner > 0.0) a *= smoothstep(inner - softness, inner, d);
	float ang = atan(p.y, p.x);
	if (dashes > 0.0) a *= smoothstep(-0.2, 0.2, sin(ang * dashes + TIME * spin));
	if (swirl > 0.0) a *= 1.0 - swirl + swirl * (0.5 + 0.5 * sin(ang * 5.0 + d * 12.0 - TIME * 3.0));
	a *= mix(1.0, 1.0 - d, falloff);
	ALBEDO = color.rgb * intensity;
	ALPHA = clamp(a * color.a, 0.0, 1.0);
}
"""

static var _shader: Shader
static var _plane: PlaneMesh

var _hits: Array[CPUParticles3D] = []
var _hit_i := 0
var _hit_cooldown := 0.0
var _deaths: Array[CPUParticles3D] = []
var _death_i := 0
var _rings: Array[MeshInstance3D] = []
var _ring_tweens: Array = []
var _ring_i := 0


static func ground_mat(params: Dictionary) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = GROUND_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


static func plane() -> PlaneMesh:
	if _plane == null:
		_plane = PlaneMesh.new()
		_plane.size = Vector2(2, 2)
	return _plane


## A flat effect quad lying on the ground; scale it to set the radius.
static func ground(parent: Node3D, params: Dictionary, radius := 1.0, y := 0.05) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = plane()
	mi.material_override = ground_mat(params)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = y
	mi.scale = Vector3(radius, 1, radius)
	parent.add_child(mi)
	return mi


static func burst(color: Color, amount: int, lifetime: float, vel: Vector2, size: float, glow := true, gravity := -14.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = vel.x
	p.initial_velocity_max = vel.y
	p.gravity = Vector3(0, gravity, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.mesh = MF.box_mesh(Vector3.ONE * size)
	p.material_override = MF.glow_mat(color, 2.5) if glow else MF.mat(color, 0.5)
	return p


func _ready() -> void:
	for i in 10:
		var h := burst(Color(1.0, 0.92, 0.6), 6, 0.25, Vector2(3, 6), 0.08)
		h.spread = 180.0
		add_child(h)
		_hits.append(h)
	for i in 12:
		var d := burst(Color.WHITE, 12, 0.55, Vector2(3, 7), 0.15, false)
		d.material_override = StandardMaterial3D.new()  # recolored per use
		add_child(d)
		_deaths.append(d)
	for i in 12:
		var r := ground(self, {"color": Color.WHITE, "inner": 0.82, "softness": 0.12}, 1.0, 0.08)
		r.visible = false
		_rings.append(r)
		_ring_tweens.append(null)


func _process(delta: float) -> void:
	_hit_cooldown -= delta


func hit(pos: Vector3) -> void:
	if _hit_cooldown > 0.0:
		return
	_hit_cooldown = 0.025
	var p := _hits[_hit_i]
	_hit_i = (_hit_i + 1) % _hits.size()
	p.position = pos + Vector3(0, 0.7, 0)
	p.restart()


func death(pos: Vector3, color: Color) -> void:
	var p := _deaths[_death_i]
	_death_i = (_death_i + 1) % _deaths.size()
	var m: StandardMaterial3D = p.material_override
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 0.6
	p.position = pos + Vector3(0, 0.5, 0)
	p.restart()
	shockwave(pos, color, 1.6, 0.3)


func shockwave(pos: Vector3, color: Color, radius: float, time: float, intensity := 1.6) -> void:
	var i := _ring_i
	_ring_i = (_ring_i + 1) % _rings.size()
	var r := _rings[i]
	if _ring_tweens[i]:
		_ring_tweens[i].kill()
	var m: ShaderMaterial = r.material_override
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("intensity", intensity)
	r.position = Vector3(pos.x, 0.08, pos.z)
	r.scale = Vector3(0.2, 1, 0.2)
	r.visible = true
	var tw := r.create_tween().set_parallel()
	tw.tween_property(r, "scale", Vector3(radius, 1, radius), time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(v: float): m.set_shader_parameter("intensity", v), intensity, 0.0, time)
	tw.chain().tween_callback(func(): r.visible = false)
	_ring_tweens[i] = tw


## Big one-off effects (boss death, level up). Allocates, so use sparingly.
func big_burst(pos: Vector3, color: Color, amount := 40, light := true) -> void:
	var p := burst(color, amount, 0.9, Vector2(5, 11), 0.22)
	p.spread = 90.0
	add_child(p)
	p.position = pos + Vector3(0, 0.8, 0)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)
	shockwave(pos, color, 6.0, 0.5, 2.5)
	if light:
		flash_light(pos + Vector3(0, 2, 0), color, 3.0, 0.5)


func level_up(pos: Vector3) -> void:
	var col := Color(0.55, 1.0, 0.75)
	var p := burst(col, 36, 1.0, Vector2(2, 5), 0.12, true, 4.0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 1.2
	p.emission_ring_inner_radius = 0.9
	p.emission_ring_height = 0.1
	p.spread = 10.0
	add_child(p)
	p.position = pos
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)
	shockwave(pos, col, 4.5, 0.45, 2.2)
	flash_light(pos + Vector3(0, 1.5, 0), col, 2.5, 0.6)


func flash_light(pos: Vector3, color: Color, energy: float, time: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = 7.0
	l.shadow_enabled = false
	add_child(l)
	l.position = pos
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, time)
	tw.tween_callback(l.queue_free)
