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
const STAGE := Rect2(110, 105, 1060, 360)
const PILE := Rect2(105, 485, 1070, 212)
const SNAP := 30.0
const WORDS := [
	"Who","will","believe","my","verse","in","time","to","come,",
	"If","it","were","fill'd","with","your","most","high","deserts?",
	"Though","yet","heaven","knows","is","but","as","a","tomb",
	"Which","hides","life","and","shows","not","half","parts.",
	"beauty","eyes","poet","lies;","papers,","yellow'd","age,",
	"truth","than","tongue,","true","rights","rage","And",
	"stretchèd","meter","of","an","antique","song:",
	"But","some","child","alive","that","You","should","live",
	"twice,","in","it","and","in","my","rhyme."
]
const SYLLABLES := {
	"believe":2, "deserts":2, "heaven":2, "beauty":2,
	"poet":2, "papers":2, "yellow'd":2, "stretchèd":2,
	"meter":2, "antique":2, "alive":2
}
const RHYMES := [
	["come","tomb"], ["deserts","parts"], ["eyes","lies"],
	["graces","faces"], ["age","rage"], ["tongue","song"], ["time","rhyme"]
]
const TENSIONS := [
	["truth","lies"], ["beauty","eyes"], ["child","rhyme"],
	["verse","truth"], ["poet","lies"], ["life","tomb"]
]
var gothic: Font
var body_font: Font
var pieces: Array[Dictionary] = []
var dragging := -1
var hover := -1
var grab := Vector2.ZERO
var mouse_at := Vector2.ZERO
var discoveries: Array[String] = []
var show_help := true
var paper_audio: AudioStreamPlayer
var drag_sound_cooldown := 0.0

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
	var rng := RandomNumberGenerator.new()
	rng.seed = 17017
	for i in range(WORDS.size()):
		var word: String = WORDS[i]
		var width := maxf(37.0, gothic.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 27).x + 22.0)
		# A jittered multi-row typesetter pile keeps more words individually reachable.
		var column := i % 15
		var row_index := int(i / 15)
		var px := 112.0 + float(column) * 70.0 + rng.randf_range(-14.0, 14.0)
		var py := 501.0 + float(row_index) * 34.0 + rng.randf_range(-9.0, 9.0)
		px = clampf(px, 105.0, 1165.0 - width)
		py = clampf(py, 494.0, 663.0)
		pieces.append({"word":word,"pos":Vector2(px,py),"width":width,"raised":false})

func _scale() -> float:
	return maxf(0.001, minf(size.x / 1280.0, size.y / 720.0))

func _offset() -> Vector2:
	return (size - Vector2(1280,720) * _scale()) * 0.5

func _local_point(p: Vector2) -> Vector2:
	return (p - _offset()) / _scale()

func _rect(i: int) -> Rect2:
	var piece: Dictionary = pieces[i]
	return Rect2(piece["pos"], Vector2(piece["width"], 39))

func _plain(word: String) -> String:
	return word.to_lower().trim_suffix(",").trim_suffix(".").trim_suffix(":").trim_suffix(";").trim_suffix("?").trim_suffix("!")

func _syllables(word: String) -> int:
	return int(SYLLABLES.get(_plain(word), 1))

