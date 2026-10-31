extends CanvasLayer
## In-run HUD: player card (level/XP/HP), run timeline, kills, quest, carried
## materials, combo, buffs, build slots, abilities, boss bar, toasts, banners
## and edge arrows to the bins / e-waste point.

const UI = preload("res://scripts/ui/ui_kit.gd")
const Bar = preload("res://scripts/ui/bar.gd")
const Icons = preload("res://scripts/ui/icons.gd")
const Player = preload("res://scripts/player.gd")
const Sorting = preload("res://scripts/sorting.gd")

const HP_COL := Color(0.95, 0.3, 0.32)
const XP_COL := Color(0.35, 0.85, 1.0)
const BOSS_COL := Color(0.78, 0.25, 0.85)
const MINI_COL := Color(1.0, 0.55, 0.25)
const ULT_COL := Color(0.62, 1.0, 0.7)
const EWASTE_COL := Color(1.0, 0.7, 0.25)

var game

var _root: Control
var _badge: Control
var _hp_bar: Bar
var _hp_label: Label
var _xp_bar: Bar
var _xp_label: Label
var _time_label: Label
var _track: Control
var _kill_label: Label
var _mat_rows := {}  # type -> {bar, count, full, row}
var _buff_box: VBoxContainer
var _buff_rows := {}  # id -> {bar, time}
var _buff_max := {}
var _build_box: VBoxContainer
var _build_sig := ""
var _boss_box: Control
var _boss_bar: Bar
var _boss_name: Label
var _boss = null
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _font := UI.font(0.7, 0)
var _banner_box: Control
var _banner: Label
var _banner_tween: Tween
var _overlay: Control
var _vignette: TextureRect
var _hurt := 0.0
var _pulse := 0.0
var _last_hp := -1.0
var _last_level := 0
var _combo_card: PanelContainer
var _combo_label: Label
var _combo_bar: Bar
var _quest_card: PanelContainer
var _quest_label: Label
var _quest_bar: Bar
var _quest_time: Label
var _abilities: Control
var _smog: ColorRect
var _ult_ready := false
var _ult_flash := 0.0


func _ready() -> void:
	layer = 1
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# red screen-edge vignette: pulses on hits and while health is low
	_vignette = UI.vignette(Color(0.75, 0.0, 0.05, 0.75))
	_vignette.modulate.a = 0.0
	_root.add_child(_vignette)
	_smog = ColorRect.new()
	_smog.color = Color(0.45, 0.42, 0.35, 0.0)
	_smog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_smog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_smog)

	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	_root.add_child(_overlay)

	_root.add_child(_player_card())
	_root.add_child(_timeline())
	_root.add_child(_kills_card())
	_root.add_child(_quest_panel())
	_root.add_child(_left_stack())
	_root.add_child(_build_panel())
	_root.add_child(_ability_panel())
	_root.add_child(_boss_panel())
	_root.add_child(_toast_panel())
	_root.add_child(_banner_panel())


# --- construction ---------------------------------------------------------------

func _player_card() -> Control:
	var card := UI.card(Color(XP_COL, 0.5), 16, Color(UI.INK, 0.78), Vector4(12, 10, 18, 10))
	card.position = Vector2(16, 16)
	var h := UI.hbox(12)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	card.add_child(h)
	# level badge with circular XP ring
	_badge = Control.new()
	_badge.custom_minimum_size = Vector2(62, 62)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.draw.connect(_draw_badge)
	h.add_child(_badge)
	var v := UI.vbox(5)
	h.add_child(v)
	var hp_row := UI.hbox(8)
	hp_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	hp_row.add_child(Icons.make("heart", HP_COL, 20))
	_hp_bar = _bar(Vector2(230, 22), HP_COL)
	_hp_bar.ghost_color = Color(1.0, 0.9, 0.7, 0.75)
	_hp_bar.segments = 10
	hp_row.add_child(_hp_bar)
	_hp_label = _num_label(15)
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_bar.add_child(_hp_label)
	v.add_child(hp_row)
	var xp_row := UI.hbox(8)
	xp_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	var xp_tag := UI.label("XP", 13, XP_COL, 0)
	xp_tag.add_theme_font_override("font", UI.font(0.6, 1))
	xp_tag.custom_minimum_size.x = 20
	xp_row.add_child(xp_tag)
	_xp_bar = _bar(Vector2(230, 10), XP_COL)
	_xp_bar.smooth = 10.0
	xp_row.add_child(_xp_bar)
	v.add_child(xp_row)
	_xp_label = UI.label("", 12, Color(1, 1, 1, 0.6), 0)
	v.add_child(_xp_label)
	return card


