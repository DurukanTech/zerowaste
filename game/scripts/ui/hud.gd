extends CanvasLayer
## In-run HUD: bars, timer, carried materials, buffs, boss bar, toasts, bin arrows.

const UI = preload("res://scripts/ui/ui_kit.gd")

var game

var _root: Control
var _xp_fill: ColorRect
var _hp_fill: ColorRect
var _hp_label: Label
var _lvl_label: Label
var _time_label: Label
var _kill_label: Label
var _mat_labels := {}
var _buff_label: Label
var _boss_box: Control
var _boss_fill: ColorRect
var _boss_name: Label
var _boss = null
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _banner: Label
var _banner_tween: Tween
var _overlay: Control
var _pulse := 0.0


func _ready() -> void:
	layer = 1
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	_root.add_child(_overlay)

	# XP bar across the top
	var xp_bg := _bar_bg(Color(0.05, 0.1, 0.12, 0.85))
	xp_bg.anchor_right = 1.0
	xp_bg.offset_bottom = 14
	_root.add_child(xp_bg)
	_xp_fill = _bar_fill(xp_bg, Color(0.35, 0.85, 1.0))

	# HP bar
	var hp_bg := _bar_bg(Color(0.1, 0.05, 0.05, 0.85))
	hp_bg.position = Vector2(16, 24)
	hp_bg.size = Vector2(280, 24)
	_root.add_child(hp_bg)
	_hp_fill = _bar_fill(hp_bg, Color(0.9, 0.25, 0.25))
	_hp_label = UI.label("", 16)
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_bg.add_child(_hp_label)

	_lvl_label = UI.label("", 24, Color(0.6, 0.95, 1.0))
	_lvl_label.position = Vector2(308, 20)
	_root.add_child(_lvl_label)

	_time_label = UI.label("00:00", 40)
	_time_label.anchor_right = 1.0
	_time_label.offset_top = 18
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_time_label)

	_kill_label = UI.label("", 22)
	_kill_label.anchor_left = 1.0
	_kill_label.anchor_right = 1.0
	_kill_label.offset_left = -360
	_kill_label.offset_right = -18
	_kill_label.offset_top = 22
	_kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_kill_label)

	# carried materials
	var mats := UI.panel(Color(0.03, 0.12, 0.12, 0.7), 12)
	mats.position = Vector2(16, 60)
	_root.add_child(mats)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 4)
	mats.add_child(mv)
	for t in GameData.BIN_TYPES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var sw := ColorRect.new()
		sw.color = GameData.MATERIALS[t].color
		sw.custom_minimum_size = Vector2(18, 18)
		row.add_child(sw)
		var l := UI.label("", 18, Color.WHITE, 4)
		l.custom_minimum_size.x = 150
		row.add_child(l)
		mv.add_child(row)
		_mat_labels[t] = l

	_buff_label = UI.label("", 18, Color(1, 0.95, 0.6), 5)
	_buff_label.position = Vector2(18, 210)
	_root.add_child(_buff_label)

	# boss bar
	_boss_box = Control.new()
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.offset_left = -300
	_boss_box.offset_right = 300
	_boss_box.offset_top = 96
	_boss_box.offset_bottom = 120
	_boss_box.visible = false
	_root.add_child(_boss_box)
	var bb := _bar_bg(Color(0.1, 0.02, 0.05, 0.9))
	bb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boss_box.add_child(bb)
	_boss_fill = _bar_fill(bb, Color(0.75, 0.2, 0.75))
	_boss_name = UI.label("", 22, Color(1, 0.85, 0.3))
	_boss_name.anchor_right = 1.0
	_boss_name.offset_top = -30
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_name)

	# toast (bottom)
	_toast = UI.panel(Color(0.03, 0.12, 0.12, 0.88), 14)
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_left = -400
	_toast.offset_right = 400
	_toast.offset_top = -150
	_toast.offset_bottom = -24
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast)
	_toast_label = UI.wrap_label("", 19, Color.WHITE, 720)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast.add_child(_toast_label)

	# center banner
	_banner = UI.label("", 46, Color.WHITE, 10)
	_banner.anchor_top = 0.28
	_banner.anchor_bottom = 0.28
	_banner.anchor_right = 1.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	_root.add_child(_banner)


