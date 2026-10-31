extends RefCounted
## Small helpers for building styled UI from code.

const Icons = preload("res://scripts/ui/icons.gd")

const GREEN := Color(0.16, 0.6, 0.36)
const DARK := Color(0.05, 0.16, 0.16, 0.92)
const INK := Color(0.02, 0.09, 0.11)
const MINT := Color(0.62, 1.0, 0.7)
const SUN := Color(1.0, 0.84, 0.3)
const MUTED := Color(0.7, 0.8, 0.8)


static func label(text: String, size := 20, color := Color.WHITE, outline := 6) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrap_label(text: String, size: int, color: Color, width: float) -> Label:
	var l := label(text, size, color, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width
	return l


static func style(color: Color, radius := 14, border_color := Color(0, 0, 0, 0), border := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border > 0:
		s.border_color = border_color
		s.set_border_width_all(border)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func button(text: String, size := 26, color := GREEN, min_size := Vector2(340, 58)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	b.add_theme_stylebox_override("normal", style(color, 14, color.darkened(0.35), 3))
	b.add_theme_stylebox_override("hover", style(color.lightened(0.18), 14, Color(1, 1, 1, 0.9), 3))
	b.add_theme_stylebox_override("pressed", style(color.darkened(0.2), 14, Color(1, 1, 1, 0.9), 3))
	b.add_theme_stylebox_override("focus", style(Color(0, 0, 0, 0), 14, Color(1, 0.9, 0.4), 3))
	b.pressed.connect(func(): Sfx.play("click"))
	return b


static func panel(color := DARK, radius := 18) -> PanelContainer:
	var p := PanelContainer.new()
	var s := style(color, radius, Color(1, 1, 1, 0.12), 2)
	s.content_margin_left = 32
	s.content_margin_right = 32
	s.content_margin_top = 24
	s.content_margin_bottom = 24
	p.add_theme_stylebox_override("panel", s)
	return p


static func dim(alpha := 0.6) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0, 0, 0, alpha)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


static func centered() -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


static func vbox(sep := 14) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	return v


static func hbox(sep := 14) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	return h


## Bolder / letter-spaced variant of the default font (works on web too).
static func font(embolden := 0.0, spacing := 0) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = ThemeDB.fallback_font
	f.variation_embolden = embolden
	f.spacing_glyph = spacing
	return f


static func fmt_time(t: float) -> String:
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]


## Dark card with a colored left accent stripe (menus, HUD panels, toasts).
static func card(border: Color, radius := 16, bg := Color(INK, 0.82), pad := Vector4(22, 18, 22, 18)) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(1)
	s.border_width_left = 4
	s.content_margin_left = pad.x
	s.content_margin_top = pad.y
	s.content_margin_right = pad.z
	s.content_margin_bottom = pad.w
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func chip(c: Color, size: Vector2, radius: int) -> Panel:
	var p := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = size
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func pill(text: String, c: Color, font_size := 15) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(c, 0.18)
	s.border_color = Color(c, 0.7)
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", s)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(label(text, font_size, c.lightened(0.35), 0))
	return p


## Rounded square holding a vector icon, tinted by `c`.
static func icon_tile(icon_id: String, c: Color, px := 44.0, dim_tile := false) -> Panel:
	var p := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(c.darkened(0.55), 0.85) if not dim_tile else Color(1, 1, 1, 0.05)
	s.border_color = Color(c, 0.85) if not dim_tile else Color(1, 1, 1, 0.12)
	s.set_border_width_all(2)
	s.set_corner_radius_all(int(px * 0.24))
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = Vector2(px, px)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon_id != "":
		var ic := Icons.make(icon_id, c.lightened(0.15), px * 0.62)
		ic.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		ic.offset_left = -px * 0.31
		ic.offset_top = -px * 0.31
		ic.offset_right = px * 0.31
		ic.offset_bottom = px * 0.31
		p.add_child(ic)
	return p


## Row of small level pips (filled up to `level`).
static func pips(level: int, c: Color, count := 5, pip := Vector2(14, 5)) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in count:
		h.add_child(chip(c if i < level else Color(1, 1, 1, 0.15), pip, 2))
	return h


static func shadow(l: Label, offset: int) -> void:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", offset)


static func gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Radial vignette texture (transparent center -> `edge` at the corners).
static func vignette(edge: Color, mid := 0.55) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, mid, 1.0])
	g.colors = PackedColorArray([Color(edge, 0.0), Color(edge, edge.a * 0.08), edge])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## Fades + slides a control in from `from` offset after `delay` seconds.