func _timeline() -> Control:
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.offset_left = -170
	box.offset_right = 170
	box.offset_top = 14
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill := UI.card(Color(UI.SUN, 0.6), 22, Color(UI.INK, 0.78), Vector4(18, 4, 20, 4))
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var h := UI.hbox(10)
	pill.add_child(h)
	h.add_child(Icons.make("clock", UI.SUN, 24))
	_time_label = _num_label(34)
	_time_label.text = "00:00"
	h.add_child(_time_label)
	box.add_child(pill)
	# run progress with miniboss / boss markers
	_track = Control.new()
	_track.custom_minimum_size = Vector2(340, 22)
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.draw.connect(_draw_track)
	box.add_child(_track)
	return box


func _kills_card() -> Control:
	var card := UI.card(Color(UI.MINT, 0.5), 16, Color(UI.INK, 0.78), Vector4(14, 8, 16, 8))
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.offset_left = -16
	card.offset_right = -16
	card.offset_top = 16
	card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var h := UI.hbox(10)
	card.add_child(h)
	h.add_child(Icons.make("recycle", UI.MINT, 30))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	_kill_label = _num_label(28)
	_kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_kill_label)
	var cap := UI.label(Loc.upper(Loc.t("kills")), 11, UI.MUTED, 0)
	cap.add_theme_font_override("font", UI.font(0.3, 1))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(cap)
	return card


func _left_stack() -> Control:
	var v := UI.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.position = Vector2(16, 132)
	var card := UI.card(Color(1, 1, 1, 0.14), 14, Color(UI.INK, 0.72), Vector4(14, 10, 14, 12))
	v.add_child(card)
	var mv := UI.vbox(6)
	card.add_child(mv)
	var title := UI.label(Loc.upper(Loc.t("carried")), 12, UI.SUN, 0)
	title.add_theme_font_override("font", UI.font(0.4, 2))
	mv.add_child(title)
	for t in GameData.BIN_TYPES:
		var c: Color = GameData.MATERIALS[t].color
		var row := UI.hbox(8)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_child(Icons.make("gem", c, 20))
		var nl := UI.label(Loc.pick(GameData.MATERIALS[t].name), 15, Color(1, 1, 1, 0.9), 0)
		nl.custom_minimum_size.x = 64
		row.add_child(nl)
		var bar := _bar(Vector2(104, 12), c)
		bar.segments = 3
		bar.smooth = 18.0
		row.add_child(bar)
		var cnt := _num_label(15)
		cnt.custom_minimum_size.x = 30
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(cnt)
		var full := UI.pill(Loc.t("full"), Color(1, 0.45, 0.35), 11)
		full.visible = false
		row.add_child(full)
		mv.add_child(row)
		_mat_rows[t] = {"bar": bar, "count": cnt, "full": full}
	# e-waste is carried separately to the collection point
	var erow := UI.hbox(8)
	erow.alignment = BoxContainer.ALIGNMENT_BEGIN
	erow.add_child(Icons.make("efficiency", EWASTE_COL, 20))
	var enl := UI.label(Loc.pick(GameData.MATERIALS.ewaste.name), 15, Color(1, 1, 1, 0.9), 0)
	enl.custom_minimum_size.x = 64
	erow.add_child(enl)
	var ebar := _bar(Vector2(104, 12), EWASTE_COL)
	ebar.segments = 4
	erow.add_child(ebar)
	var ecnt := _num_label(15)
	ecnt.custom_minimum_size.x = 30
	ecnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	erow.add_child(ecnt)
	mv.add_child(erow)
	_mat_rows["ewaste"] = {"bar": ebar, "count": ecnt, "full": null}
	# combo streak
	_combo_card = UI.card(Color(UI.SUN, 0.9), 12, Color(0.25, 0.18, 0.02, 0.85), Vector4(12, 6, 14, 8))
	_combo_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var ch := UI.hbox(10)
	_combo_card.add_child(ch)
	ch.add_child(Icons.make("recycle", UI.SUN, 24))
	var cv := UI.vbox(3)
	ch.add_child(cv)
	_combo_label = UI.label("", 18, UI.SUN, 4)
	_combo_label.add_theme_font_override("font", UI.font(0.8, 2))
	cv.add_child(_combo_label)
	_combo_bar = _bar(Vector2(150, 6), UI.SUN)
	_combo_bar.smooth = 30.0
	cv.add_child(_combo_bar)
	_combo_card.visible = false
	v.add_child(_combo_card)
	_buff_box = UI.vbox(6)
	_buff_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_child(_buff_box)
	return v


