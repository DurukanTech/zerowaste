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
	add_child(UI.dim(0.55))
	var center := UI.centered()
	add_child(center)
	var p := UI.panel()
	center.add_child(p)
	var vb := UI.vbox(14)
	p.add_child(vb)
	var title := UI.label(Loc.t("paused"), 46, Color(1, 0.9, 0.35), 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	# build overview
	var lines := []
	for w in game.player.weapons:
		lines.append("• %s  %s %d" % [Loc.pick(GameData.WEAPONS[w.id].name), Loc.t("lv"), w.level])
	for id in game.player.passives:
		lines.append("• %s  %s %d" % [Loc.pick(GameData.PASSIVES[id].name), Loc.t("lv"), game.player.passives[id]])
	vb.add_child(UI.label(Loc.t("build") + ":", 20, Color(0.6, 0.95, 1.0), 0))
	vb.add_child(UI.label("\n".join(lines), 18, Color.WHITE, 0))
	var resume := UI.button(Loc.t("resume"))
	resume.pressed.connect(_close)
	vb.add_child(resume)
	var lang := UI.button(Loc.t("language"), 22, Color(0.2, 0.4, 0.6))
	lang.pressed.connect(Loc.toggle)
	vb.add_child(lang)
	var menu := UI.button(Loc.t("main_menu"), 22, Color(0.5, 0.25, 0.2))
	menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	vb.add_child(menu)
	resume.grab_focus.call_deferred()
