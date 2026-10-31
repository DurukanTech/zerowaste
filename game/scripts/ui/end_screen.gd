extends CanvasLayer
## Victory / defeat screen with recycling stats and a closing fact.

const UI = preload("res://scripts/ui/ui_kit.gd")


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_result(win: bool, stats: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	add_child(UI.dim(0.7))
	var center := UI.centered()
	add_child(center)
	var p := UI.panel()
	center.add_child(p)
	var vb := UI.vbox(12)
	p.add_child(vb)

	var title := UI.label(Loc.t("victory") if win else Loc.t("defeat"), 58, Color(0.5, 1.0, 0.6) if win else Color(1.0, 0.5, 0.4), 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := UI.wrap_label(Loc.t("win_text") if win else Loc.t("lose_text"), 20, Color(0.9, 0.95, 0.95), 620)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	vb.add_child(grid)
	var total_sorted := 0
	var total_collected := 0
	for t in GameData.BIN_TYPES:
		total_sorted += int(stats.recycled[t])
		total_collected += int(stats.collected[t])
	_row(grid, Loc.t("time"), UI.fmt_time(stats.time))
	_row(grid, Loc.t("level"), str(stats.level))
	_row(grid, Loc.t("kills"), str(stats.kills))
	_row(grid, Loc.t("collected"), str(total_collected))
	_row(grid, Loc.t("recycled"), "%d  (%d%%)" % [total_sorted, int(100.0 * total_sorted / maxf(1.0, total_collected))], Color(0.6, 1, 0.6))
	_row(grid, Loc.t("ewaste_collected"), str(stats.collected.ewaste))

	var per := UI.hbox(18)
	for t in GameData.BIN_TYPES:
		var l := UI.label("%s: %d" % [Loc.pick(GameData.MATERIALS[t].name), stats.recycled[t]], 18, GameData.MATERIALS[t].color, 4)
		per.add_child(l)
	vb.add_child(per)

	vb.add_child(UI.label(Loc.t("did_you_know"), 18, Color(1, 0.9, 0.4), 0))
	var fact := UI.wrap_label(GameData.random_fact(), 17, Color(0.85, 0.9, 0.9), 620)
	fact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(fact)

	var btns := UI.hbox(16)
	vb.add_child(btns)
	var retry := UI.button(Loc.t("retry"), 24, UI.GREEN, Vector2(260, 56))
	retry.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	btns.add_child(retry)
	var menu := UI.button(Loc.t("main_menu"), 24, Color(0.2, 0.4, 0.6), Vector2(260, 56))
	menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	btns.add_child(menu)
	retry.grab_focus.call_deferred()


func _row(grid: GridContainer, k: String, v: String, color := Color.WHITE) -> void:
	grid.add_child(UI.label(k, 20, Color(0.75, 0.85, 0.85), 0))
	grid.add_child(UI.label(v, 20, color, 0))
