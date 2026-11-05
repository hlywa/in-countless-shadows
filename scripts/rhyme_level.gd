extends Control
## A two-ending puzzle: a rhyme is a relationship, not a beauty score.
const PAPER := Color("#f4efe3")
const INK := Color("#181410")
const TEAL := Color("#477e7b")
const COPPER := Color("#a16b49")
var level: Dictionary = {}
var body_font: Font
var display_font: Font
var selected: Array = ["",""]
var active_slot := 0
var completed := false
var discovered_once := false
var choice_rects: Array[Rect2] = []
var continue_rect := Rect2(900,580,260,58)
var reset_rect := Rect2(900,510,260,45)

func _ready() -> void:
	level = PuzzleLevels.get_level("sonnet17_rhyme")
	body_font = load("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") if ResourceLoader.exists("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") else ThemeDB.fallback_font
	display_font = load("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") if ResourceLoader.exists("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") else body_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _label(t: String, at: Vector2, font_size: int = 20, color: Color = INK, font: Font = null, max_width: float = -1.0) -> void:
	draw_string(font if font != null else body_font,at,t,HORIZONTAL_ALIGNMENT_LEFT,max_width,font_size,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PAPER)
	_label("In Countless Shadows",Vector2(90,95),39,INK,display_font)
	_label(str(level["title"]),Vector2(90,150),27)
	_label(str(level["subtitle"]),Vector2(90,184),20,COPPER)
	_label(str(level["instruction"]),Vector2(90,229),20)
	_label("Select a line, then choose its ending.",Vector2(90,260),17,Color(INK,0.65))
	for i in range(2):
		var rect := Rect2(90,290+i*105,770,85)
		draw_rect(rect,Color(TEAL,0.10) if active_slot == i else Color("#fffaf1"))
		draw_rect(rect,TEAL if active_slot == i else Color(INK,0.2),false,2.0 if active_slot == i else 1.0)
		var stem := str(level["first_stem"]) if i == 0 else str(level["second_stem"])
		_label(stem,rect.position+Vector2(15,37),21,INK,body_font,690)
		_label(str(selected[i]) if not str(selected[i]).is_empty() else "[ choose an ending ]",rect.position+Vector2(20,67),20,TEAL if not str(selected[i]).is_empty() else COPPER)
	_label("AVAILABLE ENDINGS",Vector2(90,519),17,INK)
	choice_rects.clear()
	for j in range(level["choices"].size()):
		var rect := Rect2(90+(j%3)*255,540+int(j/3)*64,238,52)
		choice_rects.append(rect)
		draw_rect(rect,Color("#fffaf1"))
		draw_rect(rect,Color(INK,0.28),false,1.0)
		_label(str(level["choices"][j]),rect.position+Vector2(20,34),23,TEAL if str(level["choices"][j]) in selected else INK)
	draw_line(Vector2(884,280),Vector2(884,670),Color(INK,0.2))
	_label("LISTEN FOR THE ECHO",Vector2(900,318),18)
	var evaluation: Dictionary = PuzzleLevels.rhyme_evaluation(level,selected)
	_label(str(evaluation["heading"]),Vector2(900,363),18,TEAL if completed else INK,body_font,260)
	_label(str(evaluation["detail"]),Vector2(900,396),16,INK,body_font,260)
	if completed:
		if bool(evaluation.get("original",false)):
			_label("Shakespeare's original pair.",Vector2(900,436),16,COPPER,body_font,260)
		else:
			_label("A new rhyme, not the original.",Vector2(900,436),16,COPPER,body_font,260)
		_label("How has the meaning changed?",Vector2(900,462),16,INK,body_font,260)
	elif discovered_once:
		_label("Try another combination.",Vector2(900,442),16,COPPER,body_font,260)
	draw_rect(reset_rect,Color("#fffaf1"))
	draw_rect(reset_rect,Color(INK,0.28),false)
	_label("Reset endings",reset_rect.position+Vector2(15,29),19)
	if discovered_once:
		draw_rect(continue_rect,TEAL)
		_label("Continue to rhythm",continue_rect.position+Vector2(10,35),19,PAPER,body_font,245)
	_label("Sonnet 17 · Shakespeare",Vector2(90,683),16,Color(INK,0.6))

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var point := get_local_mouse_position()
	if reset_rect.has_point(point):
		selected = ["",""]
		active_slot = 0
		completed = false
	elif discovered_once and continue_rect.has_point(point):
		get_tree().change_scene_to_file("res://scenes/meter_level.tscn")
		accept_event()
		return
	elif Rect2(90,290,770,85).has_point(point):
		active_slot = 0
	elif Rect2(90,395,770,85).has_point(point):
		active_slot = 1
	else:
		for j in range(choice_rects.size()):
			if choice_rects[j].has_point(point):
				var word: String = str(level["choices"][j])
				# Do not duplicate one physical word token in both positions.
				var other: int = 1 - active_slot
				if selected[other] == word:
					selected[other] = ""
				selected[active_slot] = word
				completed = PuzzleLevels.rhyme_match(level,selected)
				if completed:
					discovered_once = true
				if active_slot == 0:
					active_slot = 1
				break
	queue_redraw()
	accept_event()