func _quest_panel() -> Control:
	_quest_card = UI.card(Color(UI.MINT, 0.9), 14, Color(UI.INK, 0.82), Vector4(14, 8, 14, 10))
	_quest_card.anchor_left = 1.0
	_quest_card.anchor_right = 1.0
	_quest_card.offset_left = -16
	_quest_card.offset_right = -16
	_quest_card.offset_top = 96
	_quest_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_quest_card.custom_minimum_size.x = 250
	var v := UI.vbox(5)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	_quest_card.add_child(v)
	var top := UI.hbox(6)
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_child(Icons.make("star", UI.MINT, 14))
	var cap := UI.label(Loc.upper(Loc.t("quest")), 12, UI.MINT, 0)
	cap.add_theme_font_override("font", UI.font(0.5, 2))
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(cap)
	_quest_time = _num_label(13)
	top.add_child(_quest_time)
	v.add_child(top)
	_quest_label = UI.wrap_label("", 16, Color.WHITE, 222)
	v.add_child(_quest_label)
	_quest_bar = _bar(Vector2(222, 8), UI.MINT)
	v.add_child(_quest_bar)
	_quest_card.visible = false
	return _quest_card


## Dash + Blast buttons (bottom right), drawn in code.
func _ability_panel() -> Control:
	_abilities = Control.new()
	_abilities.anchor_left = 1.0
	_abilities.anchor_right = 1.0
	_abilities.anchor_top = 1.0
	_abilities.anchor_bottom = 1.0
	_abilities.offset_left = -236
	_abilities.offset_right = -16
	_abilities.offset_top = -116
	_abilities.offset_bottom = -16
	_abilities.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_abilities.draw.connect(_draw_abilities)
	return _abilities


func _build_panel() -> Control:
	_build_box = UI.vbox(6)
	_build_box.alignment = BoxContainer.ALIGNMENT_END
	_build_box.anchor_top = 1.0
	_build_box.anchor_bottom = 1.0
	_build_box.offset_left = 16
	_build_box.offset_bottom = -16
	_build_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	return _build_box


func _boss_panel() -> Control:
	_boss_box = VBoxContainer.new()
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.offset_left = -310
	_boss_box.offset_right = 310
	_boss_box.offset_top = 104
	_boss_box.add_theme_constant_override("separation", 4)
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	var h := UI.hbox(8)
	h.add_child(Icons.make("skull", Color(1, 0.85, 0.3), 22))
	_boss_name = UI.label("", 22, Color(1, 0.85, 0.3), 6)
	_boss_name.add_theme_font_override("font", UI.font(0.6, 2))
	h.add_child(_boss_name)
	h.add_child(Icons.make("skull", Color(1, 0.85, 0.3), 22))
	_boss_box.add_child(h)
	_boss_bar = _bar(Vector2(620, 20), BOSS_COL)
	_boss_bar.ghost_color = Color(1, 0.85, 0.4, 0.8)
	_boss_bar.bg_color = Color(0.1, 0.02, 0.06, 0.85)
	_boss_bar.border_color = Color(1, 0.85, 0.3, 0.5)
	_boss_box.add_child(_boss_bar)
	return _boss_box


