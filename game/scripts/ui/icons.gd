extends Control
## Small vector icon drawn in code (weapons, passives, buffs, materials, HUD glyphs).
## Usage: Icons.make("solar", Color.YELLOW, 32)

var id := ""
var color := Color.WHITE


static func make(icon_id: String, c: Color, px := 28.0) -> Control:
	var i = load("res://scripts/ui/icons.gd").new()
	i.id = icon_id
	i.color = c
	i.custom_minimum_size = Vector2(px, px)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	i.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return i


func set_icon(icon_id: String, c: Color) -> void:
	id = icon_id
	color = c
	queue_redraw()


func _draw() -> void:
	draw_icon(self, id, size * 0.5, minf(size.x, size.y) * 0.5, color)


## Draws icon `id` centered at `o` with half-size `r` onto any CanvasItem.
static func draw_icon(ci: CanvasItem, id: String, o: Vector2, r: float, c: Color) -> void:
	var w := maxf(1.5, r * 0.16)
	var dark := Color(0, 0, 0, 0.35)
	match id:
		# --- weapons ---
		"glass":
			for k in 3:
				var a := -0.5 + k * 0.5
				var p := o + Vector2(cos(a - PI * 0.5), sin(a - PI * 0.5)) * r * 0.15
				var tip := p + Vector2(sin(a), -cos(a)) * r * 0.85
				var side := Vector2(cos(a), sin(a)) * r * 0.22
				ci.draw_colored_polygon(PackedVector2Array([tip, p + side + Vector2(0, r * 0.6), p - side + Vector2(0, r * 0.6)]), c if k != 1 else c.lightened(0.3))
		"boomerang":
			var pts := PackedVector2Array([o + Vector2(-r * 0.85, -r * 0.3), o + Vector2(0, r * 0.55), o + Vector2(r * 0.85, -r * 0.3)])
			ci.draw_polyline(pts, c, w * 2.2, true)
			ci.draw_circle(pts[0], w * 1.1, c)
			ci.draw_circle(pts[2], w * 1.1, c)
		"compost":
			ci.draw_arc(o, r * 0.78, 0.0, TAU, 32, Color(c, 0.6), w, true)
			_leaf(ci, o, r * 0.62, -0.6, c.lightened(0.15))
		"turbine":
			for k in 3:
				var a := k * TAU / 3.0 - PI * 0.5
				var d := Vector2(cos(a), sin(a))
				var n := d.orthogonal()
				ci.draw_colored_polygon(PackedVector2Array([o + n * r * 0.12, o + d * r * 0.95, o - n * r * 0.18 + d * r * 0.3]), c)
			ci.draw_circle(o, r * 0.18, c.darkened(0.3))
		"solar":
			for k in 8:
				var a := k * TAU / 8.0
				var d := Vector2(cos(a), sin(a))
				ci.draw_line(o + d * r * 0.58, o + d * r * 0.95, c, w, true)
			ci.draw_circle(o, r * 0.45, c)
		"tote":
			ci.draw_arc(o + Vector2(0, -r * 0.2), r * 0.32, PI, TAU, 16, c, w, true)
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.62, -r * 0.2), o + Vector2(r * 0.62, -r * 0.2), o + Vector2(r * 0.72, r * 0.8), o + Vector2(-r * 0.72, r * 0.8)]), c)
			_leaf(ci, o + Vector2(0, r * 0.32), r * 0.3, -0.6, Color(0.2, 0.6, 0.3))
		"tree":
			ci.draw_rect(Rect2(o + Vector2(-r * 0.12, r * 0.1), Vector2(r * 0.24, r * 0.85)), c.darkened(0.45))
			ci.draw_circle(o + Vector2(0, -r * 0.25), r * 0.55, c)
			ci.draw_circle(o + Vector2(-r * 0.38, r * 0.05), r * 0.35, c.darkened(0.12))
			ci.draw_circle(o + Vector2(r * 0.38, r * 0.05), r * 0.35, c.lightened(0.1))
		"water":
			var drop := PackedVector2Array([o + Vector2(0, -r * 0.95)])
			for k in 13:
				var a := PI * 0.15 - k / 12.0 * PI * 1.3
				drop.append(o + Vector2(cos(a) * r * 0.55, r * 0.3 - sin(a) * r * 0.55))
			ci.draw_colored_polygon(drop, c)
			ci.draw_arc(o + Vector2(0, r * 0.3), r * 0.32, PI * 0.55, PI * 0.95, 8, Color(1, 1, 1, 0.7), w, true)
		# --- passives ---
		"repair":
			var d := Vector2(1, -1).normalized()
			ci.draw_line(o - d * r * 0.7, o + d * r * 0.35, c, w * 2.0, true)
			var head := o + d * r * 0.55
			ci.draw_circle(head, r * 0.36, c)
			ci.draw_circle(head + d * r * 0.18, r * 0.2, c.darkened(0.6))
			ci.draw_circle(o - d * r * 0.7, w * 1.1, c)
		"seeds":
			ci.draw_line(o + Vector2(0, r * 0.85), o + Vector2(0, -r * 0.2), c.darkened(0.2), w * 1.3, true)
			_leaf(ci, o + Vector2(-r * 0.32, -r * 0.3), r * 0.42, -2.6, Color(0.5, 0.9, 0.35))
			_leaf(ci, o + Vector2(r * 0.32, -r * 0.42), r * 0.42, -0.5, Color(0.45, 0.85, 0.3))
			ci.draw_circle(o + Vector2(0, r * 0.75), r * 0.22, c)
		"bike":
			ci.draw_arc(o + Vector2(-r * 0.5, r * 0.25), r * 0.38, 0, TAU, 20, c, w, true)
			ci.draw_arc(o + Vector2(r * 0.5, r * 0.25), r * 0.38, 0, TAU, 20, c, w, true)
			ci.draw_polyline(PackedVector2Array([o + Vector2(-r * 0.5, r * 0.25), o + Vector2(-r * 0.1, -r * 0.35), o + Vector2(r * 0.35, -r * 0.35), o + Vector2(r * 0.5, r * 0.25)]), c, w, true)
			ci.draw_line(o + Vector2(-r * 0.1, -r * 0.35), o + Vector2(0, r * 0.25), c, w, true)
		"canteen":
			ci.draw_rect(Rect2(o + Vector2(-r * 0.18, -r * 0.95), Vector2(r * 0.36, r * 0.25)), c.darkened(0.25))
			_rrect(ci, Rect2(o + Vector2(-r * 0.45, -r * 0.7), Vector2(r * 0.9, r * 1.6)), r * 0.25, c)
			ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 0.05), Vector2(r * 0.9, r * 0.35)), Color(1, 1, 1, 0.45))
		"net":
			ci.draw_arc(o + Vector2(-r * 0.15, -r * 0.15), r * 0.6, 0, TAU, 24, c, w, true)
			for k in 3:
				var f := -0.4 + k * 0.4
				ci.draw_line(o + Vector2(-r * 0.15 + f * r, -r * 0.7), o + Vector2(-r * 0.15 + f * r, r * 0.4), Color(c, 0.6), w * 0.6)
				ci.draw_line(o + Vector2(-r * 0.7, -r * 0.15 + f * r), o + Vector2(r * 0.4, -r * 0.15 + f * r), Color(c, 0.6), w * 0.6)
			ci.draw_line(o + Vector2(r * 0.3, r * 0.3), o + Vector2(r * 0.9, r * 0.9), c, w * 1.6, true)
		"awareness":
			var eye := PackedVector2Array()
			for k in 17:
				var a := k / 16.0 * PI
				eye.append(o + Vector2(-cos(a) * r * 0.9, -sin(a) * r * 0.5))
			for k in range(15, 0, -1):
				var a := k / 16.0 * PI
				eye.append(o + Vector2(-cos(a) * r * 0.9, sin(a) * r * 0.5))
			ci.draw_colored_polygon(eye, c)
			ci.draw_circle(o, r * 0.3, Color(0.05, 0.2, 0.1))
			_leaf(ci, o, r * 0.22, -0.6, c)
		"efficiency":
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(r * 0.2, -r), o + Vector2(-r * 0.55, r * 0.15), o + Vector2(-r * 0.02, r * 0.15), o + Vector2(-r * 0.2, r), o + Vector2(r * 0.55, -r * 0.15), o + Vector2(r * 0.02, -r * 0.15)]), c)
		"power":
			for k in 3:
				var p := o + Vector2((k - 1) * r * 0.55, -r * 0.05 + absf(k - 1) * r * 0.18)
				ci.draw_circle(p + Vector2(0, -r * 0.4), r * 0.2, c)
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.25, r * 0.6), p + Vector2(-r * 0.22, -r * 0.05), p + Vector2(r * 0.22, -r * 0.05), p + Vector2(r * 0.25, r * 0.6)]), c if k == 1 else c.darkened(0.2))
		# --- buffs ---
		"firerate":
			for k in 2:
				var x := (k - 0.5) * r * 0.7
				ci.draw_polyline(PackedVector2Array([o + Vector2(x - r * 0.3, -r * 0.6), o + Vector2(x + r * 0.3, 0), o + Vector2(x - r * 0.3, r * 0.6)]), c, w * 1.6, true)
		"speed":
			for k in 3:
				var y := (k - 1) * r * 0.5
				ci.draw_line(o + Vector2(-r * 0.9 + absf(k - 1) * r * 0.3, y), o + Vector2(r * 0.2, y), Color(c, 0.6 + 0.2 * (1 - absf(k - 1))), w, true)
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(r * 0.9, 0), o + Vector2(r * 0.25, -r * 0.5), o + Vector2(r * 0.25, r * 0.5)]), c)
		"damage":
			var star := PackedVector2Array()
			for k in 10:
				var a := k * TAU / 10.0 - PI * 0.5
				star.append(o + Vector2(cos(a), sin(a)) * r * (0.95 if k % 2 == 0 else 0.42))
			ci.draw_colored_polygon(star, c)
		"heal", "heart":
			ci.draw_circle(o + Vector2(-r * 0.36, -r * 0.2), r * 0.42, c)
			ci.draw_circle(o + Vector2(r * 0.36, -r * 0.2), r * 0.42, c)
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.76, -r * 0.05), o + Vector2(r * 0.76, -r * 0.05), o + Vector2(0, r * 0.85)]), c)
		# --- HUD glyphs ---
		"skull":
			ci.draw_circle(o + Vector2(0, -r * 0.12), r * 0.7, c)
			ci.draw_rect(Rect2(o + Vector2(-r * 0.4, r * 0.3), Vector2(r * 0.8, r * 0.5)), c)
			ci.draw_circle(o + Vector2(-r * 0.27, -r * 0.1), r * 0.2, dark.darkened(1.0))
			ci.draw_circle(o + Vector2(r * 0.27, -r * 0.1), r * 0.2, dark.darkened(1.0))
		"crown":
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.85, r * 0.6), o + Vector2(-r * 0.85, -r * 0.45), o + Vector2(-r * 0.4, 0), o + Vector2(0, -r * 0.7), o + Vector2(r * 0.4, 0), o + Vector2(r * 0.85, -r * 0.45), o + Vector2(r * 0.85, r * 0.6)]), c)
		"clock":
			ci.draw_arc(o, r * 0.8, 0, TAU, 28, c, w, true)
			ci.draw_line(o, o + Vector2(0, -r * 0.5), c, w, true)
			ci.draw_line(o, o + Vector2(r * 0.38, 0), c, w, true)
		"recycle":
			for k in 3:
				var a := k * TAU / 3.0 - PI * 0.5
				ci.draw_arc(o, r * 0.68, a + 0.35, a + 1.75, 10, c, w * 1.4, true)
				var e := a + 1.85
				var tip := o + Vector2(cos(e), sin(e)) * r * 0.68
				var tan := Vector2(-sin(e), cos(e))
				var nrm := Vector2(cos(e), sin(e))
				ci.draw_colored_polygon(PackedVector2Array([tip + tan * r * 0.3, tip + nrm * r * 0.25, tip - nrm * r * 0.25]), c)
		"star":
			draw_icon(ci, "damage", o, r, c)
		_:
			# materials and fallbacks: a faceted gem
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -r * 0.9), o + Vector2(r * 0.75, -r * 0.1), o + Vector2(0, r * 0.9), o + Vector2(-r * 0.75, -r * 0.1)]), c)
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -r * 0.9), o + Vector2(r * 0.75, -r * 0.1), o + Vector2(0, -r * 0.1)]), c.lightened(0.35))
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.75, -r * 0.1), o + Vector2(0, r * 0.9), o + Vector2(0, -r * 0.1)]), c.darkened(0.25))


static func _leaf(ci: CanvasItem, o: Vector2, r: float, a: float, c: Color) -> void:
	var d := Vector2(cos(a), sin(a))
	var n := d.orthogonal()
	var pts := PackedVector2Array()
	for k in 9:
		var t := k / 8.0
		pts.append(o + d * r * (t * 2.0 - 1.0) + n * sin(t * PI) * r * 0.55)
	for k in range(7, 0, -1):
		var t := k / 8.0
		pts.append(o + d * r * (t * 2.0 - 1.0) - n * sin(t * PI) * r * 0.55)
	ci.draw_colored_polygon(pts, c)
	ci.draw_line(o - d * r, o + d * r, c.darkened(0.35), maxf(1.0, r * 0.12), true)


static func _rrect(ci: CanvasItem, rect: Rect2, rad: float, c: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(int(rad))
	ci.draw_style_box(s, rect)