func _relation(a: String, b: String) -> Dictionary:
	var wa := _plain(a)
	var wb := _plain(b)
	for pair in RHYMES:
		if (wa == pair[0] and wb == pair[1]) or (wa == pair[1] and wb == pair[0]):
			return {"color":COPPER,"label":"RHYME"}
	for pair in TENSIONS:
		if (wa == pair[0] and wb == pair[1]) or (wa == pair[1] and wb == pair[0]):
			return {"color":OXBLOOD,"label":"MEANING"}
	if wa == "stretchèd" or wb == "stretchèd":
		return {"color":TEAL,"label":"TWO SYLLABLES"}
	if (wa == "will" and wb == "believe") or (wa == "in" and wb == "time") or (wa == "an" and wb == "antique") or (wa == "the" and wb == "beauty") or (wa == "to" and wb == "come"):
		return {"color":TEAL,"label":"RHYTHM"}
	if (wa == "my" and wb == "verse") or (wa == "antique" and wb == "song") or (wa == "your" and wb == "eyes") or (wa == "in" and wb == "my") or (wa == "your" and wb == "true") or (wa == "some" and wb == "child") or (wa == "should" and wb == "live") or (wa == "a" and wb == "tomb"):
		return {"color":VIOLET,"label":"PHRASE"}
	return {}

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
	# The page is intentionally unruled until the player lifts a word.
	if dragging >= 0 or _has_raised():
		draw_line(Vector2(142,287),Vector2(1138,287),Color(INK,0.075),1.0)
	if show_help and not _has_raised() and dragging < 0:
		_write("Lift a word from the ink below.",Vector2(478,315),22,Color(INK,0.28))
	_write("SONNET XVII  ·  MOVABLE TYPE",Vector2(106,478),13,Color(INK,0.38))
	draw_line(Vector2(105,486),Vector2(1175,486),Color(INK,0.13),1.0)
	# Relationships appear between physically adjacent words on the page.
	for i in range(pieces.size()):
		if not bool(pieces[i]["raised"]) or i == dragging:
			continue
		for j in range(pieces.size()):
			if i == j or not bool(pieces[j]["raised"]) or j == dragging or not _neighbor(i,j):
				continue
			var r: Dictionary = _relation(str(pieces[i]["word"]),str(pieces[j]["word"]))
			var color: Color = r.get("color",INK)
			var edge := _rect(i).end
			_ink_join(Vector2(edge.x+3.0,edge.y-18.0),color,1.0)
			if not r.is_empty():
				_write(str(r["label"]),Vector2(edge.x-8.0,edge.y-47.0),13,color)
	for i in range(pieces.size()):
		if i != dragging:
			_draw_piece(i)
	if dragging >= 0:
		_draw_piece(dragging)
	if discoveries.size() > 0:
		var last: String = discoveries[discoveries.size()-1]
		_write(last,Vector2(110,710),17,OXBLOOD)

func _has_raised() -> bool:
	for p in pieces:
		if bool(p["raised"]):
			return true
	return false

func _draw_piece(i: int) -> void:
	var r := _rect(i)
	var word: String = str(pieces[i]["word"])
	var active := i == hover or i == dragging
	var on_page := bool(pieces[i]["raised"])
	if active:
		draw_rect(r.grow(4),Color(INK,0.045))
		_ink_outline(r,INK)
	elif on_page:
		draw_line(r.position+Vector2(4,37),r.position+Vector2(r.size.x-4,37),Color(INK,0.15),1.0)
	_write(word,r.position+Vector2(10,29),27,INK,true)
	if i == dragging:
		for j in range(pieces.size()):
			if i == j or not bool(pieces[j]["raised"]):
				continue
			var target := _rect(j)
			var distance := (r.position - Vector2(target.end.x+9,target.position.y)).length()
			if distance < 46.0:
				var rel: Dictionary = _relation(str(pieces[j]["word"]),word)
				var ink_color: Color = rel.get("color",INK)
				_ink_outline(target,ink_color)
				_ink_join(Vector2(target.end.x+5,target.get_center().y),ink_color,1.0 - distance / 55.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_at = _local_point(event.position)
		if dragging >= 0:
			pieces[dragging]["pos"] = mouse_at - grab
		else:
			hover = -1
			for i in range(pieces.size()-1,-1,-1):
				if _rect(i).grow(4).has_point(mouse_at):
					hover = i
					break
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p := _local_point(event.position)
		if event.pressed:
			for i in range(pieces.size()-1,-1,-1):
				if _rect(i).grow(4).has_point(p):
					dragging = i
					hover = i
					grab = p - Vector2(pieces[i]["pos"])
					show_help = false
					_paper_sound(0.38)
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
				var relation: Dictionary = _relation(str(pieces[closest]["word"]),str(pieces[id]["word"]))
				if not relation.is_empty():
					discoveries.append(str(relation["label"]) + "  ·  " + str(pieces[closest]["word"]) + " / " + str(pieces[id]["word"]))
				else:
					discoveries.append("Words joined. Try another arrangement.")
			pieces[id]["raised"] = STAGE.has_point(Vector2(pieces[id]["pos"])) or closest >= 0
			_paper_sound(0.65)
			if not bool(pieces[id]["raised"]):
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
