extends CanvasLayer
## Level-up / reward-crate screen: pick 1 of 3 upgrade cards (each carrying a
## fact). Ready evolutions take the first card; rerolls come from upgrades.

const UI = preload("res://scripts/ui/ui_kit.gd")

var game
var _queue: Array[String] = []   # "level" or "chest"
var _choices: Array = []
var _open := false
var _delay := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func is_open() -> bool:
	return _open


func queue_level_up(kind := "level") -> void:
	_queue.append(kind)
	if not _open:
		_show_next()


func _show_next() -> void:
	if game.finished:
		return
	_open = true
	get_tree().paused = true
	_choices = game.roll_choices()
	_build()
	visible = true
	_delay = 0.3
	if game.trailer != null:
		_delay = 0.0
		game.trailer.on_cards(self)
	elif game.autotest:
		_delay = 0.0
		_pick.call_deferred(0 if _choices[0].kind == "evolve" else randi() % _choices.size())


func close() -> void:
	_queue.clear()
	if _open:
		_open = false
		visible = false
		get_tree().paused = false


func _process(delta: float) -> void:
	if _delay > 0.0:
		_delay -= delta


func _unhandled_input(ev: InputEvent) -> void:
	if not _open:
		return
	for i in 3:
		if ev.is_action_pressed("pick_%d" % (i + 1)):
			_pick(i)
			get_viewport().set_input_as_handled()
	if ev.is_action_pressed("reroll"):
		_reroll()
		get_viewport().set_input_as_handled()


func _reroll() -> void:
	if not _open or _delay > 0.0 or game.player.rerolls <= 0:
		return
	game.player.rerolls -= 1
	_choices = game.roll_choices()
	Sfx.play("whoosh")
	_build()