func _toast_panel() -> Control:
	_toast = UI.card(Color.WHITE, 16, Color(UI.INK, 0.9), Vector4(22, 12, 22, 14))
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_left = -320
	_toast.offset_right = 320
	_toast.offset_bottom = -26
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.modulate.a = 0.0
	_toast_label = UI.wrap_label("", 17, Color.WHITE, 596)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast.add_child(_toast_label)
	return _toast


func _banner_panel() -> Control:
	_banner_box = Control.new()
	_banner_box.anchor_right = 1.0
	_banner_box.anchor_top = 0.27
	_banner_box.anchor_bottom = 0.27
	_banner_box.offset_top = -46
	_banner_box.offset_bottom = 46
	_banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_box.modulate.a = 0.0
	# horizontal dark band that fades out to both sides
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 4
	var band := TextureRect.new()
	band.texture = gt
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_box.add_child(band)
	_banner = UI.label("", 44, Color.WHITE, 10)
	_banner.add_theme_font_override("font", UI.font(0.8, 3))
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_box.add_child(_banner)
	return _banner_box


func _bar(sz: Vector2, c: Color) -> Bar:
	var b := Bar.new()
	b.custom_minimum_size = sz
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.fill_color = c
	return b


func _num_label(sz: int) -> Label:
	var l := UI.label("", sz, Color.WHITE, 5)
	l.add_theme_font_override("font", UI.font(0.6, 1))
	return l


# --- per frame -------------------------------------------------------------------

func refresh(delta: float) -> void:
	_pulse += delta
	var p = game.player
	_hurt = maxf(0.0, _hurt - delta * 2.5)
	var low := clampf(1.0 - p.hp / (p.max_hp * 0.35), 0.0, 1.0)
	_vignette.modulate.a = maxf(_hurt, low * (0.55 + sin(_pulse * 5.0) * 0.25))

	_hp_bar.value = p.hp / p.max_hp
	_hp_bar.fill_color = HP_COL.lerp(Color(1, 0.75, 0.3), low * (0.5 + 0.5 * sin(_pulse * 10.0)))
	if p.hp < _last_hp - 0.5:
		_hp_bar.flash = 1.0
	_last_hp = p.hp
	_hp_label.text = "%d / %d" % [ceili(p.hp), int(p.max_hp)]
	_xp_bar.value = p.xp / p.xp_need
	if p.level != _last_level:
		if _last_level > 0:
			_xp_bar.snap(0.0)
			_xp_bar.flash = 1.0
		_last_level = p.level
	_xp_label.text = "%d / %d XP" % [int(p.xp), int(p.xp_need)]
	_badge.queue_redraw()

	_time_label.text = UI.fmt_time(game.elapsed)
	_track.queue_redraw()
	_kill_label.text = str(game.kills)

	var cap: int = p.carry_cap()
	for t in GameData.BIN_TYPES:
		var n: int = game.carried[t]
		var r: Dictionary = _mat_rows[t]
		var full: bool = n >= cap
		r.bar.value = float(n) / cap
		r.count.text = str(n)
		r.full.visible = full
		r.count.modulate = Color(1, 0.6, 0.5) if full and int(_pulse * 4.0) % 2 == 0 else Color.WHITE
	var en: int = game.sorting.ewaste_carried
	_mat_rows.ewaste.bar.value = float(en) / Sorting.EWASTE_CAP
	_mat_rows.ewaste.count.text = str(en)
	_refresh_combo()
	_refresh_quest()
	_refresh_buffs(p)
	_refresh_build(p)
	if p.ult >= Player.ULT_MAX and not _ult_ready:
		_ult_ready = true
		toast(Loc.t("ult_ready"), ULT_COL)
	elif p.ult < Player.ULT_MAX:
		_ult_ready = false
	_ult_flash = maxf(0.0, _ult_flash - delta * 2.0)
	_abilities.queue_redraw()

	if _boss != null:
		if is_instance_valid(_boss) and not _boss.dead:
			_boss_bar.value = _boss.hp / _boss.max_hp
		else:
			set_boss(null)
	_overlay.queue_redraw()