static func pop_in(c: Control, delay := 0.0, from := Vector2(0, 24), time := 0.45) -> void:
	c.modulate.a = 0.0
	# containers lay children out late; wait until positions are final
	var tree := c.get_tree()
	await tree.process_frame
	await tree.process_frame
	if not is_instance_valid(c):
		return
	var target := c.position
	c.position += from
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "modulate:a", 1.0, time * 0.8).set_delay(delay)
	tw.tween_property(c, "position", target, time).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Big left-aligned menu button with accent stripe and hover pop.
static func menu_button(text: String, primary := false, width := 380.0, bg_override := Color(0, 0, 0, 0)) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(width, 66 if primary else 54)
	b.add_theme_font_size_override("font_size", 28 if primary else 21)
	b.add_theme_font_override("font", font(0.7 if primary else 0.35, 3 if primary else 2))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	var bg := Color(0.11, 0.55, 0.32, 0.96) if primary else Color(INK, 0.72)
	if bg_override.a > 0.0:
		bg = bg_override
	var accent := MINT if primary else Color(1, 1, 1, 0.3)
	b.add_theme_stylebox_override("normal", _btn_style(bg, accent, 6))
	b.add_theme_stylebox_override("hover", _btn_style(bg.lightened(0.12), SUN, 12))
	b.add_theme_stylebox_override("pressed", _btn_style(bg.darkened(0.15), SUN, 12))
	var focus := _btn_style(Color(0, 0, 0, 0), SUN, 12)
	focus.draw_center = false
	b.add_theme_stylebox_override("focus", focus)
	b.pressed.connect(func(): Sfx.play("click"))
	b.mouse_entered.connect(func(): _hover(b, true))
	b.mouse_exited.connect(func(): _hover(b, false))
	b.focus_entered.connect(func(): _hover(b, true))
	b.focus_exited.connect(func(): _hover(b, false))
	return b


static func _btn_style(bg: Color, accent: Color, accent_w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(12)
	s.border_color = accent
	s.border_width_left = accent_w
	s.content_margin_left = 22 + accent_w
	s.content_margin_right = 22
	return s


static func _hover(b: Button, on: bool) -> void:
	if on:
		Sfx.play("click", -8)
	b.pivot_offset = Vector2(0, b.size.y * 0.5)
	b.create_tween().tween_property(b, "scale", Vector2.ONE * (1.04 if on else 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Labeled volume slider bound to an audio bus ("Music" / "SFX").
static func volume_row(text: String, bus: String, width := 300.0) -> HBoxContainer:
	var h := hbox(12)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	var l := label(text, 15, MUTED, 0)
	l.add_theme_font_override("font", font(0.4, 1))
	l.custom_minimum_size.x = 86
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = Meta.volume.get(bus, 0.8)
	s.custom_minimum_size = Vector2(width - 140, 24)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.14)
	track.set_corner_radius_all(4)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = MINT
	fill.set_corner_radius_all(4)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	h.add_child(s)
	var pct := label("%d%%" % int(round(s.value * 100)), 14, Color.WHITE, 0)
	pct.custom_minimum_size.x = 44
	h.add_child(pct)
	s.value_changed.connect(func(v: float):
		Meta.set_volume(bus, v)
		pct.text = "%d%%" % int(round(v * 100)))
	if bus == "SFX":
		s.drag_ended.connect(func(_changed: bool): Sfx.play("select"))
	return h
