extends Control
## The existing Gothic font is revealed like ink absorbing into paper.
const REVEAL_DURATION := 2.1
const INK := Color("#181410")
var title_label: Label
var begin_label: Label
var settings_label: Label
var title_font: Font
var elapsed := 0.0

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
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	var buttons := smoothstep(1.35, 2.1, elapsed)
	begin_label.modulate.a = buttons
	settings_label.modulate.a = buttons
	if elapsed <= REVEAL_DURATION:
		queue_redraw()

func _draw() -> void:
	if title_font == null:
		return
	var font_size := title_label.get_theme_font_size("font_size")
	var title := title_label.text
	var width := title_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var baseline := title_label.position + Vector2(maxf(0.0,(title_label.size.x-width)*0.5),float(font_size)*0.95)
	# Fixed letterforms, never flying fragments. Three passes create a soft
	# absorption effect while retaining the exact glyph shapes of the font.
	var t := smoothstep(0.0, REVEAL_DURATION, elapsed)
	var haze := Color(INK,0.12 * (1.0-t))
	draw_string(title_font,baseline+Vector2(0.7,0.6),title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,haze)
	draw_string(title_font,baseline,title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(INK,0.12+0.88*t))
	# A narrow irregular reveal front moves through the already-positioned type.
	# Draw each glyph in place with its own slight absorption delay.
	var x := baseline.x
	for i in range(title.length()):
		var glyph := title.substr(i,1)
		var advance := title_font.get_string_size(glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var offset := float(i) / maxf(1.0,float(title.length()-1))
		var local_t := smoothstep(offset*0.72,offset*0.72+0.55,elapsed/REVEAL_DURATION)
		draw_string(title_font,Vector2(x,baseline.y),glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(INK,local_t*0.35))
		x += advance

func _on_begin_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://scenes/sonnet_player.tscn")