func _refresh_combo() -> void:
	var s = game.sorting
	_combo_card.visible = s.combo >= 1
	if s.combo >= 1:
		_combo_label.text = "%s x%d   +%d%%" % [Loc.t("combo"), s.combo, int(round((s.combo_mult() - 1.0) * 100.0))]
		_combo_bar.value = s.combo_t / Sorting.COMBO_WINDOW


func _refresh_quest() -> void:
	var q: Dictionary = game.quests.active
	_quest_card.visible = not q.is_empty()
	if q.is_empty():
		return
	_quest_label.text = game.quests.text()
	_quest_bar.value = q.progress / maxf(1.0, q.goal)
	_quest_time.text = "%ds" % ceili(q.left)
	_quest_time.modulate = Color(1, 0.5, 0.4) if q.left < 8.0 else Color.WHITE


func _refresh_buffs(p) -> void:
	for b in _buff_rows.keys():
		if not p.buffs.has(b):
			_buff_rows[b].row.queue_free()
			_buff_rows.erase(b)
			_buff_max.erase(b)
	for b in p.buffs:
		var left: float = p.buffs[b]
		if not _buff_rows.has(b):
			_buff_rows[b] = _buff_row(b)
		if left > _buff_max.get(b, 0.0):
			_buff_max[b] = left
		var r: Dictionary = _buff_rows[b]
		r.bar.value = left / maxf(0.1, _buff_max[b])
		r.time.text = "%ds" % ceili(left)
		r.row.modulate.a = 1.0 if left > 2.0 or int(_pulse * 6.0) % 2 == 0 else 0.45


func _buff_row(b: String) -> Dictionary:
	var c := _buff_color(b)
	var card := UI.card(Color(c, 0.9), 12, Color(c.darkened(0.7), 0.82), Vector4(10, 6, 12, 6))
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var h := UI.hbox(8)
	card.add_child(h)
	h.add_child(Icons.make(b, c.lightened(0.2), 22))
	var v := UI.vbox(3)
	h.add_child(v)
	var nl := UI.label(Loc.t("buff_" + b), 14, Color.WHITE, 0)
	nl.add_theme_font_override("font", UI.font(0.4, 1))
	v.add_child(nl)
	var bar := _bar(Vector2(110, 6), c)
	bar.smooth = 30.0
	v.add_child(bar)
	var time := _num_label(15)
	time.custom_minimum_size.x = 32
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(time)
	_buff_box.add_child(card)
	UI.pop_in(card, 0.0, Vector2(-30, 0), 0.35)
	return {"row": card, "bar": bar, "time": time}


func _buff_color(b: String) -> Color:
	for t in GameData.MATERIALS:
		if GameData.MATERIALS[t].buff == b:
			return GameData.MATERIALS[t].color
	return Color.WHITE


## Weapon and passive slots, rebuilt only when the build changes.
func _refresh_build(p) -> void:
	var sig := ""
	for w in p.weapons:
		sig += "%s%d," % [w.id, w.level]
	for id in p.passives:
		sig += "%s%d," % [id, p.passives[id]]
	if sig == _build_sig:
		return
	_build_sig = sig
	for c in _build_box.get_children():
		c.queue_free()
	var wl := {}
	for w in p.weapons:
		wl[w.id] = w.level
	_build_box.add_child(_slot_row(wl, GameData.WEAPONS, GameData.MAX_WEAPONS, GameData.WEAPON_MAX))
	_build_box.add_child(_slot_row(p.passives, GameData.PASSIVES, GameData.MAX_PASSIVES, GameData.PASSIVE_MAX))


func _slot_row(owned: Dictionary, data: Dictionary, slots: int, max_lv: int) -> Control:
	var h := UI.hbox(6)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	var ids: Array = owned.keys()
	for i in slots:
		var v := UI.vbox(3)
		if i < ids.size():
			var id: String = ids[i]
			var lv: int = owned[id]
			var c: Color = data[id].color
			if lv > max_lv:
				var tile := UI.icon_tile(id, UI.SUN, 40)
				v.add_child(tile)
				v.add_child(UI.chip(UI.SUN, Vector2(37, 4), 2))
			else:
				v.add_child(UI.icon_tile(id, c, 40))
				v.add_child(_slot_pips(lv, c, max_lv))
		else:
			v.add_child(UI.icon_tile("", Color.WHITE, 40, true))
			v.add_child(UI.gap(4))
		h.add_child(v)
	return h


