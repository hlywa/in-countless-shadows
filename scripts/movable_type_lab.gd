extends Control
## Movable-type interaction spike for Sonnet 17, line 12.
## Word tiles remain whole objects; their width is based on syllable occupancy.
## This is NOT an automatic scansion or semantic validator.

const PAPER := Color("#f4efe3")
const INK := Color("#25231f")
const FADED := Color("#8d8577")
const ACCENT := Color("#9c4a39")
const BLUE := Color("#426b83")
const FRAME := Rect2(88, 274, 1104, 174)
const TRAY := Rect2(88, 492, 1104, 126)
const CELL := 92.0
const CELL_ORIGIN := 180.0

const WORDS := [
	{"text": "And", "syllables": 1, "parts": ["And"]},
	{"text": "stretchèd", "syllables": 2, "parts": ["stretch", "èd"]},
	{"text": "metre", "syllables": 2, "parts": ["me", "tre"]},
	{"text": "of", "syllables": 1, "parts": ["of"]},
	{"text": "an", "syllables": 1, "parts": ["an"]},
	{"text": "antique", "syllables": 2, "parts": ["an", "tique"]},
	{"text": "song", "syllables": 1, "parts": ["song"]}
]
const REFERENCE_ORDER := [0, 1, 2, 3, 4, 5, 6]

var ink_font: Font
var placed: Array[int] = []
var tile_rects: Array[Dictionary] = []
var drag_id := -1
var drag_at := Vector2.ZERO
var drag_offset := Vector2.ZERO
var printed := false
var printed_text := ""
var show_guide := true
var impression := 0.0

func _ready() -> void:
	ink_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _process(delta: float) -> void:
	if impression < 1.0:
		impression = minf(1.0, impression + delta * 2.3)
		queue_redraw()

func _draw() -> void:
	var sc := maxf(0.65, minf(size.x / 1280.0, size.y / 720.0))
	var offset := (size - Vector2(1280, 720) * sc) * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	draw_set_transform(offset, 0.0, Vector2(sc, sc))
	_draw_board()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_board() -> void:
	tile_rects.clear()
	_text("IN COUNTLESS SHADOWS", Vector2(88, 69), 30, INK)
	_text("EXPERIMENT 02  /  MOVABLE TYPE", Vector2(90, 96), 14, FADED)
	draw_line(Vector2(88, 112), Vector2(1192, 112), INK, 1)
	_text("Compose a line by dragging words into the printing forme.", Vector2(88, 158), 20, INK)
	_text("Each word is one piece. Its width reflects its number of syllables.", Vector2(88, 186), 15, FADED)
	_text("A five-foot measure expects ten positions, but rhythm is not just arithmetic.", Vector2(88, 211), 15, FADED)
	draw_rect(FRAME, Color(INK, 0.025))
	draw_rect(FRAME, INK, false, 2)
	_text("PRINTING FORME", Vector2(103, 299), 13, FADED)
	for i in range(10):
		var r := Rect2(CELL_ORIGIN + i * CELL, 327, CELL - 3, 91)
		draw_rect(r, Color(ACCENT, 0.045) if i % 2 == 0 else Color(BLUE, 0.045))
		draw_rect(r, Color(INK, 0.16), false, 1)
		if show_guide:
			_text("u" if i % 2 == 0 else "/", Vector2(r.position.x + 39, 407), 15, FADED)
		if i % 2 == 0:
			_text("FOOT %d" % (i / 2 + 1), Vector2(r.position.x + 6, 321), 10, FADED)
	draw_rect(TRAY, Color(INK, 0.025))
	draw_rect(TRAY, Color(INK, 0.3), false, 1)
	_text("TYPE TRAY  /  DRAG PIECES UP INTO THE FORME", Vector2(103, 515), 12, FADED)
	var syllables := 0
	for id in placed:
		var item: Dictionary = WORDS[id]
		var width: float = float(item["syllables"]) * CELL
		var r := Rect2(CELL_ORIGIN + syllables * CELL, 340, width - 4, 53)
		if id != drag_id:
			_draw_tile(id, r, true)
		syllables += int(item["syllables"])
	var tray_x := 111.0
	for id in range(WORDS.size()):
		if placed.has(id):
			continue
		var label: String = WORDS[id]["text"]
		var width := maxf(95.0, float(label.length()) * 14.0 + 30.0)
		var r := Rect2(tray_x, 538, width, 54)
		if id != drag_id:
			_draw_tile(id, r, false)
		tray_x += width + 10.0
	if drag_id >= 0:
		var label: String = WORDS[drag_id]["text"]
		var width := maxf(95.0, float(label.length()) * 14.0 + 30.0)
		_draw_tile(drag_id, Rect2(drag_at - drag_offset, Vector2(width, 54)), true, false)
	_text("SYLLABIC OCCUPANCY: %d / 10" % syllables, Vector2(88, 652), 15, INK)
	if syllables == 10 and placed.size() == WORDS.size():
		_text("THE FORME IS FULL  /  TRY AN IMPRESSION", Vector2(365, 652), 13, BLUE)
		_draw_button(Rect2(988, 636, 202, 38), "PRINT", "print")
	else:
		_text("Fill the ten positions to print.", Vector2(365, 652), 13, FADED)
	_draw_button(Rect2(88, 675, 166, 33), "RESET TYPE", "reset")
	_draw_button(Rect2(267, 675, 185, 33), "HIDE GUIDE" if show_guide else "SHOW GUIDE", "guide")
	if printed:
		draw_rect(Rect2(510, 674, 680, 35), Color(BLUE, 0.09))
		_text("IMPRESSION: " + printed_text, Vector2(520, 697), 15, BLUE)

