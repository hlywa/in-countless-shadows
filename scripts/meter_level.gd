extends Control
## An exploratory visual pulse, not an authoritative recitation.
const PAPER := Color("#f4efe3")
const INK := Color("#181410")
const TEAL := Color("#477e7b")
const COPPER := Color("#a16b49")
var level: Dictionary = {}
var body_font: Font
var display_font: Font
var reading_index := 0
var playing := false
var pulse_clock := 0.0
var pulse_index := 0
var explored := false
var readings: Array = []
var choice_rects: Array[Rect2] = []
var play_rect := Rect2(90,570,230,55)
var next_rect := Rect2(885,570,300,55)
var pulse_rects: Array[Rect2] = []

func _ready() -> void:
	level = PuzzleLevels.get_level("sonnet17_measure")
	readings = level["readings"]
	body_font = load("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") if ResourceLoader.exists("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") else ThemeDB.fallback_font
	display_font = load("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") if ResourceLoader.exists("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") else body_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(true)

func _process(delta: float) -> void:
	if not playing:
		return
	pulse_clock += delta
	if pulse_clock >= 0.38:
		pulse_clock -= 0.38
		pulse_index += 1
		var reading: Dictionary = PuzzleLevels.meter_reading(readings[reading_index]["words"])
		if pulse_index >= int(reading["syllables"]):
			playing = false
			pulse_index = -1
		queue_redraw()

func _label(t: String, at: Vector2, font_size: int = 20, color: Color = INK, font: Font = null, width: float = -1.0) -> void:
	draw_string(font if font != null else body_font,at,t,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PAPER)
	_label("In Countless Shadows",Vector2(90,95),39,INK,display_font)
	_label(str(level["title"]),Vector2(90,150),27)
	_label(str(level["subtitle"]),Vector2(90,184),20,COPPER)
	_label(str(level["instruction"]),Vector2(90,229),20)
	_label("The pulse below is a visual counting aid, not a prescribed performance.",Vector2(90,258),17,Color(INK,0.65))
	choice_rects.clear()
	for i in range(readings.size()):
		var rect := Rect2(90+i*395,295,375,60)
		choice_rects.append(rect)
		draw_rect(rect,Color(TEAL,0.12) if reading_index == i else Color("#fffaf1"))
		draw_rect(rect,TEAL if reading_index == i else Color(INK,0.22),false,2.0 if reading_index == i else 1.0)
		_label("Reading %d" % (i+1),rect.position+Vector2(20,37),22)
	var words: Array = readings[reading_index]["words"]
	var result: Dictionary = PuzzleLevels.meter_reading(words)
	_label(str(readings[reading_index]["text"]),Vector2(90,413),25,INK,body_font,1080)
	_label("%d syllable positions (editorial estimate)" % int(result["syllables"]),Vector2(90,461),19,TEAL)
	if int(result["unknown_words"]) > 0:
		_label("%d words lack recorded syllable evidence." % int(result["unknown_words"]),Vector2(90,486),17,COPPER)
	else:
		_label("Recorded syllable counts; stress remains interpretive.",Vector2(90,486),17,COPPER)
	pulse_rects.clear()
	var slots: Array = result["slots"]
	var count: int = slots.size()
	var step := minf(80.0,1000.0 / maxf(1.0,float(count)))
	for i in range(count):
		var rect := Rect2(90+i*step,515,step-8,24)
		pulse_rects.append(rect)
		var strong := i % 2 == 1
		draw_rect(rect,TEAL if playing and pulse_index == i else Color(COPPER,0.45) if strong else Color(INK,0.12))
	_label("Alternating positions suggest a pattern; actual speech can depart from it.",Vector2(90,558),15,Color(INK,0.7))
	draw_rect(play_rect,TEAL)
	_label("Pause" if playing else "Play visual pulse",play_rect.position+Vector2(18,35),20,PAPER)
	if explored:
		draw_rect(next_rect,TEAL)
		_label("Explore the whole sonnet",next_rect.position+Vector2(16,35),20,PAPER,body_font,275)
	else:
		_label("Try the pulse to continue",Vector2(885,604),18,COPPER)
	_label("No audio or automatic scansion is implied.",Vector2(90,683),16,Color(INK,0.65))

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var point := get_local_mouse_position()
	if explored and next_rect.has_point(point):
		get_tree().change_scene_to_file("res://scenes/sonnet_player.tscn")
		accept_event()
		return
	if play_rect.has_point(point):
		playing = not playing
		if playing:
			pulse_clock = 0.0
			pulse_index = 0
			explored = true
		queue_redraw()
		accept_event()
		return
	for i in range(choice_rects.size()):
		if choice_rects[i].has_point(point):
			reading_index = i
			playing = false
			pulse_index = -1
			queue_redraw()
			accept_event()
			return
