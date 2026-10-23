extends Control
## Integrated Sonnet 17 movable-type compositor.
## All fourteen lines are available; select a line to rearrange its individual words.
## The measure is a guide, not an automated scansion verdict.

const PAPER := Color("#f4efe3")
const INK := Color("#25231f")
const FADED := Color("#82776b")
const ACCENT := Color("#9c4a39")
const BLUE := Color("#426b83")
const RHYME := ["A","B","A","B","C","D","C","D","E","F","E","F","G","G"]
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
const FRAME := Rect2(590, 265, 610, 178)
const TRAY := Rect2(590, 468, 610, 138)
const SLOT_WIDTH := 55.0
const SLOT_X := 612.0
const MULTISYLLABLE := {
"believe":2,"verse":1,"time":1,"come":1,"fill'd":1,"deserts":2,"heaven":2,
"beauty":2,"numbers":2,"number":2,"graces":2,"poet":2,"heavenly":3,
"earthly":2,"faces":2,"papers":2,"yellow'd":2,"scorn'd":1,"antique":2,
"stretchèd":2,"meter":2,"child":1,"alive":2,"rhyme":1,"touches":2,
"less":1,"should":1,"your":1,"were":1,"age":1,"old":1,"tongue":1
}
var font_body: Font
var font_title: Font
var selected_line := 11
var show_meter := true
var show_rhyme := true
var stretch_open := false
var shadow_trace: Array[String] = []
var arrangements: Array = []
var placed: Array[int] = []
var regions: Array[Dictionary] = []
var drag_id := -1
var drag_at := Vector2.ZERO
var drag_offset := Vector2.ZERO
var printed := false
var printed_text := ""
var message := "Drag words from the tray into the forme."
var history: Array[Dictionary] = []

func _ready() -> void:
	font_body = load("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") if ResourceLoader.exists("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") else ThemeDB.fallback_font
	font_title = load("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") if ResourceLoader.exists("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") else font_body
	for line in LINES:
		arrangements.append([])
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _words() -> PackedStringArray:
	return LINES[selected_line].split(" ", false)

func _syllables(word: String) -> int:
	var clean := word.to_lower().strip_edges().trim_prefix("'").trim_suffix(".").trim_suffix(",").trim_suffix(":").trim_suffix(";").trim_suffix("?").trim_suffix("'")
	return int(MULTISYLLABLE.get(clean, 1))

func _used() -> int:
	var count := 0
	var words := _words()
	for id in placed:
		count += _syllables(words[id])
	return count

