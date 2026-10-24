extends Control
## In Countless Shadows: words are movable type, and form is discovered by arranging them.
## Formal feedback is a visual invitation, not a verdict about interpretation.

const PAPER := Color("#f4efe3")
const INK := Color("#181410")
const FAINT := Color("#a99b88")
const TEAL := Color("#477e7b")
const COPPER := Color("#a16b49")
const VIOLET := Color("#65558d")
const OXBLOOD := Color("#a4484d")
const STAGE := Rect2(105, 105, 775, 585)
const PILE := Rect2(902, 105, 273, 585)
const SNAP := 30.0
const INTRO_HOLD := 1.35
const INTRO_FLY := 9.8
const VOLTA_LINE := 12 # Zero-based: "But were some child..." is line 13.
const TRAY_ROWS := 7
const TRAY_COLS := 2
const TRAY_PAGE_SIZE := TRAY_ROWS * TRAY_COLS
# First Folio-style spelling is not enforced; this is a complete modernized Sonnet 17.
# A syllable count is an editorial reading, not a verdict on spoken performance.
const SONNET_LINES := [
	"Who will believe my verse in time to come,",
	"If it were fill'd with your most high deserts?",
	"Though yet heaven knows it is but as a tomb",
	"Which hides your life, and shows not half your parts.",
	"If I could write the beauty of your eyes",
	"And in fresh numbers number all your graces,",
	"The age to come would say 'This poet lies;",
	"Such heavenly touches ne'er touch'd earthly faces.'",
	"So should my papers, yellow'd with their age,",
	"Be scorn'd, like old men of less truth than tongue,",
	"And your true rights be term'd a poet's rage",
	"And stretchèd meter of an antique song:",
	"But were some child of yours alive that time,",
	"You should live twice; in it, and in my rhyme."
]
const RHYME_PAIRS := [[0,2],[1,3],[4,6],[5,7],[8,10],[9,11],[12,13]]
const RHYME_SCHEME := ["A","B","A","B","C","D","C","D","E","F","E","F","G","G"]
const SYLLABLES := {
	"believe":2, "deserts":2, "heaven":2, "beauty":2, "numbers":2,
	"number":2, "graces":2, "poet":2, "heavenly":3, "earthly":2,
	"faces":2, "papers":2, "yellow'd":2, "scorn'd":1, "stretchèd":2,
	"meter":2, "antique":2, "alive":2, "twice":1, "would":1,
	"touches":2, "less":1, "term'd":1, "rage":1, "should":1
}
# These pairings are interpretive suggestions, deliberately distinct from prosodic rules.
const ECHO_GROUPS := [["number","numbers"],["poet","poet\u0027s"],["touches","touch\u0027d"],["age","age"],["time","time"]]
const TENSIONS := [
	["truth","lies"], ["beauty","eyes"], ["child","rhyme"],
	["verse","truth"], ["poet","lies"], ["life","tomb"]
]
var gothic: Font
var body_font: Font
var pieces: Array[Dictionary] = []
var original_lines: Array[PackedStringArray] = []
var dragging := -1
var hover := -1
var grab := Vector2.ZERO
var mouse_at := Vector2.ZERO
var discoveries: Array[String] = []
var show_help := true
var paper_audio: AudioStreamPlayer
var rustle_voices: Array[AudioStreamPlayer] = []
var rustle_voice_index := 0
var intro_rustle_clock := 0.0
var drag_sound_cooldown := 0.0
var ink_time := 0.0
var intro_elapsed := 0.0
var intro_active := true
var intro_flight_started := false
var tray_page := 0
var tray_indices: Array[int] = []
var constraint_report: Dictionary = {}

func _process(delta: float) -> void:
	if intro_active:
		intro_elapsed += delta
		if intro_elapsed >= INTRO_HOLD and intro_elapsed < INTRO_HOLD + INTRO_FLY:
			intro_rustle_clock += delta
			if intro_rustle_clock >= 0.17:
				intro_rustle_clock = 0.0
				_paper_sound(0.035)
		queue_redraw()
		if intro_elapsed >= INTRO_HOLD + INTRO_FLY:
			intro_active = false
			for i in range(pieces.size()):
				pieces[i]["pos"] = pieces[i]["tray_pos"]
			queue_redraw()
	elif dragging >= 0:
		ink_time += delta
		queue_redraw()