func _pick(i: int) -> void:
	if not _open or _delay > 0.0 or i >= _choices.size():
		return
	game.apply_choice(_choices[i])
	Sfx.play("select")
	_queue.pop_front()
	if not _queue.is_empty():
		_show_next()
	else:
		close()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	add_child(UI.dim(0.45))
	add_child(UI.vignette(Color(0.0, 0.03, 0.04, 0.9), 0.35))
	var center := UI.centered()
	add_child(center)
	var vb := UI.vbox(14)
	center.add_child(vb)
	var chest := not _queue.is_empty() and _queue[0] == "chest"
	var title := UI.label(Loc.t("chest_title") if chest else Loc.t("level_up"), 56, Color(1.0, 0.75, 0.3) if chest else UI.SUN, 0)
	title.add_theme_font_override("font", UI.font(0.9, 3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.shadow(title, 5)
	vb.add_child(title)
	var sub := UI.hbox(10)
	sub.add_child(UI.chip(UI.MINT, Vector2(28, 3), 1))
	var lv := UI.label("%s %d" % [Loc.t("lv"), game.player.level], 18, UI.MINT, 0)
	lv.add_theme_font_override("font", UI.font(0.5, 2))
	sub.add_child(lv)
	sub.add_child(UI.chip(UI.MINT, Vector2(28, 3), 1))
	vb.add_child(sub)
	vb.add_child(UI.gap(6))
	var hb := UI.hbox(22)
	vb.add_child(hb)
	for i in _choices.size():
		var card := _card(i, _choices[i])
		hb.add_child(card)
	var foot := UI.hbox(18)
	vb.add_child(foot)
	var hint := UI.label(Loc.t("choose"), 16, Color(1, 1, 1, 0.6), 0)
	foot.add_child(hint)
	if game.player.rerolls > 0:
		var rr := UI.menu_button("%s (R)  ×%d" % [Loc.t("reroll"), game.player.rerolls], false, 220)
		rr.custom_minimum_size.y = 42
		rr.add_theme_font_size_override("font_size", 16)
		rr.focus_mode = Control.FOCUS_NONE
		rr.pressed.connect(_reroll)
		foot.add_child(rr)
	# pop the title and cards in after layout has placed them
	_animate_in.call_deferred(title, hb)


func _animate_in(title: Label, hb: HBoxContainer) -> void:
	title.pivot_offset = title.size * 0.5
	title.scale = Vector2(1.4, 1.4)
	title.create_tween().tween_property(title, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# the card content sits in a non-container Button, so grow every card to
	# fit the tallest content (long names / descriptions wrap to more lines)
	var tallest := 0.0
	for c in hb.get_children():
		for k in c.get_children():
			if k is MarginContainer:
				tallest = maxf(tallest, k.get_combined_minimum_size().y)
	for c in hb.get_children():
		c.custom_minimum_size.y = maxf(c.custom_minimum_size.y, tallest)
	for i in hb.get_child_count():
		var c: Control = hb.get_child(i)
		c.pivot_offset = c.size * 0.5
		UI.pop_in(c, 0.05 + i * 0.07, Vector2(0, 40), 0.4)


func _card(i: int, c: Dictionary) -> Button:
	var name_txt := ""
	var desc := ""
	var fact := ""
	var kind_txt := ""
	var icon := ""
	var color := Color.WHITE
	match c.kind:
		"weapon":
			var d: Dictionary = GameData.WEAPONS[c.id]
			name_txt = Loc.pick(d.name)
			if c.level == 1:
				desc = Loc.pick(d.desc)
			elif c.level <= 5:
				desc = Loc.pick(d.up[c.level - 2])
			else:
				desc = Loc.t("weapon_mastery")
			fact = GameData.fact_text(d.fact)
			kind_txt = Loc.t("weapon")
			color = d.color
			icon = c.id
		"passive":
			var d: Dictionary = GameData.PASSIVES[c.id]
			name_txt = Loc.pick(d.name)
			desc = Loc.pick(d.desc)
			fact = GameData.fact_text(d.fact)
			kind_txt = Loc.t("passive")
			color = d.color
			icon = c.id
		"evolve":
			var d: Dictionary = GameData.EVOLUTIONS[c.id]
			name_txt = Loc.pick(d.name)
			desc = Loc.pick(d.desc)
			fact = GameData.fact_text(GameData.WEAPONS[c.id].fact)
			kind_txt = Loc.t("evolution")
			color = UI.SUN
			icon = c.id
		"stat":
			var d: Dictionary = GameData.STAT_CARDS[c.id]
			name_txt = Loc.pick(d.name)
			desc = Loc.pick(d.desc)
			fact = GameData.random_fact()
			kind_txt = Loc.t("stat_card")
			color = d.color
			icon = d.icon
		_:
			name_txt = Loc.t("heal_name")
			desc = Loc.t("heal_desc")
			fact = GameData.fact_text(17)
			color = Color(0.4, 0.9, 1.0)
			icon = "heal"
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 420)
	var base := Color(UI.INK, 0.96)
	b.add_theme_stylebox_override("normal", _style(base, Color(color, 0.45), 2))
	b.add_theme_stylebox_override("hover", _style(base.lightened(0.06), color, 4))
	b.add_theme_stylebox_override("pressed", _style(base.lightened(0.1), Color.WHITE, 4))
	b.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), color, 4))
	b.pressed.connect(_pick.bind(i))
	b.mouse_entered.connect(_hover.bind(b, true))
	b.mouse_exited.connect(_hover.bind(b, false))
	b.focus_entered.connect(_hover.bind(b, true))
	b.focus_exited.connect(_hover.bind(b, false))

	# colored header band
	var head := Panel.new()
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(color.darkened(0.55), 0.9)
	hs.corner_radius_top_left = 18
	hs.corner_radius_top_right = 18
	head.add_theme_stylebox_override("panel", hs)
	head.anchor_right = 1.0
	head.offset_left = 2
	head.offset_right = -2
	head.offset_top = 2
	head.offset_bottom = 116
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(head)

	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 18)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	top.add_child(UI.icon_tile(icon, color, 78))
	var tv := UI.vbox(6)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 6)
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(tags)
	if kind_txt != "":
		tags.add_child(UI.pill(Loc.upper(kind_txt), color, 12))
	if c.kind == "evolve":
		# weapon + partner passive = evolution
		var combo := UI.hbox(4)
		combo.alignment = BoxContainer.ALIGNMENT_BEGIN
		combo.add_child(UI.icon_tile(c.id, GameData.WEAPONS[c.id].color, 26))
		combo.add_child(UI.label("+", 16, UI.SUN, 0))
		var pid: String = GameData.EVOLUTIONS[c.id].passive
		combo.add_child(UI.icon_tile(pid, GameData.PASSIVES[pid].color, 26))
		tv.add_child(combo)
	elif c.kind == "stat":
		tags.add_child(UI.pill("×%d" % c.level, UI.MINT, 12))
	elif c.kind != "heal":
		if c.level == 1:
			tags.add_child(UI.pill(Loc.t("new"), UI.SUN, 12))
		else:
			tags.add_child(UI.pill("%s %d" % [Loc.t("lv"), c.level], UI.MINT, 12))
		var max_lv: int = GameData.WEAPON_MAX if c.kind == "weapon" else GameData.PASSIVE_MAX
		tv.add_child(UI.pips(c.level, color, max_lv, Vector2(14 if max_lv > 5 else 22, 7)))
	# key hint in the corner
	var key := UI.label(str(i + 1), 18, Color(1, 1, 1, 0.75), 0)
	key.add_theme_font_override("font", UI.font(0.6, 0))
	var kp := PanelContainer.new()
	var ks := UI.style(Color(0, 0, 0, 0.35), 8, Color(1, 1, 1, 0.3), 1)
	ks.content_margin_left = 9
	ks.content_margin_right = 9
	ks.content_margin_top = 2
	ks.content_margin_bottom = 2
	kp.add_theme_stylebox_override("panel", ks)
	kp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	kp.add_child(key)
	top.add_child(kp)

	v.add_child(UI.gap(8))
	var nl := UI.wrap_label(name_txt, 24, color.lightened(0.25), 264)
	nl.add_theme_font_override("font", UI.font(0.7, 1))
	v.add_child(nl)
	v.add_child(UI.wrap_label(desc, 18, Color(1, 1, 1, 0.92), 264))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	var fc := UI.card(Color(UI.SUN, 0.7), 10, Color(1, 1, 1, 0.05), Vector4(12, 8, 10, 10))
	var fv := UI.vbox(3)
	fv.alignment = BoxContainer.ALIGNMENT_BEGIN
	fc.add_child(fv)
	var dyk := UI.label(Loc.upper(Loc.t("did_you_know")), 12, UI.SUN, 0)
	dyk.add_theme_font_override("font", UI.font(0.4, 2))
	fv.add_child(dyk)
	fv.add_child(UI.wrap_label(fact, 14, Color(0.82, 0.9, 0.9), 240))
	v.add_child(fc)
	return b


func _style(bg: Color, border: Color, w: int) -> StyleBoxFlat:
	var s := UI.style(bg, 20, border, w)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 6)
	return s


func _hover(b: Button, on: bool) -> void:
	if on:
		Sfx.play("click", -8)
	b.pivot_offset = b.size * 0.5
	b.z_index = 1 if on else 0
	b.create_tween().tween_property(b, "scale", Vector2.ONE * (1.05 if on else 1.0), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
