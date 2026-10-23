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
const INTRO_HOLD := 2.4
const INTRO_FLY := 2.1
const TRAY_ROWS := 9
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
const RHYME_SCHEME := ["A","B","A","B","C","D","C","D","E","F","E","F","G","G"]
const SYLLABLES := {
	"believe":2, "deserts":2, "heaven":2, "beauty":2, "numbers":2,
	"number":2, "graces":2, "poet":2, "heavenly":3, "earthly":2,
	"faces":2, "papers":2, "yellow'd":2, "scorn'd":1, "stretchèd":2,
	"meter":2, "antique":2, "alive":2, "twice":1, "would":1,
	"touches":2, "less":1, "term'd":1, "rage":1, "should":1
}
# These pairings are interpretive suggestions, deliberately distinct from prosodic rules.
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
var drag_sound_cooldown := 0.0
var ink_time := 0.0
var intro_elapsed := 0.0
var intro_active := true
var tray_page := 0
var tray_indices: Array[int] = []

func _process(delta: float) -> void:
	if intro_active:
		intro_elapsed += delta
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
		var ty := PILE.position.y + 49.0 + float(row_index) * 56.0
		pieces[id]["tray_pos"] = Vector2(tx, ty)
		pieces[id]["tray_page"] = int(order / TRAY_PAGE_SIZE)
		pieces[id]["width"] = maxf(29.0, gothic.get_string_size(str(pieces[id]["word"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 8.0)

func _visible_piece(i: int) -> bool:
	if intro_active:
		return true
	if i == dragging or bool(pieces[i]["raised"]):
		return true
	return int(pieces[i]["tray_page"]) == tray_page

func _intro_position(i: int) -> Vector2:
	var original: Vector2 = pieces[i]["original_pos"]
	var destination: Vector2 = pieces[i]["tray_pos"]
	if intro_elapsed <= INTRO_HOLD:
		return original
	var fraction := clampf((intro_elapsed - INTRO_HOLD) / INTRO_FLY, 0.0, 1.0)
	var delay := float(i % 17) / 35.0
	var t := clampf((fraction - delay) / (1.0 - delay), 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	return original.lerp(destination, t)

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
func _relation_ids(left_id: int, right_id: int) -> Dictionary:
	var left: Dictionary = pieces[left_id]
	var right: Dictionary = pieces[right_id]
	var wa := _plain(str(left["word"]))
	var wb := _plain(str(right["word"]))
	if int(left["line"]) == int(right["line"]) and int(right["word_index"]) == int(left["word_index"]) + 1:
		var start_syllable := _assembled_syllables_before(left_id)
		var end_syllable := start_syllable + int(left["syllables"])
		if end_syllable % 2 == 0:
			return {"color":TEAL,"label":"IAMBIC FOOT?","symbol":"˘ /"}
		return {"color":TEAL,"label":"METRICAL PULSE?","symbol":"˘"}
	if str(left["rhyme"]) == str(right["rhyme"]) and int(left["line"]) != int(right["line"]):
		if int(left["word_index"]) == original_lines[int(left["line"])].size() - 1 and int(right["word_index"]) == original_lines[int(right["line"])].size() - 1:
			return {"color":COPPER,"label":"RHYME POSITION","symbol":"≈"}
	for pair in TENSIONS:
		if (wa == pair[0] and wb == pair[1]) or (wa == pair[1] and wb == pair[0]):
			return {"color":OXBLOOD,"label":"INTERPRETIVE TENSION","symbol":"◇"}
	if int(left["line"]) == int(right["line"]):
		return {"color":VIOLET,"label":"SHARED LINE","symbol":"⌣"}
	return {}

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
		var line_color := Color(INK, 0.15 if line_index == 12 else 0.085)
		draw_line(Vector2(129,baseline_y),Vector2(862,baseline_y),line_color,1.0)
		if not intro_active:
			_write(str(line_index + 1).pad_zeros(2),Vector2(109,baseline_y - 4.0),11,Color(INK,0.3))
		if line_index == 3 or line_index == 7 or line_index == 11:
			draw_line(Vector2(129,baseline_y + 8.0),Vector2(862,baseline_y + 8.0),Color(INK,0.12),1.0)
	if show_help and not intro_active and not _has_raised() and dragging < 0:
		_write("Lift a word from the ink at right.",Vector2(300,385),22,Color(INK,0.28))
	_write("SONNET XVII  ·  MOVABLE TYPE",Vector2(907,113),13,Color(INK,0.48))
	if not intro_active:
		_write("TYPE %d / %d    ‹  ›" % [tray_page + 1, int(ceil(float(tray_indices.size()) / float(TRAY_PAGE_SIZE)))], Vector2(908,684), 17, INK)
	else:
		_write("SONNET XVII", Vector2(110,106), 14, Color(INK,0.45))
	draw_line(Vector2(892,104),Vector2(892,691),Color(INK,0.13),1.0)
	# Relationships appear between physically adjacent words on the page.
	for i in range(pieces.size()):
		if intro_active or not bool(pieces[i]["raised"]) or i == dragging:
			continue
		for j in range(pieces.size()):
			if i == j or not bool(pieces[j]["raised"]) or j == dragging or not _neighbor(i,j):
				continue
			var r: Dictionary = _relation_ids(i,j)
			var color: Color = r.get("color",INK)
			var edge := _rect(i).end
			_ink_join(Vector2(edge.x+3.0,edge.y-18.0),color,1.0)
			if not r.is_empty():
				_write(str(r.get("symbol","")) + "  " + str(r["label"]),Vector2(edge.x-8.0,edge.y-47.0),13,color)
	for i in range(pieces.size()):
		if i != dragging and _visible_piece(i):
			_draw_piece(i)
	if dragging >= 0:
		_draw_piece(dragging)
	if discoveries.size() > 0:
		var last: String = discoveries[discoveries.size()-1]
		_write(last,Vector2(110,702),17,OXBLOOD)
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
	if on_page:
		_write(_assembled_meter(i),r.position+Vector2(12,49),13,TEAL)
	if i == dragging:
		for j in range(pieces.size()):
			if i == j or not bool(pieces[j]["raised"]):
				continue
			var target := _rect(j)
			var distance := (r.position - Vector2(target.end.x+9,target.position.y)).length()
			if distance < 46.0:
				var rel: Dictionary = _relation_ids(j,i)
				var ink_color: Color = rel.get("color",INK)
				_ink_outline(target,ink_color)
				_ink_join(Vector2(target.end.x+5,target.get_center().y),ink_color,1.0 - distance / 55.0)

func _gui_input(event: InputEvent) -> void:
	if intro_active:
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
			if Rect2(900,658,275,48).has_point(p):
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
					_paper_sound(0.14)
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
				var relation: Dictionary = _relation_ids(closest,id)
				if not relation.is_empty():
					discoveries.append(str(relation["label"]) + "  ·  " + str(pieces[closest]["word"]) + " / " + str(pieces[id]["word"]))
				else:
					discoveries.append("Words joined. Try another arrangement.")
			pieces[id]["raised"] = STAGE.has_point(Vector2(pieces[id]["pos"])) or closest >= 0
			if bool(pieces[id]["raised"]):
				var count := _assembled_syllables_before(id) + int(pieces[id]["syllables"])
				if count == 10:
					discoveries.append("TEN SYLLABLES · a pentameter-length sequence (stress remains open)")
			_paper_sound(0.24)
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

# Procedurally generated dry paper friction: no external audio asset needed.
func _make_paper_audio() -> void:
	paper_audio = AudioStreamPlayer.new()
	add_child(paper_audio)
	var sample_rate := 22050
	var sample_count := 2600
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1701701
	var previous := 0.0
	for n in range(sample_count):
		var envelope := pow(1.0 - float(n) / float(sample_count),1.6)
		var noise := rng.randf_range(-1.0,1.0)
		previous = lerpf(previous,noise,0.38)
		var value := int(clampf(previous*envelope*0.36,-1.0,1.0)*32767.0)
		if value < 0:
			value += 65536
		samples[n*2] = value & 255
		samples[n*2+1] = (value >> 8) & 255
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = samples
	paper_audio.stream = wav

func _paper_sound(volume: float) -> void:
	if paper_audio == null:
		return
	paper_audio.volume_db = linear_to_db(volume)
	paper_audio.pitch_scale = randf_range(0.86,1.13)
	paper_audio.play()