func _ready() -> void:
	gothic = load("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") if ResourceLoader.exists("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") else ThemeDB.fallback_font
	body_font = load("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") if ResourceLoader.exists("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") else gothic
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scatter()
	_make_paper_audio()
	queue_redraw()

func _scatter() -> void:
	pieces.clear()
	original_lines.clear()
	tray_indices.clear()
	var index := 0
	for line_number in range(SONNET_LINES.size()):
		var words: PackedStringArray = SONNET_LINES[line_number].split(" ", false)
		original_lines.append(words)
		var syllable_position := 0
		var x := 129.0
		var y := 123.0 + float(line_number) * 39.0
		for word_index in range(words.size()):
			var word: String = words[word_index]
			var width := maxf(29.0, gothic.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 8.0)
			var original_pos := Vector2(x, y)
			pieces.append({"word":word, "pos":original_pos, "original_pos":original_pos,
				"tray_pos":Vector2.ZERO, "width":width, "raised":false,
				"line":line_number, "word_index":word_index, "syllable_start":syllable_position,
				"syllables":_syllables(word), "rhyme":RHYME_SCHEME[line_number]})
			x += width + 4.0
			syllable_position += _syllables(word)
			index += 1
	# Distribute all the words into readable pages of loose type.
	# The deterministic shuffle preserves the sense of a jumble without overlap.
	var rng := RandomNumberGenerator.new()
	rng.seed = 17017
	for i in range(pieces.size()):
		tray_indices.append(i)
	for i in range(tray_indices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var old := tray_indices[i]
		tray_indices[i] = tray_indices[j]
		tray_indices[j] = old
	for order in range(tray_indices.size()):
		var id := tray_indices[order]
		var slot := order % TRAY_PAGE_SIZE
		var col := slot % TRAY_COLS
		var row_index := int(slot / TRAY_COLS)
		var tx := PILE.position.x + 12.0 + float(col) * 130.0
		var ty := PILE.position.y + 45.0 + float(row_index) * 54.0
		pieces[id]["tray_pos"] = Vector2(tx, ty)
		pieces[id]["tray_page"] = int(order / TRAY_PAGE_SIZE)
		pieces[id]["width"] = maxf(29.0, gothic.get_string_size(str(pieces[id]["word"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 8.0)

func _visible_piece(i: int) -> bool:
	if intro_active:
		if intro_elapsed <= INTRO_HOLD:
			return true
		var fraction := clampf((intro_elapsed - INTRO_HOLD) / INTRO_FLY, 0.0, 1.0)
		var delay := float(i % 31) / 70.0
		var t := clampf((fraction - delay) / (1.0 - delay), 0.0, 1.0)
		return int(pieces[i]["tray_page"]) == 0 or t < 0.83
	if i == dragging or bool(pieces[i]["raised"]):
		return true
	return int(pieces[i]["tray_page"]) == tray_page

func _intro_position(i: int) -> Vector2:
	var original: Vector2 = pieces[i]["original_pos"]
	var destination: Vector2 = pieces[i]["tray_pos"]
	if intro_elapsed <= INTRO_HOLD:
		return original
	var fraction := clampf((intro_elapsed - INTRO_HOLD) / INTRO_FLY, 0.0, 1.0)
	var delay := float(i % 31) / 70.0
	var t := clampf((fraction - delay) / (1.0 - delay), 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	var lift := sin(t * PI) * (12.0 + float(i % 9) * 5.0)
	return original.lerp(destination, t) + Vector2(0.0, -lift)

func _scale() -> float:
	return maxf(0.001, minf(size.x / 1280.0, size.y / 720.0))

func _offset() -> Vector2:
	return (size - Vector2(1280,720) * _scale()) * 0.5

func _local_point(p: Vector2) -> Vector2:
	return (p - _offset()) / _scale()

func _rect(i: int) -> Rect2:
	var piece: Dictionary = pieces[i]
	return Rect2(_intro_position(i) if intro_active else Vector2(piece["pos"]), Vector2(piece["width"], 39))

func _plain(word: String) -> String:
	return word.to_lower().trim_suffix(",").trim_suffix(".").trim_suffix(":").trim_suffix(";").trim_suffix("?").trim_suffix("!")

func _syllables(word: String) -> int:
	return int(SYLLABLES.get(_plain(word), 1))

# Analyze neighboring pieces using their provenance and the syllabic sequence
# assembled on the page. Stress is presented as an iambic hypothesis, not a fact.
func _relation_ids(left_id: int, right_id: int) -> Array[Dictionary]:
	return _pair_relationships(_analyze_composition(false),left_id,right_id)

func _pair_relationships(model: Dictionary, left_id: int, right_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var adjacent := false
	for line in model["lines"]:
		var ids: Array = line["ids"]
		var index := ids.find(left_id)
		if index >= 0 and index + 1 < ids.size() and int(ids[index+1]) == right_id:
			adjacent = true
			break
	if not adjacent:
		return result
	var a := _plain(str(pieces[left_id]["word"]))
	var b := _plain(str(pieces[right_id]["word"]))
	for pair in TENSIONS:
		if (a == pair[0] and b == pair[1]) or (a == pair[1] and b == pair[0]):
			result.append({"color":OXBLOOD,"label":"INTERPRETIVE TENSION?","symbol":"◇"})
	if _echo_key(a) == _echo_key(b):
		result.append({"color":VIOLET,"label":"WORD ECHO","symbol":"↺"})
	var pulse: int = int(model["starts"].get(left_id,0)) + int(pieces[left_id]["syllables"])
	result.append({"color":TEAL,"label":"METRICAL POSITION?","symbol":"˘ /" if pulse % 2 == 0 else "˘"})
	result.append({"color":VIOLET,"label":"SHARED VERSE","symbol":"⌣"})
	return result

# One formal vocabulary serves the intact poem and new compositions.
# Rhyme is a provisional sound-family lexicon, not a full phonetic engine.
const RHYME_FAMILIES := {
	"come":"COME_TOMB", "tomb":"COME_TOMB", "deserts":"DESERTS_PARTS", "parts":"DESERTS_PARTS",
	"eyes":"EYES", "lies":"EYES", "graces":"ACES", "faces":"ACES",
	"age":"AGE", "rage":"AGE", "tongue":"TONGUE_SONG", "song":"TONGUE_SONG",
	"time":"IME", "rhyme":"IME"
}
func _rhyme_family(word: String) -> String:
	return str(RHYME_FAMILIES.get(_plain(word), ""))

func _echo_key(word: String) -> String:
	var plain := _plain(word).trim_prefix("\u0027")
	for group in ECHO_GROUPS:
		if plain in group:
			return str(group[0])
	return plain

func _on_stage_line(i: int) -> int:
	var center_y := _rect(i).get_center().y
	var line_number := roundi((center_y - 142.5) / 39.0)
	if line_number < 0 or line_number >= 14:
		return -1
	if absf(center_y - (142.5 + float(line_number) * 39.0)) > 19.0:
		return -1
	return line_number

func _line_words(line_number: int, intact: bool) -> Array[int]:
	var result: Array[int] = []
	for i in range(pieces.size()):
		if intact:
			if int(pieces[i]["line"]) == line_number:
				result.append(i)
		elif bool(pieces[i]["raised"]) and _on_stage_line(i) == line_number:
			result.append(i)
	result.sort_custom(func(a: int, b: int) -> bool:
		return _rect(a).position.x < _rect(b).position.x)
	return result

func _line_syllables(line_number: int, intact: bool) -> int:
	var total := 0
	for id in _line_words(line_number, intact):
		total += int(pieces[id]["syllables"])
	return total

func _line_ending(line_number: int, intact: bool) -> String:
	var words := _line_words(line_number, intact)
	if words.is_empty():
		return ""
	return str(pieces[words[words.size() - 1]]["word"])

func _draw_formal_overlay(model: Dictionary, intact: bool) -> void:
	for pair in model["pairs"]:
		if not intact and not bool(pair["match"]):
			continue
		var a: int = pair["a"]
		var b: int = pair["b"]
		var x := 866.0
		var ya := 145.0 + float(a)*39.0
		var yb := 145.0 + float(b)*39.0
		draw_line(Vector2(x,ya),Vector2(x+9,ya),Color(COPPER,0.7),1.4)
		draw_line(Vector2(x+9,ya),Vector2(x+9,yb),Color(COPPER,0.43),1.1)
		draw_line(Vector2(x+9,yb),Vector2(x,yb),Color(COPPER,0.7),1.4)
		_write("≈" if bool(pair["match"]) else "≈?",Vector2(x+11,(ya+yb)*0.5+5),12,COPPER)
	for n in range(14):
		var line: Dictionary = model["lines"][n]
		if bool(line["has_words"]):
			var mark := "∎" if bool(line["end_stopped"]) else "↳"
			_write(mark,Vector2(847,145.0+float(n)*39.0),12,VIOLET)
		for pause_index in line["internal_pauses"]:
			var pause_id: int = line["ids"][int(pause_index)]
			var pause_rect := _rect(pause_id)
			_write("‖",pause_rect.position+Vector2(pause_rect.size.x-5,8),12,VIOLET)
		for id in line["ids"]:
			var rect := _rect(int(id))
			var before: int = int(model["starts"].get(int(id),0))
			var count := int(pieces[int(id)]["syllables"])
			var marks := ""
			for k in range(count):
				marks += "˘" if (before+k)%2 == 0 else "/"
				if k < count-1:
					marks += " "
			_write(marks,rect.position+Vector2(4,38 if intact else 49),11,Color(TEAL,0.83))
		if int(line["syllables"]) == 10:
			draw_circle(Vector2(118,144.0+float(n)*39.0),2.4,TEAL)
	for key in model["echoes"]:
		var occurrences: Array = model["echoes"][key]
		if occurrences.size() > 1:
			for id in occurrences:
				var rect := _rect(int(id))
				draw_line(Vector2(rect.position.x+3,rect.end.y-2),Vector2(rect.end.x-3,rect.end.y-2),Color(VIOLET,0.65),1.5)
	if intact:
		_draw_volta_mark(VOLTA_LINE,true)
	else:
		for n in model["turns"]:
			_draw_volta_mark(int(n),false)

func _draw_volta_mark(line_number: int, intact: bool) -> void:
	var cy := 142.0 + float(line_number) * 39.0
	var x := 112.0
	draw_arc(Vector2(x,cy),14.0,-PI*0.62,PI*0.64,22,Color(OXBLOOD,0.8),2.0,true)
	draw_line(Vector2(x+10,cy+10),Vector2(x+16,cy+16),Color(OXBLOOD,0.8),2.0,true)
	_write("TURN?" if not intact else "VOLTA",Vector2(133,cy-18),11,OXBLOOD)


# Single model for all annotations, feedback and formal completion.
# All visible relationships are derived from the current composition.
# Punctuation and turn markers are editorial clues, not automatic proof of meaning.
func _analyze_composition(intact: bool) -> Dictionary:
	var lines: Array[Dictionary] = []
	var starts: Dictionary = {}
	var used := 0
	var ten := 0
	var filled := 0
	var turns: Array[int] = []
	var echoes: Dictionary = {}
	for n in range(14):
		var ids := _line_words(n,intact)
		var count := 0
		var words: Array[String] = []
		for id in ids:
			starts[id] = count
			count += int(pieces[id]["syllables"])
			var word := str(pieces[id]["word"])
			words.append(word)
			var key := _echo_key(word)
			if not echoes.has(key):
				echoes[key] = []
			echoes[key].append(id)
		used += ids.size()
		if not ids.is_empty():
			filled += 1
			var first := _plain(words[0]).trim_prefix("'")
			if first in ["but","yet","though","so","then"] and n > 0:
				turns.append(n)
		if count == 10:
			ten += 1
		var ending := words[words.size()-1] if not words.is_empty() else ""
		var end_stopped := ending.ends_with(".") or ending.ends_with("?") or ending.ends_with("!") or ending.ends_with(";") or ending.ends_with(":")
		var internal_pauses: Array[int] = []
		for k in range(maxi(0,words.size()-1)):
			var w: String = words[k]
			if w.ends_with(",") or w.ends_with(";") or w.ends_with(":") or w.ends_with("?") or w.ends_with("!"):
				internal_pauses.append(k)
		lines.append({"ids":ids,"syllables":count,"family":_rhyme_family(ending),
			"ending":ending,"end_stopped":end_stopped,"internal_pauses":internal_pauses,
			"has_words":not ids.is_empty(),"group":0 if n < 4 else (1 if n < 8 else (2 if n < 12 else 3))})
	var pairs: Array[Dictionary] = []
	var matched := 0
	var known := 0
	for positions in RHYME_PAIRS:
		var a: int = positions[0]
		var b: int = positions[1]
		var fa: String = lines[a]["family"]
		var fb: String = lines[b]["family"]
		var is_known := not fa.is_empty() and not fb.is_empty()
		var is_match := is_known and fa == fb
		if is_known:
			known += 1
		if is_match:
			matched += 1
		pairs.append({"a":a,"b":b,"known":is_known,"match":is_match})
	var complete := used == pieces.size() and filled == 14
	return {"lines":lines,"starts":starts,"filled":filled,"ten":ten,"rhymes":matched,
		"known":known,"turns":turns,"pairs":pairs,"echoes":echoes,"used":used,
		"complete":complete,"formal":complete and ten == 14 and matched == 7}

func _evaluate_form(intact: bool) -> Dictionary:
	return _analyze_composition(intact)

func _draw_form_report(model: Dictionary) -> void:
	# The tray's final two rows are reserved for a compact, non-overlapping report.
	var left := 909.0
	var right := 1050.0
	_write("FORM IN PROGRESS",Vector2(left,564),13,INK)
	draw_line(Vector2(left,574),Vector2(1167,574),Color(INK,0.13),1.0)
	_write("LINES  %d / 14" % int(model["filled"]),Vector2(left,595),13,TEAL)
	_write("RHYME  %d / 7" % int(model["rhymes"]),Vector2(right,595),13,COPPER)
	_write("10 SYLL  %d / 14" % int(model["ten"]),Vector2(left,617),13,TEAL)
	_write("KNOWN  %d / 7" % int(model["known"]),Vector2(right,617),13,COPPER)
	if bool(model["formal"]):
		_write("FORM HOLDS. MEANING REMAINS OPEN.",Vector2(110,703),15,OXBLOOD)
	elif bool(model["complete"]):
		_write("All words placed. The form can still change.",Vector2(110,703),15,OXBLOOD)
	elif int(model["used"]) > 0:
		_write("%d words placed; more than one reading is possible." % int(model["used"]),Vector2(110,703),13,Color(INK,0.55))

func _assembled_syllables_before(piece_id: int) -> int:
	var count := 0
	var target := _rect(piece_id)
	for i in range(pieces.size()):
		if i == piece_id or not bool(pieces[i]["raised"]):
			continue
		var r := _rect(i)
		if absf(r.get_center().y - target.get_center().y) < 28.0 and r.position.x < target.position.x:
			count += int(pieces[i]["syllables"])
	return count

func _assembled_meter(piece_id: int) -> String:
	var count := _assembled_syllables_before(piece_id)
	var n := int(pieces[piece_id]["syllables"])
	var result := ""
	for k in range(n):
		result += "˘" if (count + k) % 2 == 0 else "/"
		if k < n - 1:
			result += " "
	return result

func _neighbor(i: int, j: int) -> bool:
	var a := _rect(i)
	var b := _rect(j)
	return absf(a.get_center().y - b.get_center().y) < 28.0 and absf(a.end.x - b.position.x) < 19.0

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size), PAPER)
	draw_set_transform(_offset(), 0.0, Vector2(_scale(),_scale()))
	_page()
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _write(t: String, at: Vector2, font_size: int, color: Color, use_gothic := false) -> void:
	draw_string(gothic if use_gothic else body_font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _page() -> void:
	_write("In Countless Shadows", Vector2(105,73), 40, INK, true)
	draw_line(Vector2(105,87),Vector2(1175,87),Color(INK,0.16),1.0)
	# Fourteen quiet letterpress baselines: one for each verse of the sonnet.
	# The seventh rhyme pair is the closing couplet, not a seven-line poem.
	for line_index in range(14):
		var baseline_y := 154.0 + float(line_index) * 39.0
		var line_color := Color(INK, 0.085 if line_index == 12 else 0.038)
		draw_line(Vector2(129,baseline_y),Vector2(862,baseline_y),line_color,1.0)
		if line_index == 3 or line_index == 7 or line_index == 11:
			draw_line(Vector2(129,baseline_y + 8.0),Vector2(862,baseline_y + 8.0),Color(INK,0.065),1.0)
	if show_help and not intro_active and not _has_raised() and dragging < 0:
		_write("Lift a word from the ink at right.",Vector2(300,385),22,Color(INK,0.28))
	_write("SONNET XVII  ·  MOVABLE TYPE",Vector2(907,113),13,Color(INK,0.48))
	if not intro_active:
		_write("TYPE %d / %d    ‹  ›" % [tray_page + 1, int(ceil(float(tray_indices.size()) / float(TRAY_PAGE_SIZE)))], Vector2(909,676), 16, INK)
	else:
		_write("CLICK TO RELEASE THE TYPE", Vector2(110,106), 14, Color(INK,0.45))
	draw_line(Vector2(892,104),Vector2(892,691),Color(INK,0.13),1.0)
	if not intro_active:
		_write("˘ /  METER", Vector2(128,112), 12, TEAL)
		_write("≈  RHYME", Vector2(252,112), 12, COPPER)
		_write("↺  ECHO / PAUSE", Vector2(368,112), 12, VIOLET)
		_write("◇  TENSION", Vector2(548,112), 12, OXBLOOD)
	var intact := intro_active and intro_elapsed <= INTRO_HOLD
	var model := _analyze_composition(intact)
	if not intro_active:
		_draw_form_report(model)
	_draw_formal_overlay(model,intact)
	# Relationships appear between physically adjacent words on the page.
	for i in range(pieces.size()):
		if intro_active or not bool(pieces[i]["raised"]) or i == dragging:
			continue
		for j in range(pieces.size()):
			if i == j or not bool(pieces[j]["raised"]) or j == dragging or not _neighbor(i,j):
				continue
			var relations := _pair_relationships(model,i,j)
			var color: Color = relations[0]["color"] if not relations.is_empty() else INK
			var edge := _rect(i).end
			_ink_join(Vector2(edge.x+3.0,edge.y-18.0),color,1.0)
			for k in range(relations.size()):
				var relation: Dictionary = relations[k]
				_write(str(relation["symbol"]),Vector2(edge.x-8.0+float(k)*18.0,edge.y-47.0),12,relation["color"])
	for i in range(pieces.size()):
		if i != dragging and _visible_piece(i):
			_draw_piece(i)
	if dragging >= 0:
		_draw_piece(dragging)
	if discoveries.size() > 0:
		var last: String = discoveries[discoveries.size()-1]
		_write(last,Vector2(110,678),13,OXBLOOD)
func _has_raised() -> bool:
	for p in pieces:
		if bool(p["raised"]):
			return true
	return false

func _draw_piece(i: int) -> void:
	var r := _rect(i)
	var word: String = str(pieces[i]["word"])
	var active := i == hover or i == dragging
	var on_page := bool(pieces[i]["raised"]) and not intro_active
	if active:
		draw_rect(r.grow(4),Color(INK,0.045))
		_ink_outline(r,INK)
		if i == dragging:
			var phase := fposmod(ink_time * 26.0,19.0)
			for drop in range(3):
				var drip_x := r.position.x + 10.0 + float(drop) * maxf(9.0,(r.size.x-20.0)/3.0)
				var drip_y := r.end.y + fposmod(phase + float(drop)*7.0,21.0)
				draw_line(Vector2(drip_x,r.end.y),Vector2(drip_x,drip_y),Color(INK,0.55),1.5,true)
				draw_circle(Vector2(drip_x,drip_y),2.2,Color(INK,0.72))
	elif on_page:
		draw_line(r.position+Vector2(4,37),r.position+Vector2(r.size.x-4,37),Color(INK,0.15),1.0)
	_write(word,r.position+Vector2(4,23 if intro_active or not on_page else 29),20 if intro_active or not on_page else 27,INK,true)
	# Scansion marks are drawn centrally by _draw_formal_overlay().
	if i == dragging:
		for j in range(pieces.size()):
			if i == j or not bool(pieces[j]["raised"]):
				continue
			var target := _rect(j)
			var distance := (r.position - Vector2(target.end.x+9,target.position.y)).length()
			if distance < 46.0:
				var rel := _relation_ids(j,i)
				var ink_color: Color = rel[0]["color"] if not rel.is_empty() else INK
				_ink_outline(target,ink_color)
				_ink_join(Vector2(target.end.x+5,target.get_center().y),ink_color,1.0 - distance / 55.0)

func _gui_input(event: InputEvent) -> void:
	if intro_active:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			intro_elapsed = maxf(intro_elapsed, INTRO_HOLD)
			_paper_sound(0.065)
			queue_redraw()
			accept_event()
		return
	if event is InputEventMouseMotion:
		mouse_at = _local_point(event.position)
		if dragging >= 0:
			pieces[dragging]["pos"] = mouse_at - grab
		else:
			hover = -1
			for i in range(pieces.size()-1,-1,-1):
				if _visible_piece(i) and _rect(i).grow(4).has_point(mouse_at):
					hover = i
					break
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and PILE.has_point(_local_point(event.position)):
		tray_page = mini(tray_page + 1, int((tray_indices.size() - 1) / TRAY_PAGE_SIZE))
		queue_redraw()
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and PILE.has_point(_local_point(event.position)):
		tray_page = maxi(0, tray_page - 1)
		queue_redraw()
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p := _local_point(event.position)
		if event.pressed:
			if Rect2(900,646,275,52).has_point(p):
				tray_page = (tray_page + 1) % int(ceil(float(tray_indices.size()) / float(TRAY_PAGE_SIZE)))
				queue_redraw()
				accept_event()
				return
			for i in range(pieces.size()-1,-1,-1):
				if _visible_piece(i) and _rect(i).grow(4).has_point(p):
					dragging = i
					hover = i
					grab = p - Vector2(pieces[i]["pos"])
					show_help = false
					_paper_sound(0.07)
					accept_event()
					queue_redraw()
					return
		elif dragging >= 0:
			var id := dragging
			dragging = -1
			var pos: Vector2 = pieces[id]["pos"]
			var closest := -1
			var best := SNAP * 2.0
			for j in range(pieces.size()):
				if j == id or not bool(pieces[j]["raised"]):
					continue
				var r := _rect(j)
				var target := Vector2(r.end.x + 8.0,r.position.y)
				var d := pos.distance_to(target)
				if d < best:
					best = d
					closest = j
			if closest >= 0:
				var anchor := _rect(closest)
				pieces[id]["pos"] = Vector2(anchor.end.x+8.0,anchor.position.y)
				# Relationship feedback is evaluated after placement.
			pieces[id]["raised"] = STAGE.has_point(Vector2(pieces[id]["pos"])) or closest >= 0
			if closest >= 0 and bool(pieces[id]["raised"]):
				var relations := _relation_ids(closest,id)
				if not relations.is_empty():
					var labels: Array[String] = []
					for relation in relations:
						labels.append(str(relation["label"]))
					discoveries.append(" + ".join(labels))
			if bool(pieces[id]["raised"]):
				var line_number := _on_stage_line(id)
				if line_number >= 0 and _line_syllables(line_number, false) == 10:
					discoveries.append("TEN SYLLABLES · possible pentameter")
				var report := _evaluate_form(false)
				if int(report["rhymes"]) > 0:
					discoveries.append("RHYME PAIRS · %d / 7" % int(report["rhymes"]))
			_paper_sound(0.09)
			if not bool(pieces[id]["raised"]):
				pieces[id]["pos"] = pieces[id]["tray_pos"]
				discoveries.append("Return to the ink. Lift another word.")
			queue_redraw()
			accept_event()
# Irregular pools and small hanging droplets, drawn in the same canvas as the type.
func _ink_outline(r: Rect2, ink_color: Color) -> void:
	var edge := r.grow(3.0)
	draw_rect(edge,Color(ink_color,0.07))
	draw_rect(edge,Color(ink_color,0.85),false,2.0)
	for k in range(4):
		var x := edge.position.x + 7.0 + float(k) * (edge.size.x - 14.0) / 4.0
		var y := edge.end.y + float((k * 7 + 3) % 5)
		draw_circle(Vector2(x,y),2.0 + float(k % 2),Color(ink_color,0.74))
		draw_line(Vector2(x,edge.end.y),Vector2(x,y+3.0+float(k % 3)*3.0),Color(ink_color,0.6),1.8,true)

func _ink_join(center: Vector2, ink_color: Color, strength: float) -> void:
	var alpha := clampf(strength,0.15,1.0)
	draw_circle(center,8.0,Color(ink_color,0.38*alpha))
	draw_circle(center+Vector2(3,1),5.0,Color(ink_color,0.85*alpha))
	draw_circle(center+Vector2(-4,-2),3.0,Color(ink_color,0.75*alpha))
	for k in range(3):
		var dx := float(k-1)*5.0
		var length := 7.0 + float((k*7+3)%9)
		draw_line(center+Vector2(dx,3),center+Vector2(dx,length),Color(ink_color,0.7*alpha),2.0,true)
		draw_circle(center+Vector2(dx,length),2.5,Color(ink_color,0.7*alpha))

# Soft, low-passed paper friction shared by flying type and manual placement.
# Multiple voices let the tiny rustles overlap instead of cutting one another off.
func _make_paper_audio() -> void:
	var sample_rate := 22050
	var sample_count := 6200
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1701701
	var previous := 0.0
	for n in range(sample_count):
		var phase := float(n) / float(sample_count)
		var envelope := pow(sin(phase * PI), 1.6)
		var noise := rng.randf_range(-1.0, 1.0)
		previous = lerpf(previous, noise, 0.075)
		var grain := 0.74 + 0.26 * sin(phase * TAU * 13.0)
		var value := int(clampf(previous * envelope * grain * 0.18, -1.0, 1.0) * 32767.0)
		if value < 0:
			value += 65536
		samples[n * 2] = value & 255
		samples[n * 2 + 1] = (value >> 8) & 255
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = samples
	for i in range(6):
		var voice := AudioStreamPlayer.new()
		voice.stream = wav
		add_child(voice)
		rustle_voices.append(voice)
	paper_audio = rustle_voices[0]

func _paper_sound(volume: float) -> void:
	if rustle_voices.is_empty():
		return
	var voice: AudioStreamPlayer = rustle_voices[rustle_voice_index]
	rustle_voice_index = (rustle_voice_index + 1) % rustle_voices.size()
	voice.volume_db = linear_to_db(maxf(volume, 0.001))
	voice.pitch_scale = randf_range(0.83, 1.06)
	voice.play()
