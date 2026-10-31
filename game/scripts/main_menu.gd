extends Control
## Title screen: live 3D backdrop, left menu column, right info cards.

const UI = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scripts/menu_backdrop.gd")

const INK := UI.INK
const MINT := UI.MINT
const SUN := UI.SUN
const MUTED := UI.MUTED
const FACT_TIME := 8.0
const PERKS := {"plastic": "perk_firerate", "paper": "perk_speed", "glass": "perk_damage", "organic": "perk_heal"}

var _ui: Control
var _fade: ColorRect
var _how_open := false
var _shop_open := false
var _leaving := false
var _t := 0.0
var _fact_idx := 0
var _fact_t := 0.0
var _fact_label: Label
var _fact_bar: ColorRect


func _ready() -> void:
	get_tree().paused = false
	add_child(Backdrop.new())
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.8)
	_fact_idx = randi() % GameData.FACTS.size()
	Loc.language_changed.connect(_build.bind(false))
	Meta.changed.connect(_build.bind(false))
	_build(true)


func _process(delta: float) -> void:
	_t += delta
	_fact_t += delta
	if _fact_bar:
		_fact_bar.anchor_right = clampf(_fact_t / FACT_TIME, 0.0, 1.0)
	if _fact_t >= FACT_TIME:
		_next_fact()
	_maybe_screenshot()


