extends Control
## The title assembles as movable type; the sonnet subsequently disassembles.
const ARRIVAL_DURATION := 3.8
const PAPER := Color("#f4efe3")
const INK := Color("#181410")
var title_label: Label
var begin_label: Label
var settings_label: Label
var title_font: Font
var fragments: Array[Dictionary] = []
var elapsed := 0.0
var settling := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	title_label = get_node("Title") as Label
	begin_label = get_node("StartButton") as Label
	settings_label = get_node("SettingsButton") as Label
	title_font = title_label.get_theme_font("font")
	title_label.visible = false
	begin_label.modulate.a = 0.0
	settings_label.modulate.a = 0.0
	begin_label.mouse_filter = Control.MOUSE_FILTER_STOP
	begin_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	begin_label.gui_input.connect(_on_begin_input)
	_build_fragments()
	queue_redraw()

func _build_fragments() -> void:
	fragments.clear()
	var words := ["IN", "COUNTLESS", "SHADOWS"]
	var font_size := 72
	var full_width := title_font.get_string_size("IN COUNTLESS SHADOWS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x := title_label.position.x + maxf(0.0, (title_label.size.x - full_width) * 0.5)
	var baseline := title_label.position.y + 75.0
	var space := title_font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	for i in range(words.size()):
		var word: String = words[i]
		var width := title_font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var target := Vector2(x, baseline)
		var origin := Vector2(-width - 70.0, -70.0) if i == 0 else (Vector2(size.x + 90.0, baseline - 170.0) if i == 1 else Vector2(size.x + 100.0, size.y + 100.0))
		fragments.append({"word":word, "target":target, "origin":origin, "delay":float(i) * 0.32})
		x += width + space

func _process(delta: float) -> void:
	elapsed += delta
	var fraction := clampf((elapsed - 2.9) / 0.9, 0.0, 1.0)
	begin_label.modulate.a = fraction
	settings_label.modulate.a = fraction
	if elapsed < ARRIVAL_DURATION:
		queue_redraw()
	elif not settling:
		settling = true
		queue_redraw()

func _draw() -> void:
	if title_font == null:
		return
	for fragment in fragments:
		var delay: float = fragment["delay"]
		var t := clampf((elapsed - delay) / maxf(0.1, ARRIVAL_DURATION - delay), 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		var origin: Vector2 = fragment["origin"]
		var target: Vector2 = fragment["target"]
		var pos := origin.lerp(target, t)
		var lift := sin(t * PI) * 22.0
		draw_string(title_font, pos + Vector2(0.0, -lift), str(fragment["word"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 72, INK)

func _on_begin_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://scenes/sonnet_player.tscn")