## Tiny level pips that fit under a 40px slot tile.
func _slot_pips(lv: int, c: Color, max_lv: int) -> HBoxContainer:
	var h := UI.pips(lv, c, max_lv, Vector2(3 if max_lv > 5 else 5, 4))
	h.add_theme_constant_override("separation", 2 if max_lv > 5 else 3)
	return h


# --- custom drawing --------------------------------------------------------------

func _draw_badge() -> void:
	var p = game.player
	var c := _badge.size * 0.5
	var r := 27.0
	_badge.draw_circle(c, r + 3, Color(0, 0, 0, 0.5))
	_badge.draw_circle(c, r - 4, Color(0.05, 0.2, 0.24))
	_badge.draw_arc(c, r - 1, 0, TAU, 40, Color(1, 1, 1, 0.12), 5, true)
	var frac := clampf(p.xp / p.xp_need, 0.0, 1.0)
	if frac > 0.005:
		_badge.draw_arc(c, r - 1, -PI * 0.5, -PI * 0.5 + TAU * frac, 40, XP_COL, 5, true)
	var font := _font
	var lv := str(p.level)
	var fs := 24 if lv.length() < 3 else 19
	var tw := font.get_string_size(lv, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_badge.draw_string(font, c + Vector2(-tw * 0.5, 5), lv, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	var cap := Loc.t("lv")
	var cw := font.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	_badge.draw_string(font, c + Vector2(-cw * 0.5, 19), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(XP_COL, 0.9))


func _draw_track() -> void:
	var w := _track.size.x
	var y := 11.0
	var frac := clampf(game.elapsed / GameData.RUN_TIME, 0.0, 1.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(3)
	_track.draw_style_box(bg, Rect2(0, y - 3, w, 6))
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(UI.SUN, 0.9)
	fg.set_corner_radius_all(3)
	if frac > 0.0:
		_track.draw_style_box(fg, Rect2(0, y - 3, maxf(6.0, w * frac), 6))
	for m in [[0.5, "skull", MINI_COL], [1.0, "crown", BOSS_COL]]:
		var x: float = w * m[0] - (8.0 if m[0] >= 1.0 else 0.0)
		var passed: bool = frac >= m[0]
		_track.draw_circle(Vector2(x, y), 10, Color(0, 0, 0, 0.6))
		_track.draw_circle(Vector2(x, y), 8, m[2] if not passed else Color(0.4, 0.4, 0.4))
		Icons.draw_icon(_track, m[1], Vector2(x, y), 5.5, Color(0.08, 0.05, 0.05))
	var px := clampf(w * frac, 5.0, w - 5.0)
	_track.draw_circle(Vector2(px, y), 5 + sin(_pulse * 6.0), Color.WHITE)


## Edge-of-screen arrows pointing to bins, with carried counts and distance.
func _draw_overlay() -> void:
	if game == null or game.camera == null:
		return
	var cam: Camera3D = game.camera
	var size := _overlay.size
	var center := size * 0.5
	var font := _font
	var margin := 48.0
	var targets: Array = []
	for b in game.bins:
		targets.append([b, GameData.MATERIALS[b.mat_type].color, game.carried[b.mat_type], "gem"])
	var ep = game.sorting.ewaste_point
	if ep != null:
		targets.append([ep, EWASTE_COL, game.sorting.ewaste_carried, "efficiency"])
	for tgt in targets:
		var b: Node3D = tgt[0]
		var col: Color = tgt[1]
		var n: int = tgt[2]
		var wp: Vector3 = b.position + Vector3(0, 1.0, 0)
		var behind := cam.is_position_behind(wp)
		var sp := cam.unproject_position(wp)
		var inner := Rect2(Vector2.ZERO, size).grow(-margin)
		if not behind and inner.has_point(sp):
			if n > 0:
				# bouncing count bubble above an on-screen bin
				var bp := sp + Vector2(0, -112 - absf(sin(_pulse * 4.0)) * 8.0)
				var r := 21.0
				_overlay.draw_circle(bp, r + 4, Color(0, 0, 0, 0.55))
				_overlay.draw_circle(bp, r + 1, Color.WHITE)
				_overlay.draw_circle(bp, r - 1, col)
				_overlay.draw_colored_polygon(PackedVector2Array([bp + Vector2(-7, r - 2), bp + Vector2(7, r - 2), bp + Vector2(0, r + 9)]), Color.WHITE)
				_centered_text(font, bp + Vector2(0, 7), str(n), 20, Color.WHITE)
			continue
		var dir := sp - center
		if behind:
			dir = -dir
		if dir.length() < 0.01:
			continue
		dir = dir.normalized()
		var half := center - Vector2(margin, margin)
		var tx := absf(half.x / dir.x) if absf(dir.x) > 0.0001 else INF
		var ty := absf(half.y / dir.y) if absf(dir.y) > 0.0001 else INF
		var pos := center + dir * minf(tx, ty)
		var active := n > 0
		var alpha := 1.0 if active else 0.5
		var c := Color(col.r, col.g, col.b, alpha)
		var side := dir.orthogonal() * 11.0
		var push := (sin(_pulse * 7.0) * 3.0) if active else 0.0
		_overlay.draw_colored_polygon(PackedVector2Array([pos + dir * (38.0 + push), pos + dir * (21.0 + push) + side, pos + dir * (21.0 + push) - side]), c)
		_overlay.draw_circle(pos, 23.0, Color(0, 0, 0, 0.55 * alpha))
		if active:
			_overlay.draw_circle(pos, 21.0, Color.WHITE)
		_overlay.draw_circle(pos, 19.0, c)
		if active:
			_centered_text(font, pos + Vector2(0, 7), str(n), 19, Color.WHITE)
		else:
			Icons.draw_icon(_overlay, tgt[3], pos, 10.0, Color(1, 1, 1, 0.6))
		var dist := int(Vector2(b.position.x - game.player.position.x, b.position.z - game.player.position.z).length())
		var label_pos := pos - dir * 36.0 + Vector2(0, 5)
		_centered_text(font, label_pos, "%dm" % dist, 13, Color(1, 1, 1, 0.75 * alpha), true)


func _centered_text(font: Font, at: Vector2, text: String, fs: int, c: Color, outline := false) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := at - Vector2(w * 0.5, 0)
	if outline:
		_overlay.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.7 * c.a))
	_overlay.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)


