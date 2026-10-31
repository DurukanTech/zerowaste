extends CanvasLayer
## Esc pause menu with current build overview and language switch.

const UI = preload("res://scripts/ui/ui_kit.gd")

var game
var _open := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	Loc.language_changed.connect(func():
		if _open:
			_build())


func _unhandled_input(ev: InputEvent) -> void:
	if not ev.is_action_pressed("pause"):
		return
	if _open:
		_close()
	elif not game.finished and not game.level_ui.is_open():
		_open_menu()
	get_viewport().set_input_as_handled()


func _open_menu() -> void:
	_open = true
	get_tree().paused = true
	_build()
	visible = true


func _close() -> void:
	_open = false
	visible = false
	get_tree().paused = false


func _build() -> void:
	for c in get_children():
		c.queue_free()
	add_child(UI.dim(0.5))
	add_child(UI.vignette(Color(0.0, 0.03, 0.04, 0.9), 0.35))
	var center := UI.centered()
	add_child(center)
	var row := UI.hbox(26)
	center.add_child(row)

	# left: title, run stats, actions
	var left := UI.vbox(12)
	left.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_child(left)
	var title := UI.label(Loc.t("paused"), 50, UI.SUN, 0)
	title.add_theme_font_override("font", UI.font(0.9, 3))
	UI.shadow(title, 5)
	left.add_child(title)
	left.add_child(UI.chip(UI.MINT, Vector2(72, 4), 2))
	left.add_child(_stats())
	left.add_child(UI.gap(8))
	var resume := UI.menu_button(Loc.t("resume"), true, 360)
	resume.pressed.connect(_close)
	left.add_child(resume)
	var lang := UI.menu_button(Loc.t("language"), false, 360)
	lang.pressed.connect(Loc.toggle)
	left.add_child(lang)
	var menu := UI.menu_button(Loc.t("main_menu"), false, 360, Color(0.32, 0.12, 0.1, 0.85))
	menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	left.add_child(menu)
	left.add_child(UI.gap(6))
	left.add_child(UI.volume_row(Loc.t("music_vol"), "Music", 360))
	left.add_child(UI.volume_row(Loc.t("sfx_vol"), "SFX", 360))

	# right: current build
	var card := UI.card(Color(UI.MINT, 0.45), 18, Color(UI.INK, 0.86))
	card.custom_minimum_size.x = 400
	row.add_child(card)
	var v := UI.vbox(8)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	card.add_child(v)
	v.add_child(_heading(Loc.t("build")))
	for w in game.player.weapons:
		if w.evolved:
			var evo: Dictionary = GameData.EVOLUTIONS[w.id]
			v.add_child(_item(w.id, {"name": evo.name, "color": UI.SUN}, GameData.WEAPON_MAX, Loc.t("evolution"), GameData.WEAPON_MAX))
		else:
			v.add_child(_item(w.id, GameData.WEAPONS[w.id], w.level, "", GameData.WEAPON_MAX))
	if not game.player.passives.is_empty():
		v.add_child(UI.gap(4))
		for id in game.player.passives:
			v.add_child(_item(id, GameData.PASSIVES[id], game.player.passives[id]))
	UI.pop_in(left, 0.0, Vector2(-30, 0), 0.35)
	UI.pop_in(card, 0.08, Vector2(30, 0), 0.35)
	resume.grab_focus.call_deferred()


func _stats() -> Control:
	var h := UI.hbox(18)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	var sorted := 0
	for t in GameData.BIN_TYPES:
		sorted += int(game.recycled[t])
	var items := [
		["clock", UI.fmt_time(game.elapsed), UI.SUN],
		["star", "%s %d" % [Loc.t("lv"), game.player.level], Color(0.35, 0.85, 1.0)],
		["recycle", str(game.kills), UI.MINT],
		["gem", str(sorted), Color(0.6, 1, 0.6)],
	]
	for s in items:
		var item := UI.hbox(6)
		item.add_child(UI.Icons.make(s[0], s[2], 18))
		var l := UI.label(s[1], 18, Color.WHITE, 0)
		l.add_theme_font_override("font", UI.font(0.5, 0))
		item.add_child(l)
		h.add_child(item)
	return h


func _heading(text: String) -> Label:
	var l := UI.label(Loc.upper(text), 13, UI.SUN, 0)
	l.add_theme_font_override("font", UI.font(0.4, 2))
	return l


func _item(id: String, d: Dictionary, level: int, tag := "", max_lv := 5) -> Control:
	var h := UI.hbox(12)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	h.add_child(UI.icon_tile(id, d.color, 40))
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nl := UI.label(Loc.pick(d.name), 17, Color.WHITE, 0)
	nl.add_theme_font_override("font", UI.font(0.4, 0))
	v.add_child(nl)
	v.add_child(UI.pips(level, d.color, max_lv, Vector2(12 if max_lv > 5 else 18, 5)))
	h.add_child(UI.label(tag if tag != "" else "%s %d" % [Loc.t("lv"), level], 15, d.color.lightened(0.3), 0))
	return h