func _unhandled_input(ev: InputEvent) -> void:
	if (_how_open or _shop_open) and (ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel")):
		_how_open = false
		_set_shop(false)
		get_viewport().set_input_as_handled()


# --- layout --------------------------------------------------------------------

func _build(intro := false) -> void:
	for c in _ui.get_children():
		c.queue_free()
	_fact_bar = null
	_ui.add_child(_side_shade())

	var left := _left_column()
	_ui.add_child(left)
	var right := _right_column()
	_ui.add_child(right)
	_ui.add_child(_lang_switch())

	if _how_open:
		_ui.add_child(_how_modal())
	if _shop_open:
		_ui.add_child(_shop_modal())
	if intro:
		_slide_in(left, -60.0, 0.15)
		_slide_in(right, 60.0, 0.45)


func _side_shade() -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(INK, 0.94), Color(INK, 0.72), Color(INK, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	gt.width = 256
	gt.height = 4
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.anchor_right = 0.62
	tr.anchor_bottom = 1.0
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _left_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.anchor_bottom = 1.0
	col.offset_left = 72
	col.offset_right = 72 + 560
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)

	# eyebrow: four bin-colored dots
	var eyebrow := HBoxContainer.new()
	eyebrow.add_theme_constant_override("separation", 6)
	for t in GameData.BIN_TYPES:
		eyebrow.add_child(UI.chip(GameData.MATERIALS[t].color, Vector2(10, 10), 5))
	col.add_child(eyebrow)

	var t1 := UI.label(Loc.t("title_1"), 92, MINT, 0)
	t1.add_theme_font_override("font", UI.font(0.9, 1))
	UI.shadow(t1, 6)
	col.add_child(t1)
	var t2 := UI.label(Loc.t("title_2"), 60, SUN, 0)
	t2.add_theme_font_override("font", UI.font(0.8, 9))
	UI.shadow(t2, 5)
	col.add_child(t2)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	for t in GameData.BIN_TYPES:
		bar.add_child(UI.chip(GameData.MATERIALS[t].color, Vector2(64, 6), 3))
	col.add_child(_spaced(bar, 10))

	var tag := UI.wrap_label(Loc.t("tagline"), 20, Color(0.88, 0.95, 0.95), 470)
	col.add_child(_spaced(tag, 12))
	col.add_child(UI.gap(22))

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	var play := UI.menu_button(Loc.t("play"), true)
	play.pressed.connect(_start_game)
	buttons.add_child(play)
	var shop := UI.menu_button(Loc.t("upgrades"))
	shop.pressed.connect(_set_shop.bind(true))
	var pts := UI.pill("%d" % Meta.points, MINT, 15)
	pts.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	pts.offset_left = -96
	pts.offset_right = -16
	pts.offset_top = -13
	pts.offset_bottom = 13
	pts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	shop.add_child(pts)
	buttons.add_child(shop)
	var how := UI.menu_button(Loc.t("how_to"))
	how.pressed.connect(_set_how.bind(true))
	buttons.add_child(how)
	if not OS.has_feature("web"):
		var quit := UI.menu_button(Loc.t("quit"))
		quit.pressed.connect(func(): get_tree().quit())
		buttons.add_child(quit)
	col.add_child(buttons)
	col.add_child(_spaced(UI.label(Loc.t("enter_hint"), 14, Color(1, 1, 1, 0.45), 0), 10))

	# gentle "breathing" on the primary button
	var pulse := play.create_tween().set_loops()
	pulse.tween_property(play, "modulate", Color(1.12, 1.12, 1.12), 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(play, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)
	if not _how_open and not _shop_open:
		play.grab_focus.call_deferred()
	return col


func _right_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.anchor_left = 1.0
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = -440
	col.offset_right = -48
	col.offset_bottom = -56
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 16)

	# bin legend
	var sort := UI.card(Color(1, 1, 1, 0.12))
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	sort.add_child(sv)
	var st := UI.label(Loc.t("sort_title"), 15, SUN, 0)
	st.add_theme_font_override("font", UI.font(0.3, 3))
	sv.add_child(st)
	for t in GameData.BIN_TYPES:
		var c: Color = GameData.MATERIALS[t].color
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(UI.chip(c, Vector2(26, 26), 7))
		var mat_name := UI.label(Loc.pick(GameData.MATERIALS[t].name), 19, Color.WHITE, 0)
		mat_name.add_theme_font_override("font", UI.font(0.5))
		mat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(mat_name)
		row.add_child(UI.pill(Loc.t(PERKS[t]), c))
		sv.add_child(row)
	col.add_child(sort)

	# rotating fact card
	var fact := UI.card(Color(SUN, 0.8))
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 8)
	fact.add_child(fv)
	var ft := UI.label(Loc.upper(Loc.t("did_you_know")), 15, SUN, 0)
	ft.add_theme_font_override("font", UI.font(0.3, 3))
	fv.add_child(ft)
	_fact_label = UI.wrap_label(Loc.pick(GameData.FACTS[_fact_idx]), 17, Color(0.9, 0.96, 0.96), 340)
	_fact_label.custom_minimum_size.y = 72
	fv.add_child(_fact_label)
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.1)
	track.custom_minimum_size = Vector2(0, 3)
	_fact_bar = ColorRect.new()
	_fact_bar.color = Color(SUN, 0.8)
	_fact_bar.anchor_bottom = 1.0
	track.add_child(_fact_bar)
	fv.add_child(track)
	col.add_child(fact)
	return col


func _lang_switch() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.anchor_left = 1.0
	h.anchor_right = 1.0
	h.offset_left = -170
	h.offset_right = -48
	h.offset_top = 32
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_theme_constant_override("separation", 0)
	for code in ["tr", "en"]:
		var active: bool = Loc.lang == code
		var b := Button.new()
		b.text = code.to_upper()
		b.custom_minimum_size = Vector2(58, 38)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_font_override("font", UI.font(0.4, 2))
		b.add_theme_color_override("font_color", INK if active else Color.WHITE)
		b.add_theme_color_override("font_hover_color", INK if active else SUN)
		var left: bool = code == "tr"
		for state in ["normal", "hover", "pressed", "focus"]:
			var s := StyleBoxFlat.new()
			s.bg_color = MINT if active else Color(INK, 0.7)
			s.border_color = Color(1, 1, 1, 0.25) if state != "focus" else SUN
			s.set_border_width_all(2)
			s.draw_center = state != "focus"
			s.corner_radius_top_left = 19 if left else 0
			s.corner_radius_bottom_left = 19 if left else 0
			s.corner_radius_top_right = 0 if left else 19
			s.corner_radius_bottom_right = 0 if left else 19
			b.add_theme_stylebox_override(state, s)
		if not active:
			b.pressed.connect(func():
				Sfx.play("click", -6)
				Loc.toggle())
		h.add_child(b)
	return h