# --- events ----------------------------------------------------------------------

func hurt_flash() -> void:
	_hurt = maxf(_hurt, 0.45)


## Hides the boss bar only if it is showing `b` (the miniboss can die after
## the final boss has taken over the bar).
func clear_boss(b) -> void:
	if _boss == b:
		set_boss(null)


func set_boss(b) -> void:
	var was := _boss != null
	_boss = b
	_boss_box.visible = b != null
	if b != null:
		_boss_name.text = Loc.upper(Loc.pick(GameData.ENEMIES[b.kind].name))
		_boss_bar.fill_color = BOSS_COL if b.kind == "boss" else MINI_COL
		if b.kind == "boss":
			_boss_bar.markers = [{"at": 0.33, "color": Color(1, 0.85, 0.3, 0.8)}, {"at": 0.66, "color": Color(1, 0.85, 0.3, 0.8)}]
		else:
			_boss_bar.markers = [{"at": 0.5, "color": Color(1, 0.85, 0.3, 0.8)}]
		_boss_bar.snap(1.0)
		if not was:
			UI.pop_in(_boss_box, 0.0, Vector2(0, -20), 0.5)


func toast(text: String, color := Color.WHITE) -> void:
	_toast_label.text = text
	var s: StyleBoxFlat = _toast.get_theme_stylebox("panel").duplicate()
	s.border_color = color
	s.border_width_left = 6
	_toast.add_theme_stylebox_override("panel", s)
	if _toast_tween:
		_toast_tween.kill()
	_toast.offset_bottom = -2.0
	_toast_tween = create_tween()
	_toast_tween.set_parallel()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_property(_toast, "offset_bottom", -26.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.chain().tween_interval(6.0)
	_toast_tween.chain().tween_property(_toast, "modulate:a", 0.0, 0.6)


func banner(text: String, color := Color.WHITE) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	if _banner_tween:
		_banner_tween.kill()
	_banner_box.modulate.a = 0.0
	_banner.pivot_offset = _banner_box.size * 0.5
	_banner.scale = Vector2(1.35, 1.35)
	_banner_tween = create_tween()
	_banner_tween.set_parallel()
	_banner_tween.tween_property(_banner_box, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(2.2)
	_banner_tween.chain().tween_property(_banner_box, "modulate:a", 0.0, 0.6)


func _draw_abilities() -> void:
	var p = game.player
	var font := _font
	# dash (small) and blast (big) buttons, right-aligned
	var dash_c := Vector2(_abilities.size.x - 150, _abilities.size.y - 38)
	var ult_c := Vector2(_abilities.size.x - 52, _abilities.size.y - 52)
	var dash_frac: float = 1.0 - p.dash_cd / maxf(0.01, Player.DASH_CD * (1.0 - 0.12 * p.meta("dash")))
	_ability(dash_c, 30.0, "speed", Color(0.4, 0.85, 1.0), clampf(dash_frac, 0.0, 1.0), "Shift", Loc.t("dash"), font)
	var uf: float = p.ult / Player.ULT_MAX
	_ability(ult_c, 44.0, "recycle", ULT_COL, uf, Loc.t("key_space"), Loc.t("ultimate"), font)


func _ability(c: Vector2, r: float, icon: String, col: Color, frac: float, key: String, cap: String, font: Font) -> void:
	var ready := frac >= 1.0
	if ready:
		var glow := 0.35 + 0.25 * sin(_pulse * 6.0) + _ult_flash
		_abilities.draw_circle(c, r + 8.0, Color(col, glow * 0.5))
	_abilities.draw_circle(c, r + 3.0, Color(0, 0, 0, 0.6))
	_abilities.draw_circle(c, r, Color(UI.INK, 0.9))
	if frac > 0.001:
		# filling pie
		var pts := PackedVector2Array([c])
		var steps := 40
		for i in steps + 1:
			var a := -PI * 0.5 + TAU * frac * float(i) / steps
			pts.append(c + Vector2(cos(a), sin(a)) * (r - 3.0))
		if pts.size() >= 3:
			_abilities.draw_colored_polygon(pts, Color(col, 0.55 if ready else 0.28))
	_abilities.draw_arc(c, r, 0, TAU, 48, Color(col, 0.9 if ready else 0.35), 3.0, true)
	Icons.draw_icon(_abilities, icon, c + Vector2(0, -4), r * 0.42, Color.WHITE if ready else Color(1, 1, 1, 0.55))
	var kw := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var kr := Rect2(c + Vector2(-kw * 0.5 - 6, r * 0.45), Vector2(kw + 12, 17))
	var ks := StyleBoxFlat.new()
	ks.bg_color = Color(0, 0, 0, 0.6)
	ks.set_corner_radius_all(5)
	ks.border_color = Color(col, 0.7)
	ks.set_border_width_all(1)
	_abilities.draw_style_box(ks, kr)
	_abilities.draw_string(font, Vector2(kr.position.x + 6, kr.position.y + 13), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var cw := font.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	_abilities.draw_string_outline(font, c + Vector2(-cw * 0.5, -r - 8), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color(0, 0, 0, 0.8))
	_abilities.draw_string(font, c + Vector2(-cw * 0.5, -r - 8), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col.lightened(0.3))


func combo_pop(n: int) -> void:
	_combo_card.pivot_offset = _combo_card.size * 0.5
	_combo_card.scale = Vector2.ONE * (1.25 + 0.05 * n)
	_combo_card.create_tween().tween_property(_combo_card, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func quest_started() -> void:
	_refresh_quest()
	UI.pop_in(_quest_card, 0.0, Vector2(30, 0), 0.4)


func ult_flash() -> void:
	_ult_flash = 1.0


func set_smog(v: float) -> void:
	_smog.color.a = v * 0.22
