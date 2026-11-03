extends Control
## Volta-first teaching encounter. The rule tests a relationship, not beauty.
const PAPER := Color("#f4efe3")
const INK := Color("#181410")
const TEAL := Color("#477e7b")
const COPPER := Color("#a16b49")
const OXBLOOD := Color("#a4484d")
var level: Dictionary = {}
var order: Array = []
var selected := -1
var discovered := false
var revealed := false
var body_font: Font
var display_font: Font
var slots: Array[Rect2] = []
var next_button := Rect2(925,605,220,52)
var reset_button := Rect2(925,535,220,44)

func _ready() -> void:
	body_font = load("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") if ResourceLoader.exists("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") else ThemeDB.fallback_font
	display_font = load("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") if ResourceLoader.exists("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") else body_font
	level = PuzzleLevels.get_level("sonnet17_turn")
	order = level["initial_order"].duplicate()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _unit(id: String) -> Dictionary:
	for unit in level["units"]:
		if str(unit["id"]) == id:
			return unit
	return {}

func _label(text: String, pos: Vector2, size: int = 20, color: Color = INK, font: Font = null, width: float = -1.0) -> void:
	draw_string(font if font != null else body_font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,width,size,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PAPER)
	_label("In Countless Shadows",Vector2(90,95),39,INK,display_font)
	_label(str(level["title"]),Vector2(90,150),27,INK)
	_label(str(level["subtitle"]),Vector2(90,184),20,COPPER)
	_label(str(level["instruction"]),Vector2(90,229),20,INK)
	_label("Select a passage, then select another to exchange their positions.",Vector2(90,258),16,Color(INK,0.68))
	slots.clear()
	for i in range(order.size()):
		var rect := Rect2(90,290+i*115,775,100)
		slots.append(rect)
		draw_rect(rect,Color(TEAL,0.12) if selected == i else Color("#fffaf1"))
		draw_rect(rect,TEAL if selected == i else Color(INK,0.22),false,2.0 if selected == i else 1.0)
		var unit := _unit(str(order[i]))
		_label("%d  ·  %s" % [i+1,str(unit["label"])],rect.position+Vector2(18,26),16,COPPER)
		var lines: PackedStringArray = str(unit["text"]).split("\n")
		for j in range(lines.size()):
			_label(lines[j],rect.position+Vector2(18,55+j*25),21,INK,body_font,730)
	draw_line(Vector2(895,280),Vector2(895,675),Color(INK,0.22),1.0)
	_label("WHAT CHANGED?",Vector2(925,317),19,INK)
	if discovered:
		_label("You made a turn.",Vector2(925,357),20,TEAL)
		_label("The doubt is answered",Vector2(925,390),17,INK)
		_label("by a possibility.",Vector2(925,413),17,INK)
		_label("This is a volta:",Vector2(925,451),17,COPPER)
		_label("a change in thought.",Vector2(925,475),17,COPPER)
	else:
		_label("Try changing the order.",Vector2(925,357),18,INK)
		_label("What becomes a response?",Vector2(925,388),17,INK)
		_label("What becomes a premise?",Vector2(925,412),17,INK)
	draw_rect(reset_button,Color("#fffaf1"))
	draw_rect(reset_button,Color(INK,0.3),false,1.0)
	_label("Reset arrangement",reset_button.position+Vector2(15,29),18,INK)
	if discovered:
		draw_rect(next_button,TEAL)
		_label("Explore the whole sonnet",next_button.position+Vector2(12,32),18,PAPER)
	else:
		_label("Discover a turn to continue",Vector2(925,640),16,Color(INK,0.6),body_font,225)
	_label("Sonnet 17  ·  Shakespeare",Vector2(90,683),16,Color(INK,0.6))

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var point := get_local_mouse_position()
	if reset_button.has_point(point):
		order = level["initial_order"].duplicate()
		selected = -1
		discovered = false
		queue_redraw()
		accept_event()
		return
	if discovered and next_button.has_point(point):
		get_tree().change_scene_to_file("res://scenes/sonnet_player.tscn")
		accept_event()
		return
	for i in range(slots.size()):
		if slots[i].has_point(point):
			if selected == -1:
				selected = i
			elif selected == i:
				selected = -1
			else:
				var previous: String = order[selected]
				order[selected] = order[i]
				order[i] = previous
				selected = -1
				discovered = PuzzleLevels.discovered_turn(level,order)
			queue_redraw()
			accept_event()
			return
