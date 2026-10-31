extends Control
## Rounded progress bar drawn in code: smooth fill, trailing "ghost" fill after
## drops, top shine, optional segment ticks and markers.

var value := 1.0          # 0..1 target
var fill_color := Color.WHITE
var ghost_color := Color(1, 1, 1, 0.55)
var bg_color := Color(0, 0, 0, 0.55)
var border_color := Color(1, 1, 1, 0.12)
var segments := 0         # tick marks dividing the bar
var markers: Array = []   # [{"at": 0..1, "color": Color}]
var flash := 0.0          # brightens the fill briefly (set > 0 to trigger)
var smooth := 14.0

var _shown := 1.0
var _ghost := 1.0
var _ghost_hold := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func snap(v: float) -> void:
	value = v
	_shown = v
	_ghost = v


func _process(delta: float) -> void:
	var v := clampf(value, 0.0, 1.0)
	var old_shown := _shown
	_shown = lerpf(_shown, v, minf(1.0, smooth * delta))
	if absf(_shown - v) < 0.001:
		_shown = v
	if v < _ghost:
		if v < old_shown - 0.0005:
			_ghost_hold = 0.45
		_ghost_hold -= delta
		if _ghost_hold <= 0.0:
			_ghost = maxf(v, _ghost - delta * 0.9)
	else:
		_ghost = _shown
	flash = maxf(0.0, flash - delta * 3.0)
	queue_redraw()


func _draw() -> void:
	var r := size.y * 0.5
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(_box(bg_color, r, border_color), rect)
	var inner := rect.grow(-2.0)
	var ir := maxf(1.0, inner.size.y * 0.5)
	if _ghost > _shown + 0.002:
		draw_style_box(_box(ghost_color, ir), Rect2(inner.position, Vector2(maxf(inner.size.y, inner.size.x * _ghost), inner.size.y)))
	if _shown > 0.003:
		var w := maxf(inner.size.y, inner.size.x * _shown)
		var fc := fill_color.lerp(Color.WHITE, flash * 0.6)
		draw_style_box(_box(fc, ir), Rect2(inner.position, Vector2(w, inner.size.y)))
		draw_style_box(_box(Color(1, 1, 1, 0.22), ir * 0.5), Rect2(inner.position + Vector2(ir * 0.5, 1), Vector2(maxf(0.0, w - ir), inner.size.y * 0.32)))
	for i in range(1, segments):
		var x := inner.position.x + inner.size.x * float(i) / segments
		draw_line(Vector2(x, inner.position.y + 1), Vector2(x, inner.end.y - 1), Color(0, 0, 0, 0.35), 1.0)
	for m in markers:
		var x: float = inner.position.x + inner.size.x * m.at
		draw_line(Vector2(x, -3), Vector2(x, size.y + 3), m.color, 2.0)


static func _box(c: Color, r: float, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(int(r))
	s.anti_aliasing = true
	if border.a > 0.0:
		s.border_color = border
		s.set_border_width_all(1)
	return s