func _bar_bg(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _bar_fill(parent: Control, c: Color) -> ColorRect:
	var f := ColorRect.new()
	f.color = c
	f.anchor_bottom = 1.0
	f.anchor_right = 0.0
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(f)
	return f


func refresh(delta: float) -> void:
	_pulse += delta
	var p = game.player
	_xp_fill.anchor_right = clampf(p.xp / p.xp_need, 0.0, 1.0)
	_hp_fill.anchor_right = clampf(p.hp / p.max_hp, 0.0, 1.0)
	_hp_label.text = "%s %d / %d" % [Loc.t("hp"), ceili(p.hp), int(p.max_hp)]
	_lvl_label.text = "%s %d" % [Loc.t("lv"), p.level]
	_time_label.text = UI.fmt_time(game.elapsed)
	_kill_label.text = "%s: %d" % [Loc.t("kills"), game.kills]
	for t in GameData.BIN_TYPES:
		var n: int = game.carried[t]
		var l: Label = _mat_labels[t]
		var full: bool = n >= GameData.CARRY_CAP
		l.text = "%s  %d/%d%s" % [Loc.pick(GameData.MATERIALS[t].name), n, GameData.CARRY_CAP, ("  " + Loc.t("full")) if full else ""]
		l.modulate = Color(1, 0.6, 0.5) if full and int(_pulse * 4.0) % 2 == 0 else Color.WHITE
	var lines := []
	for b in p.buffs:
		lines.append("+ %s  %ds" % [Loc.t("buff_" + b), ceili(p.buffs[b])])
	_buff_label.text = "\n".join(lines)
	if _boss != null:
		if is_instance_valid(_boss) and not _boss.dead:
			_boss_fill.anchor_right = clampf(_boss.hp / _boss.max_hp, 0.0, 1.0)
		else:
			set_boss(null)
	_overlay.queue_redraw()


func set_boss(b) -> void:
	_boss = b
	_boss_box.visible = b != null
	if b != null:
		_boss_name.text = Loc.pick(GameData.ENEMIES[b.kind].name)


func toast(text: String, color := Color.WHITE) -> void:
	_toast_label.text = text
	var s: StyleBoxFlat = _toast.get_theme_stylebox("panel").duplicate()
	s.border_color = color
	s.set_border_width_all(3)
	_toast.add_theme_stylebox_override("panel", s)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(6.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func banner(text: String, color := Color.WHITE) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(2.2)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


## Edge-of-screen arrows pointing to bins, with carried counts.
func _draw_overlay() -> void:
	if game == null or game.camera == null:
		return
	var cam: Camera3D = game.camera
	var size := _overlay.size
	var center := size * 0.5
	var font := ThemeDB.fallback_font
	var margin := 44.0
	for b in game.bins:
		var t: String = b.mat_type
		var col: Color = GameData.MATERIALS[t].color
		var n: int = game.carried[t]
		var wp: Vector3 = b.position + Vector3(0, 1.0, 0)
		var behind := cam.is_position_behind(wp)
		var sp := cam.unproject_position(wp)
		var inner := Rect2(Vector2.ZERO, size).grow(-margin)
		if not behind and inner.has_point(sp):
			if n > 0:
				var bp := sp + Vector2(0, -110)
				var r := 20.0 + sin(_pulse * 6.0) * 3.0
				_overlay.draw_circle(bp, r + 3, Color(0, 0, 0, 0.6))
				_overlay.draw_circle(bp, r, col)
				_overlay.draw_string(font, bp + Vector2(-30, 7), str(n), HORIZONTAL_ALIGNMENT_CENTER, 60, 20, Color.WHITE)
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
		var alpha := 1.0 if n > 0 else 0.55
		var c := Color(col.r, col.g, col.b, alpha)
		var side := dir.orthogonal() * 11.0
		_overlay.draw_colored_polygon(PackedVector2Array([pos + dir * 36.0, pos + dir * 20.0 + side, pos + dir * 20.0 - side]), c)
		_overlay.draw_circle(pos, 22.0, Color(0, 0, 0, 0.55 * alpha))
		_overlay.draw_circle(pos, 18.0, c)
		if n > 0:
			_overlay.draw_string(font, pos + Vector2(-30, 7), str(n), HORIZONTAL_ALIGNMENT_CENTER, 60, 19, Color.WHITE)
