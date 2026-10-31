extends CanvasLayer
## Level-up screen: pick 1 of 3 upgrade cards, each carrying a fact.

const UI = preload("res://scripts/ui/ui_kit.gd")

var game
var _pending := 0
var _choices: Array = []
var _open := false
var _delay := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func is_open() -> bool:
	return _open


func queue_level_up() -> void:
	_pending += 1
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
	if game.autotest:
		_delay = 0.0
		_pick.call_deferred(randi() % _choices.size())


func close() -> void:
	_pending = 0
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


func _pick(i: int) -> void:
	if not _open or _delay > 0.0 or i >= _choices.size():
		return
	game.apply_choice(_choices[i])
	Sfx.play("select")
	_pending -= 1
	if _pending > 0:
		_show_next()
	else:
		close()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	add_child(UI.dim(0.65))
	var center := UI.centered()
	add_child(center)
	var vb := UI.vbox(18)
	center.add_child(vb)
	var title := UI.label(Loc.t("level_up"), 54, Color(1, 0.9, 0.35), 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := UI.label(Loc.t("choose"), 20, Color(0.85, 0.95, 0.95), 4)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var hb := UI.hbox(22)
	vb.add_child(hb)
	for i in _choices.size():
		hb.add_child(_card(i, _choices[i]))


func _card(i: int, c: Dictionary) -> Button:
	var name_txt := ""
	var desc := ""
	var fact := ""
	var kind_txt := ""
	var color := Color.WHITE
	match c.kind:
		"weapon":
			var d: Dictionary = GameData.WEAPONS[c.id]
			name_txt = Loc.pick(d.name)
			desc = Loc.pick(d.desc) if c.level == 1 else Loc.pick(d.up[c.level - 2])
			fact = GameData.fact_text(d.fact)
			kind_txt = Loc.t("weapon")
			color = d.color
		"passive":
			var d: Dictionary = GameData.PASSIVES[c.id]
			name_txt = Loc.pick(d.name)
			desc = Loc.pick(d.desc)
			fact = GameData.fact_text(d.fact)
			kind_txt = Loc.t("passive")
			color = d.color
		_:
			name_txt = Loc.t("heal_name")
			desc = Loc.t("heal_desc")
			fact = GameData.fact_text(17)
			color = Color(0.4, 0.9, 1.0)
	var b := Button.new()
	b.custom_minimum_size = Vector2(310, 400)
	var base := Color(0.06, 0.2, 0.2, 0.97)
	b.add_theme_stylebox_override("normal", UI.style(base, 18, color.darkened(0.2), 3))
	b.add_theme_stylebox_override("hover", UI.style(base.lightened(0.1), 18, color, 5))
	b.add_theme_stylebox_override("pressed", UI.style(base.lightened(0.15), 18, Color.WHITE, 5))
	b.add_theme_stylebox_override("focus", UI.style(base, 18, color, 5))
	b.pressed.connect(_pick.bind(i))
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
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	top.add_child(UI.label("[%d]" % (i + 1), 18, Color(0.7, 0.8, 0.8), 0))
	var k := UI.label("  " + kind_txt, 16, Color(0.7, 0.8, 0.8), 0)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(k)
	var lv_txt := Loc.t("new") if c.level == 1 else "%s %d" % [Loc.t("lv"), c.level]
	if c.kind == "heal":
		lv_txt = ""
	top.add_child(UI.label(lv_txt, 18, Color(1, 0.85, 0.3) if c.level == 1 else Color(0.6, 1, 0.7), 0))
	var nl := UI.wrap_label(name_txt, 27, color, 270)
	nl.add_theme_constant_override("outline_size", 4)
	nl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	v.add_child(nl)
	# level pips
	var pips := HBoxContainer.new()
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if c.kind != "heal":
		for p in 5:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(22, 8)
			pip.color = color if p < c.level else Color(1, 1, 1, 0.15)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pips.add_child(pip)
	v.add_child(pips)
	v.add_child(UI.wrap_label(desc, 20, Color.WHITE, 270))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	v.add_child(UI.label(Loc.t("did_you_know"), 16, Color(1, 0.9, 0.4), 0))
	v.add_child(UI.wrap_label(fact, 15, Color(0.8, 0.88, 0.88), 270))
	return b