func _how_modal() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(UI.dim(0.6))
	var center := UI.centered()
	root.add_child(center)
	var panel := UI.card(Color(MINT, 0.35), 22)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	panel.add_child(vb)
	var title := UI.label(Loc.t("how_to"), 38, SUN, 0)
	title.add_theme_font_override("font", UI.font(0.8, 4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	vb.add_child(grid)
	var accents := [MINT, Color(0.45, 0.85, 1.0), SUN, Color(1.0, 0.5, 0.45)]
	for i in 4:
		grid.add_child(_step_card(i + 1, Loc.t("how_s%d_t" % (i + 1)), Loc.t("how_s%d" % (i + 1)), accents[i], i == 2))
	var keys := UI.label(Loc.t("how_keys"), 15, MUTED, 0)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(keys)
	var back := UI.menu_button(Loc.t("back"), true)
	back.custom_minimum_size = Vector2(260, 54)
	back.alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.pressed.connect(_set_how.bind(false))
	var bw := CenterContainer.new()
	bw.add_child(back)
	vb.add_child(bw)
	back.grab_focus.call_deferred()
	root.modulate.a = 0.0
	root.create_tween().tween_property(root, "modulate:a", 1.0, 0.2)
	return root


func _step_card(n: int, title: String, text: String, accent: Color, show_bins: bool) -> PanelContainer:
	var p := UI.card(Color(accent, 0.5), 16, Color(1, 1, 1, 0.04))
	p.custom_minimum_size = Vector2(420, 150)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	p.add_child(h)
	var badge := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = accent
	bs.set_corner_radius_all(24)
	badge.add_theme_stylebox_override("panel", bs)
	badge.custom_minimum_size = Vector2(48, 48)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var num := UI.label(str(n), 24, INK, 0)
	num.add_theme_font_override("font", UI.font(0.8))
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(num)
	h.add_child(badge)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	h.add_child(v)
	var t := UI.label(title, 20, accent, 0)
	t.add_theme_font_override("font", UI.font(0.6, 2))
	v.add_child(t)
	v.add_child(UI.wrap_label(text, 16, Color(0.9, 0.95, 0.95), 320))
	if show_bins:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		for m in GameData.BIN_TYPES:
			row.add_child(UI.pill(Loc.pick(GameData.MATERIALS[m].name), GameData.MATERIALS[m].color, 13))
		v.add_child(row)
	return p


func _shop_modal() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(UI.dim(0.65))
	var center := UI.centered()
	root.add_child(center)
	var panel := UI.card(Color(MINT, 0.35), 22, Color(INK, 0.9), Vector4(26, 18, 26, 18))
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	vb.add_child(head)
	var title := UI.label(Loc.t("upgrades"), 34, SUN, 0)
	title.add_theme_font_override("font", UI.font(0.8, 4))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UI.Icons.make("recycle", MINT, 26))
	var pts := UI.label("%d" % Meta.points, 28, MINT, 0)
	pts.add_theme_font_override("font", UI.font(0.8, 1))
	head.add_child(pts)
	var cap := UI.label(Loc.t("points"), 14, MUTED, 0)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(cap)
	vb.add_child(UI.wrap_label(Loc.t("shop_hint"), 15, MUTED, 820))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	vb.add_child(grid)
	var first: Button = null
	for id in GameData.META:
		var b := _shop_item(id, grid)
		if first == null and b != null:
			first = b
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(foot)
	var back := UI.menu_button(Loc.t("back"), true, 240)
	back.alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.pressed.connect(_set_shop.bind(false))
	foot.add_child(back)
	var refund := UI.menu_button(Loc.t("refund"), false, 180)
	refund.alignment = HORIZONTAL_ALIGNMENT_CENTER
	refund.pressed.connect(Meta.refund_all)
	foot.add_child(refund)
	(first if first != null else back).grab_focus.call_deferred()
	return root


## One upgrade row; returns its buy button (null when maxed).
func _shop_item(id: String, grid: GridContainer) -> Button:
	var d: Dictionary = GameData.META[id]
	var lv := Meta.lv(id)
	var maxed: bool = lv >= d.max
	var card := UI.card(Color(d.color, 0.6), 14, Color(1, 1, 1, 0.04), Vector4(12, 8, 12, 8))
	card.custom_minimum_size.x = 410
	grid.add_child(card)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	h.add_child(UI.icon_tile(d.icon, d.color, 46))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nl := UI.label(Loc.pick(d.name), 17, Color.WHITE, 0)
	nl.add_theme_font_override("font", UI.font(0.5, 0))
	v.add_child(nl)
	v.add_child(UI.label(Loc.pick(d.desc), 13, MUTED, 0))
	v.add_child(UI.pips(lv, d.color, d.max, Vector2(16, 5)))
	if maxed:
		h.add_child(UI.pill(Loc.t("maxed"), SUN, 14))
		return null
	var cost := Meta.cost(id)
	var b := Button.new()
	b.text = "%s  %d" % [Loc.t("buy"), cost]
	b.custom_minimum_size = Vector2(104, 40)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_font_override("font", UI.font(0.5, 1))
	var ok := Meta.points >= cost
	var bg := Color(0.11, 0.55, 0.32, 0.96) if ok else Color(1, 1, 1, 0.06)
	b.add_theme_stylebox_override("normal", UI.style(bg, 10))
	b.add_theme_stylebox_override("hover", UI.style(bg.lightened(0.12), 10, SUN, 2))
	b.add_theme_stylebox_override("pressed", UI.style(bg.darkened(0.15), 10, SUN, 2))
	b.add_theme_stylebox_override("focus", UI.style(Color(0, 0, 0, 0), 10, SUN, 2))
	b.add_theme_stylebox_override("disabled", UI.style(bg, 10))
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	b.disabled = not ok
	b.pressed.connect(func():
		if Meta.buy(id):
			Sfx.play("levelup", -6))
	h.add_child(b)
	return b if ok else null


# --- widgets -------------------------------------------------------------------

## Wraps a control with extra space above it.
func _spaced(c: Control, top: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", top)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(c)
	return m


# --- behaviour -----------------------------------------------------------------

func _slide_in(c: Control, from_x: float, delay: float) -> void:
	c.modulate.a = 0.0
	var target := c.position.x
	c.position.x += from_x
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "modulate:a", 1.0, 0.5).set_delay(delay)
	tw.tween_property(c, "position:x", target, 0.6).set_delay(delay).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _next_fact() -> void:
	_fact_t = 0.0
	_fact_idx = (_fact_idx + 1 + randi() % 3) % GameData.FACTS.size()
	if _fact_label == null:
		return
	var l := _fact_label
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): l.text = Loc.pick(GameData.FACTS[_fact_idx]))
	tw.tween_property(l, "modulate:a", 1.0, 0.35)


func _set_how(open: bool) -> void:
	_how_open = open
	_build()


func _set_shop(open: bool) -> void:
	_shop_open = open
	_build()


func _start_game() -> void:
	if _leaving:
		return
	_leaving = true
	Sfx.play("select")
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.35)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/game.tscn"))


## Test hook: `-- --shots=<dir>` saves the menu and the how-to modal, then quits.
func _maybe_screenshot() -> void:
	var dir := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			dir = a.substr(8)
	if dir == "":
		return
	var prev := _t - get_process_delta_time()
	if _t >= 2.0 and prev < 2.0:
		get_viewport().get_texture().get_image().save_png(dir.path_join("menu.png"))
		_set_how(true)
	elif _t >= 2.6 and prev < 2.6:
		get_viewport().get_texture().get_image().save_png(dir.path_join("menu_how.png"))
		_how_open = false
		_set_shop(true)
	elif _t >= 3.2 and prev < 3.2:
		get_viewport().get_texture().get_image().save_png(dir.path_join("menu_shop.png"))
		get_tree().quit()
