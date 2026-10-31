extends RefCounted
## Small helpers for building styled UI from code.

const GREEN := Color(0.16, 0.6, 0.36)
const DARK := Color(0.05, 0.16, 0.16, 0.92)


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
	b.pressed.connect(func(): Sfx.play("click", -6))
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