func _draw() -> void:
	regions.clear()
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	# Draw a fixed diagnostic marker in untransformed local coordinates.
	# This distinguishes a rendering/layout issue from a text-color issue.
	draw_rect(Rect2(12, 12, 110, 28), Color("#dc2537"))
	draw_string(ThemeDB.fallback_font, Vector2(18, 32), "DRAW ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	var sc := minf(size.x / 1280.0, size.y / 720.0)
	if sc <= 0.0:
		return
	var offset := (size - Vector2(1280, 720) * sc) * 0.5
	draw_set_transform(offset, 0.0, Vector2(sc, sc))
	_draw_page()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _text(t: String, p: Vector2, sz: int, c: Color, title := false) -> void:
	draw_string(font_title if title else font_body, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)

func _button(r: Rect2, label: String, action: String) -> void:
	draw_rect(r, Color(INK, 0.045))
	draw_rect(r, Color(INK, 0.6), false, 1)
	_text(label, r.position + Vector2(9, 23), 14, INK)
	regions.append({"rect":r,"action":action})

func _draw_page() -> void:
	_text("In Countless Shadows", Vector2(70, 67), 37, INK, true)
	_text("SONNET XVII  /  MOVABLE TYPE", Vector2(72, 96), 14, FADED)
	draw_line(Vector2(70, 109), Vector2(1210, 109), INK, 1)
	_text("Select any line. Drag its words into the printing forme.", Vector2(72, 145), 17, INK)
	_text("THE SONNET", Vector2(72, 185), 16, ACCENT)
	_text("THE PRINTING FORME  /  LINE %02d" % (selected_line + 1), Vector2(590, 185), 16, ACCENT)
	_text("ABAB  CDCD  EFEF  GG", Vector2(590, 208), 14, BLUE)
	for i in range(LINES.size()):
		var y := 220.0 + i * 29.0 + float(i / 4) * 8.0
		if i >= 12:
			y += 8.0
		if selected_line == i:
			draw_rect(Rect2(68, y - 20, 495, 27), Color(ACCENT, 0.11))
		_text("%02d" % (i + 1), Vector2(73, y), 13, FADED)
		var preview: String = LINES[i]
		var saved: Array = arrangements[i]
		if not saved.is_empty():
			var parts: PackedStringArray = String(LINES[i]).split(" ", false)
			var arranged := PackedStringArray()
			for id in saved:
				arranged.append(parts[id])
			preview = " ".join(arranged)
		_text(preview, Vector2(103, y), 15, ACCENT if i == selected_line else INK)
		if show_rhyme:
			_text(RHYME[i], Vector2(544, y), 13, BLUE)
		regions.append({"rect":Rect2(69, y - 21, 496, 28),"action":"line","index":i})
	draw_rect(FRAME, Color(INK, 0.025))
	draw_rect(FRAME, Color(INK, 0.65), false, 1.5)
	_text("FIVE FEET  /  TEN EXPECTED SYLLABIC POSITIONS", Vector2(605, 287), 12, FADED)
	for i in range(10):
		var x := SLOT_X + float(i) * SLOT_WIDTH
		draw_rect(Rect2(x, 310, SLOT_WIDTH - 2, 112), Color(ACCENT, 0.05) if i % 2 == 0 else Color(BLUE, 0.05))
		draw_rect(Rect2(x, 310, SLOT_WIDTH - 2, 112), Color(INK, 0.15), false, 1)
		if show_meter:
			_text("u" if i % 2 == 0 else "/", Vector2(x + 22, 410), 15, FADED)
	var words := _words()
	var occupancy := 0
	for id in placed:
		var w := _syllables(words[id])
		var r := Rect2(SLOT_X + occupancy * SLOT_WIDTH, 331, float(w) * SLOT_WIDTH - 3, 58)
		if id != drag_id:
			_tile(id, r, true)
		occupancy += w
	draw_rect(TRAY, Color(INK, 0.025))
	draw_rect(TRAY, Color(INK, 0.35), false, 1)
	_text("TYPE TRAY  /  PICK UP INDIVIDUAL WORDS", Vector2(605, 489), 12, FADED)
	var x := 605.0
	var y := 502.0
	for id in range(words.size()):
		if placed.has(id):
			continue
		var width := maxf(40.0, font_body.get_string_size(words[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 18.0)
		if x + width > 1186.0:
			x = 605.0
			y += 42.0
		if y + 36.0 > TRAY.end.y:
			break
		var r := Rect2(x, y, width, 35)
		if id != drag_id:
			_tile(id, r, false)
		x += width + 6.0
	if drag_id >= 0:
		var width := maxf(55.0, font_body.get_string_size(words[drag_id], HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 22.0)
		_tile(drag_id, Rect2(drag_at - drag_offset, Vector2(width, 40)), true, false)
	_text("OCCUPANCY  %d / 10" % occupancy, Vector2(590, 631), 15, INK)
	_text(message, Vector2(590, 654), 14, BLUE)
	_button(Rect2(590, 672, 117, 34), "RESET LINE", "reset")
	_button(Rect2(716, 672, 110, 34), "UNDO", "undo")
	_button(Rect2(835, 672, 134, 34), "METER ON" if show_meter else "METER OFF", "meter")
	_button(Rect2(978, 672, 102, 34), "PRINT", "print")
	_button(Rect2(1089, 672, 112, 34), "RHYME", "rhyme")
	if selected_line == 11 and placed.has(1):
		_text("stretchèd: two syllables, one movable piece", Vector2(590, 242), 14, ACCENT)
	if printed:
		_text("IMPRESSION: " + printed_text, Vector2(72, 682), 14, BLUE)
	elif not shadow_trace.is_empty():
		_text("RHYME TRACE: " + " / ".join(shadow_trace), Vector2(72, 682), 14, BLUE)

func _tile(id: int, r: Rect2, active: bool, register := true) -> void:
	draw_rect(r, Color("#e9d9bf") if active else Color("#faf6ee"))
	draw_rect(r, ACCENT if active else Color(INK, 0.65), false, 1.3)
	_text(_words()[id], r.position + Vector2(7, 24), 17, INK)
	if register:
		regions.append({"rect":r,"action":"tile","index":id})

func _gui_input(event: InputEvent) -> void:
	var sc := minf(size.x / 1280.0, size.y / 720.0)
	var offset := (size - Vector2(1280, 720) * sc) * 0.5
	if event is InputEventMouseMotion and drag_id >= 0:
		drag_at = (event.position - offset) / sc
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = (event.position - offset) / sc
		if event.pressed:
			for i in range(regions.size() - 1, -1, -1):
				var region: Dictionary = regions[i]
				if region["rect"].has_point(p):
					if region["action"] == "tile":
						_save()
						drag_id = int(region["index"])
						drag_offset = p - region["rect"].position
						drag_at = p
						printed = false
					else:
						_action(region)
					queue_redraw()
					accept_event()
					return
		elif drag_id >= 0:
			var id := drag_id
			drag_id = -1
			placed.erase(id)
			if FRAME.has_point(p):
				var words := _words()
				if _used() + _syllables(words[id]) <= 10:
					var target := clampi(int(roundf((p.x - SLOT_X) / SLOT_WIDTH)), 0, 10)
					var position := 0
					var insertion := placed.size()
					for j in range(placed.size()):
						var span := _syllables(words[placed[j]])
						if float(target) < float(position) + float(span) / 2.0:
							insertion = j
							break
						position += span
					placed.insert(insertion, id)
					message = "Piece seated. Explore another arrangement."
				else:
					message = "The forme has no room for that piece."
			else:
				message = "Piece returned to the type tray."
			arrangements[selected_line] = placed.duplicate()
			queue_redraw()
			accept_event()

func _save() -> void:
	history.append({"line":selected_line,"placed":placed.duplicate(),"meter":show_meter,"rhyme":show_rhyme,"printed":printed,"text":printed_text})
	if history.size() > 80:
		history.pop_front()

func _action(region: Dictionary) -> void:
	var action: String = region["action"]
	if action == "undo":
		if history.is_empty():
			return
		var previous: Dictionary = history.pop_back()
		selected_line = previous["line"]
		placed = previous["placed"].duplicate()
		show_meter = previous["meter"]
		show_rhyme = previous["rhyme"]
		printed = previous["printed"]
		printed_text = previous["text"]
		arrangements[selected_line] = placed.duplicate()
		return
	_save()
	match action:
		"line":
			arrangements[selected_line] = placed.duplicate()
			selected_line = int(region["index"])
			placed = arrangements[selected_line].duplicate()
			printed = false
			message = "Line %02d selected. Assemble its words." % (selected_line + 1)
		"reset":
			placed.clear()
			arrangements[selected_line] = []
			printed = false
			message = "Type returned to tray."
		"meter":
			show_meter = not show_meter
		"rhyme":
			show_rhyme = not show_rhyme
		"print":
			if placed.size() == _words().size() and _used() == 10:
				var assembled := PackedStringArray()
				for id in placed:
					assembled.append(_words()[id])
				printed_text = " ".join(assembled)
				printed = true
				message = "Impression made. This is not a scansion verdict."
				if selected_line in [9, 11]:
					shadow_trace.append("tongue" if selected_line == 9 else "song")
			else:
				message = "Printing requires every word and ten positions."
	queue_redraw()
