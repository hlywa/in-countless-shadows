extends Control
## First mechanical sketch: a letterpress-inspired sonnet compositor.
## All decorative marks are drawn in code; no image assets are required.

const PAPER := Color("#f4efe3")
const INK := Color("#25231f")
const FADED := Color("#8d8577")
const ACCENT := Color("#9c4a39")
const BLUE := Color("#426b83")
const LINES := [
	"Who will believe my verse in time to come,",
	"If it were fill'd with your most high deserts?",
	"Though yet heaven knows it is but as a tomb",
	"Which hides your life and shows not half your parts.",
	"If I could write the beauty of your eyes",
	"And in fresh numbers number all your graces,",
	"The age to come would say 'This poet lies;",
	"Such heavenly touches ne'er touch'd earthly faces.'",
	"So should my papers, yellow'd with their age,",
	"Be scorn'd, like old men of less truth than tongue,",
	"And your true rights be term'd a poet's rage",
	"And stretchèd meter of an antique song:",
	"But were some child of yours alive that time,",
	"You should live twice, in it and in my rhyme."
]
const RHYME := ["A", "B", "A", "B", "C", "D", "C", "D", "E", "F", "E", "F", "G", "G"]

var ink_font: Font
var show_meter := false
var stretch_open := false
var show_rhyme := false
var selected_line := 11
var impression := 0.0
var undo_stack: Array[Dictionary] = []
var click_regions: Array[Dictionary] = []

func _ready() -> void:
	ink_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _process(delta: float) -> void:
	if impression < 1.0:
		impression = minf(1.0, impression + delta * 1.7)
		queue_redraw()

func _draw() -> void:
	click_regions.clear()
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), PAPER)
	# Stable engraved ruling and registration marks.
	for i in range(0, int(s.y), 24):
		draw_line(Vector2(0, i), Vector2(s.x, i), Color(INK, 0.014), 1.0)
	var scale_factor := minf(s.x / 1280.0, s.y / 720.0)
	var sc := maxf(0.65, scale_factor)
	var ox := (s.x - 1280.0 * sc) * 0.5
	var oy := (s.y - 720.0 * sc) * 0.5
	draw_set_transform(Vector2(ox, oy), 0.0, Vector2(sc, sc))
	_draw_page()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_page() -> void:
	_print("IN COUNTLESS SHADOWS", Vector2(74, 65), 31, INK, 0.97)
	_print("A SONNET COMPOSITOR  /  EXPERIMENT 01", Vector2(77, 93), 13, FADED)
	draw_line(Vector2(75, 108), Vector2(1205, 108), Color(INK, 0.6), 1.5)
	_print("SONNET XVII", Vector2(76, 143), 18, INK)
	_print("Select a line. Expose the measure. Try stretching the type.", Vector2(76, 167), 15, FADED)
	for i in LINES.size():
		var y := 204.0 + i * 29.0 + float(i / 4) * 8.0
		if i >= 12:
			y += 11.0
		var selected := selected_line == i
		if selected:
			draw_rect(Rect2(72, y - 19, 800, 26), Color(ACCENT, 0.09))
			draw_line(Vector2(72, y + 8), Vector2(872, y + 8), Color(ACCENT, 0.38), 1)
		_print("%02d" % (i + 1), Vector2(78, y), 13, FADED)
		var displayed: String = LINES[i]
		if i == 11 and stretch_open:
			displayed = displayed.replace("stretchèd", "stretch  |  èd")
		_print(displayed, Vector2(117, y), 19, INK if not selected else ACCENT)
		if show_rhyme:
			_print(RHYME[i], Vector2(836, y), 14, BLUE)
		click_regions.append({"rect": Rect2(72, y - 20, 800, 28), "action": "line", "index": i})
		if show_meter and selected:
			for foot in 5:
				var fx := 903.0 + foot * 55.0
				draw_rect(Rect2(fx, y - 17, 49, 25), Color(ACCENT, 0.09), false, 1)
				_print("u /", Vector2(fx + 9, y), 14, ACCENT)
	if show_rhyme:
		_print("RHYME: ABAB  CDCD  EFEF  GG", Vector2(904, 210), 13, BLUE)
		_print("An echo across distant lines.", Vector2(904, 235), 13, FADED)
	_print("FORMAL PRESSURE", Vector2(903, 296), 15, INK)
	_print("Five iambic feet:  u /  × 5", Vector2(903, 320), 13, FADED)
	_print("The grid is an expectation,", Vector2(903, 350), 13, FADED)
	_print("not a verdict on the poem.", Vector2(903, 369), 13, FADED)
	if selected_line == 11:
		_print("Line 12: stretchèd", Vector2(903, 425), 16, ACCENT)
		_print("This word occupies two", Vector2(903, 449), 13, FADED)
		_print("syllabic positions.", Vector2(903, 467), 13, FADED)
		_button(Rect2(903, 483, 268, 36), "COMPRESS TYPE" if stretch_open else "STRETCH TYPE", "stretch")
	else:
		_print("Select line 12 to try", Vector2(903, 425), 14, FADED)
		_print("the first type operation.", Vector2(903, 445), 14, FADED)
	draw_line(Vector2(75, 660), Vector2(1205, 660), Color(INK, 0.4), 1)
	_button(Rect2(76, 674, 195, 34), "HIDE METER" if show_meter else "EXPOSE METER", "meter")
	_button(Rect2(281, 674, 195, 34), "HIDE RHYME" if show_rhyme else "SHOW RHYME", "rhyme")
	_button(Rect2(486, 674, 145, 34), "UNDO", "undo")
	_button(Rect2(641, 674, 145, 34), "RESET", "reset")
	_print("PROTOTYPE  /  NO SCORING OF MEANING", Vector2(907, 698), 12, FADED)

func _print(t: String, p: Vector2, font_size: int, color: Color, alpha := 1.0) -> void:
	# A subtle offset impression suggests uneven contact with paper.
	draw_string(ink_font, p + Vector2(0.6, 0.7), t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, 0.09 * impression))
	draw_string(ink_font, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, alpha * impression))

func _button(rect: Rect2, label: String, action: String) -> void:
	draw_rect(rect, Color(INK, 0.045))
	draw_rect(rect, Color(INK, 0.65), false, 1)
	_print(label, rect.position + Vector2(11, 23), 13, INK)
	click_regions.append({"rect": rect, "action": action})

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var sc := maxf(0.65, minf(size.x / 1280.0, size.y / 720.0))
		var local := (event.position - Vector2((size.x - 1280.0 * sc) * 0.5, (size.y - 720.0 * sc) * 0.5)) / sc
		for region in click_regions:
			if region.rect.has_point(local):
				_apply(region)
				accept_event()
				return

func _apply(region: Dictionary) -> void:
	var action: String = region.action
	if action == "undo":
		if not undo_stack.is_empty():
			var previous: Dictionary = undo_stack.pop_back()
			selected_line = previous.line
			show_meter = previous.meter
			show_rhyme = previous.rhyme
			stretch_open = previous.stretch
	elif action == "reset":
		_save_undo()
		selected_line = 11
		show_meter = false
		show_rhyme = false
		stretch_open = false
	else:
		_save_undo()
		match action:
			"line":
				selected_line = region.index
			"meter":
				show_meter = not show_meter
			"rhyme":
				show_rhyme = not show_rhyme
			"stretch":
				stretch_open = not stretch_open
	queue_redraw()

func _save_undo() -> void:
	undo_stack.append({"line": selected_line, "meter": show_meter, "rhyme": show_rhyme, "stretch": stretch_open})
	if undo_stack.size() > 60:
		undo_stack.pop_front()