func _draw_tile(id: int, rect: Rect2, in_forme: bool, register: bool = true) -> void:
	draw_rect(rect, Color("#eee2cd") if in_forme else Color("#f8f4eb"))
	draw_rect(rect, ACCENT if in_forme else INK, false, 1.5)
	var label: String = WORDS[id]["text"]
	_text(label, rect.position + Vector2(10, 32), 20, INK)
	if in_forme and int(WORDS[id]["syllables"]) > 1:
		for k in range(1, int(WORDS[id]["syllables"])):
			draw_line(Vector2(rect.position.x + CELL * k, rect.position.y + 5), Vector2(rect.position.x + CELL * k, rect.end.y - 5), Color(ACCENT, 0.4), 1)
	if register:
		tile_rects.append({"id": id, "rect": rect})

func _draw_button(rect: Rect2, label: String, _action: String) -> void:
	draw_rect(rect, Color(INK, 0.045))
	draw_rect(rect, INK, false, 1)
	_text(label, rect.position + Vector2(12, 23), 13, INK)

func _text(label: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ink_font, pos + Vector2(0.5, 0.6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, 0.08 * impression))
	draw_string(ink_font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, impression))

func _gui_input(event: InputEvent) -> void:
	var sc := maxf(0.65, minf(size.x / 1280.0, size.y / 720.0))
	var offset := (size - Vector2(1280, 720) * sc) * 0.5
	if event is InputEventMouseMotion and drag_id >= 0:
		drag_at = (event.position - offset) / sc
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = (event.position - offset) / sc
		if event.pressed:
			for i in range(tile_rects.size() - 1, -1, -1):
				var tile: Dictionary = tile_rects[i]
				if tile["rect"].has_point(p):
					drag_id = tile["id"]
					drag_offset = p - tile["rect"].position
					drag_at = p
					printed = false
					queue_redraw()
					accept_event()
					return
			if Rect2(88, 675, 166, 33).has_point(p):
				placed.clear()
				printed = false
				printed_text = ""
			elif Rect2(267, 675, 185, 33).has_point(p):
				show_guide = not show_guide
			elif Rect2(988, 636, 202, 38).has_point(p) and placed.size() == WORDS.size():
				printed_text = _assembled_text()
				printed = true
			queue_redraw()
		elif drag_id >= 0:
			var id := drag_id
			drag_id = -1
			placed.erase(id)
			if FRAME.has_point(p):
				var count := 0
				for other in placed:
					count += int(WORDS[other]["syllables"])
				var needed: int = WORDS[id]["syllables"]
				if count + needed <= 10:
					var target := clampi(int(roundf((p.x - CELL_ORIGIN) / CELL)), 0, 10)
					var running := 0
					var insertion := placed.size()
					for j in range(placed.size()):
						var span: int = WORDS[placed[j]]["syllables"]
						if target < running + span / 2.0:
							insertion = j
							break
						running += span
					placed.insert(insertion, id)
			printed = false
			queue_redraw()
			accept_event()

func _assembled_text() -> String:
	var words: PackedStringArray = []
	for id in placed:
		words.append(WORDS[id]["text"])
	return " ".join(words)
