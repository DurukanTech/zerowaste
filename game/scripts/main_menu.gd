extends Control
## Title screen.

const UI = preload("res://scripts/ui/ui_kit.gd")

var _how_open := false
var _t := 0.0
var _floaters: Array[ColorRect] = []


func _ready() -> void:
	get_tree().paused = false
	Loc.language_changed.connect(_build)
	_build()


func _process(delta: float) -> void:
	_t += delta
	_maybe_screenshot()
	for i in _floaters.size():
		var f := _floaters[i]
		f.position.y -= delta * (20.0 + i * 3.0)
		f.rotation = _t * 0.5 + i
		if f.position.y < -60:
			f.position = Vector2(randf() * size.x, size.y + 40)


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_floaters.clear()
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.2, 0.22)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# floating material shapes in the background
	var vp := get_viewport_rect().size
	for i in 18:
		var t: String = GameData.BIN_TYPES[i % 4]
		var f := ColorRect.new()
		f.color = GameData.MATERIALS[t].color
		f.size = Vector2.ONE * (18 + (i % 3) * 12)
		f.pivot_offset = f.size * 0.5
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.modulate.a = 0.3
		f.position = Vector2(randf() * vp.x, randf() * vp.y)
		add_child(f)
		_floaters.append(f)

	var center := UI.centered()
	add_child(center)
	var vb := UI.vbox(16)
	center.add_child(vb)

	if _how_open:
		var p := UI.panel()
		vb.add_child(p)
		var inner := UI.vbox(16)
		p.add_child(inner)
		inner.add_child(UI.label(Loc.t("how_to"), 40, Color(1, 0.9, 0.35), 8))
		inner.add_child(UI.label(Loc.t("how_text"), 20, Color.WHITE, 0))
		var back := UI.button(Loc.t("back"))
		back.pressed.connect(func():
			_how_open = false
			_build())
		inner.add_child(back)
		back.grab_focus.call_deferred()
		return

	var title := UI.label(Loc.t("title"), 76, Color(0.55, 1.0, 0.65), 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := UI.label(Loc.t("subtitle"), 24, Color(1, 0.9, 0.4), 6)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var tag := UI.label(Loc.t("tagline"), 20, Color(0.85, 0.95, 0.95), 4)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tag)

	# bin color legend
	var legend := UI.hbox(22)
	for t in GameData.BIN_TYPES:
		var row := UI.hbox(6)
		var sw := ColorRect.new()
		sw.color = GameData.MATERIALS[t].color
		sw.custom_minimum_size = Vector2(22, 22)
		row.add_child(sw)
		row.add_child(UI.label(Loc.pick(GameData.MATERIALS[t].name), 18, Color.WHITE, 4))
		legend.add_child(row)
	vb.add_child(legend)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 16
	vb.add_child(spacer)

	var play := UI.button(Loc.t("play"), 30)
	play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game.tscn"))
	vb.add_child(_center_wrap(play))
	var how := UI.button(Loc.t("how_to"), 24, Color(0.2, 0.4, 0.6))
	how.pressed.connect(func():
		_how_open = true
		_build())
	vb.add_child(_center_wrap(how))
	var lang := UI.button(Loc.t("language"), 22, Color(0.25, 0.3, 0.45))
	lang.pressed.connect(Loc.toggle)
	vb.add_child(_center_wrap(lang))
	if not OS.has_feature("web"):
		var quit := UI.button(Loc.t("quit"), 22, Color(0.5, 0.25, 0.2))
		quit.pressed.connect(func(): get_tree().quit())
		vb.add_child(_center_wrap(quit))

	var credits := UI.label(Loc.t("credits"), 14, Color(0.6, 0.75, 0.75), 0)
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(credits)
	play.grab_focus.call_deferred()


## Test hook: `-- --shots=<dir>` saves the menu and quits.
func _maybe_screenshot() -> void:
	if _t < 1.0 or _t - get_process_delta_time() >= 1.0:
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			get_viewport().get_texture().get_image().save_png(a.substr(8).path_join("menu.png"))
			get_tree().quit()


func _center_wrap(c: Control) -> Control:
	var w := CenterContainer.new()
	w.add_child(c)
	return w
