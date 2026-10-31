extends CanvasLayer
## Victory / defeat screen with recycling stats and a closing fact.

const UI = preload("res://scripts/ui/ui_kit.gd")
const Bar = preload("res://scripts/ui/bar.gd")


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_result(win: bool, stats: Dictionary, earned := 0) -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	var accent := Color(0.5, 1.0, 0.6) if win else Color(1.0, 0.5, 0.4)
	add_child(UI.dim(0.55))
	add_child(UI.vignette(Color(0.0, 0.03, 0.04, 0.95), 0.3))
	var center := UI.centered()
	add_child(center)
	var vb := UI.vbox(14)
	center.add_child(vb)
	var parts: Array[Control] = []

	var title := UI.label(Loc.t("victory") if win else Loc.t("defeat"), 64, accent, 0)
	title.add_theme_font_override("font", UI.font(0.9, 3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.shadow(title, 6)
	vb.add_child(title)
	var sub := UI.wrap_label(Loc.t("win_text") if win else Loc.t("lose_text"), 19, Color(0.9, 0.95, 0.95), 640)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	parts.append(sub)

	var total_sorted := 0
	var total_collected := 0
	for t in GameData.BIN_TYPES:
		total_sorted += int(stats.recycled[t])
		total_collected += int(stats.collected[t])
	var pct := int(100.0 * total_sorted / maxf(1.0, total_collected))

	# stat tiles
	var tiles := UI.hbox(12)
	vb.add_child(tiles)
	parts.append(tiles)
	var tile_data := [
		["clock", Loc.t("time"), UI.fmt_time(stats.time), UI.SUN],
		["star", Loc.t("level"), str(stats.level), Color(0.35, 0.85, 1.0)],
		["recycle", Loc.t("kills"), str(stats.kills), UI.MINT],
		["gem", Loc.t("recycled"), "%d%%" % pct, Color(0.6, 1, 0.6)],
	]
	for s in tile_data:
		tiles.add_child(_tile(s[0], s[1], s[2], s[3]))

	# recycling points earned for the upgrade shop
	var pts := UI.card(Color(UI.MINT, 0.9), 14, Color(0.04, 0.2, 0.12, 0.9), Vector4(18, 8, 18, 8))
	pts.custom_minimum_size.x = 640
	vb.add_child(pts)
	parts.append(pts)
	var ph := UI.hbox(10)
	ph.alignment = BoxContainer.ALIGNMENT_BEGIN
	pts.add_child(ph)
	ph.add_child(UI.Icons.make("recycle", UI.MINT, 26))
	var pl := UI.label("+%d  %s" % [earned, Loc.t("points")], 22, UI.MINT, 0)
	pl.add_theme_font_override("font", UI.font(0.7, 1))
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ph.add_child(pl)
	ph.add_child(_caption("%s: %d" % [Loc.t("total_points"), Meta.points], UI.MUTED))

	# per-material sorting breakdown
	var card := UI.card(Color(1, 1, 1, 0.14), 16, Color(UI.INK, 0.85))
	card.custom_minimum_size.x = 640
	vb.add_child(card)
	parts.append(card)
	var cv := UI.vbox(8)
	card.add_child(cv)
	var head := UI.hbox(8)
	head.alignment = BoxContainer.ALIGNMENT_BEGIN
	head.add_child(_caption(Loc.t("recycled"), UI.SUN))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	head.add_child(_caption("%s: %d  •  %s: %d" % [Loc.t("collected"), total_collected, Loc.t("ewaste_collected"), stats.collected.ewaste], UI.MUTED))
	cv.add_child(head)
	var most := 1
	for t in GameData.BIN_TYPES:
		most = maxi(most, int(stats.recycled[t]))
	for t in GameData.BIN_TYPES:
		var c: Color = GameData.MATERIALS[t].color
		var row := UI.hbox(10)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_child(UI.Icons.make("gem", c, 18))
		var nl := UI.label(Loc.pick(GameData.MATERIALS[t].name), 16, Color.WHITE, 0)
		nl.custom_minimum_size.x = 80
		row.add_child(nl)
		var bar := Bar.new()
		bar.custom_minimum_size = Vector2(440, 12)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.fill_color = c
		bar.smooth = 3.0
		bar.snap(0.0)
		bar.value = float(stats.recycled[t]) / most
		row.add_child(bar)
		var n := UI.label(str(stats.recycled[t]), 16, c.lightened(0.3), 0)
		n.add_theme_font_override("font", UI.font(0.5, 0))
		row.add_child(n)
		cv.add_child(row)

	var fc := UI.card(Color(UI.SUN, 0.8), 14, Color(UI.INK, 0.85))
	fc.custom_minimum_size.x = 640
	var fv := UI.vbox(4)
	fv.alignment = BoxContainer.ALIGNMENT_BEGIN
	fc.add_child(fv)
	fv.add_child(_caption(Loc.t("did_you_know"), UI.SUN))
	fv.add_child(UI.wrap_label(GameData.random_fact(), 16, Color(0.85, 0.9, 0.9), 590))
	vb.add_child(fc)
	parts.append(fc)

	var btns := UI.hbox(16)
	vb.add_child(btns)
	parts.append(btns)
	var retry := UI.menu_button(Loc.t("retry"), true, 300)
	retry.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	btns.add_child(retry)
	var menu := UI.menu_button(Loc.t("main_menu"), false, 300)
	menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	btns.add_child(menu)
	retry.grab_focus.call_deferred()
	_animate_in.call_deferred(title, parts)


func _animate_in(title: Label, parts: Array[Control]) -> void:
	title.pivot_offset = title.size * 0.5
	title.scale = Vector2(1.5, 1.5)
	title.modulate.a = 0.0
	var tw := title.create_tween().set_parallel()
	tw.tween_property(title, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(title, "modulate:a", 1.0, 0.3)
	for i in parts.size():
		UI.pop_in(parts[i], 0.25 + i * 0.1, Vector2(0, 26), 0.4)


func _tile(icon: String, cap: String, value: String, c: Color) -> Control:
	var p := UI.card(Color(c, 0.8), 14, Color(UI.INK, 0.85), Vector4(14, 10, 14, 12))
	p.custom_minimum_size.x = 151
	var v := UI.vbox(4)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	p.add_child(v)
	var h := UI.hbox(6)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	h.add_child(UI.Icons.make(icon, c, 16))
	h.add_child(_caption(cap, UI.MUTED))
	v.add_child(h)
	var l := UI.label(value, 30, Color.WHITE, 0)
	l.add_theme_font_override("font", UI.font(0.7, 1))
	v.add_child(l)
	return p


func _caption(text: String, c: Color) -> Label:
	var l := UI.label(Loc.upper(text), 11, c, 0)
	l.add_theme_font_override("font", UI.font(0.4, 1))
	return l
