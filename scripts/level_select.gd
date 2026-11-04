extends Control
## Direct access for prototyping. Levels are not locked.
const PAPER := Color("#f4efe3")
const INK := Color("#181410")
const TEAL := Color("#477e7b")
const COPPER := Color("#a16b49")
const DESTINATIONS := [
	"res://scenes/volta_level.tscn",
	"res://scenes/rhyme_level.tscn",
	"res://scenes/meter_level.tscn",
	"res://scenes/sonnet_player.tscn"
]
var body_font: Font
var display_font: Font
var hitboxes: Array[Rect2] = []
var back_rect := Rect2(90,620,220,55)

func _ready() -> void:
	body_font = load("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf")
	display_font = load("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf")
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _label(t: String, at: Vector2, font_size: int = 22, color: Color = INK, font: Font = null) -> void:
	draw_string(font if font != null else body_font,at,t,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PAPER)
	_label("In Countless Shadows",Vector2(90,110),40,INK,display_font)
	_label("Choose an experiment",Vector2(90,175),32)
	_label("Explore the four encounters in any order. No levels are locked.",Vector2(90,213),19,COPPER)
	hitboxes.clear()
	var titles := ["I. The Turn","II. The Echo","III. The Measure","IV. The Whole Sonnet"]
	var descriptions := ["Change the order of an argument","Discover relationships between endings","Experiment with rhythm and emphasis","Recompose the fourteen-line poem"]
	for i in range(4):
		var rect := Rect2(90,245+i*88,1000,76)
		hitboxes.append(rect)
		draw_rect(rect,Color("#fffaf1"))
		draw_rect(rect,Color(INK,0.22),false,1.0)
		_label(titles[i],rect.position+Vector2(22,31),24)
		_label(descriptions[i],rect.position+Vector2(22,57),18,COPPER)
	draw_rect(back_rect,TEAL)
	_label("Back to menu",back_rect.position+Vector2(20,35),22,PAPER)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var point := get_local_mouse_position()
	if back_rect.has_point(point):
		get_tree().change_scene_to_file("res://main.tscn")
		accept_event()
		return
	for i in range(hitboxes.size()):
		if hitboxes[i].has_point(point):
			get_tree().change_scene_to_file(DESTINATIONS[i])
			accept_event()
			return
