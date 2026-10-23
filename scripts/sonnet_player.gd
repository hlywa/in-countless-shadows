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

func _ready() -> void:
    gothic = load("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") if ResourceLoader.exists("res://assets/fonts/UnifrakturCook/UnifrakturCook-Bold.ttf") else ThemeDB.fallback_font
    body_font = load("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") if ResourceLoader.exists("res://assets/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf") else gothic
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _scatter()
    queue_redraw()

func _scatter() -> void:
    pieces.clear()
    var rng := RandomNumberGenerator.new()
    rng.seed = 17017
    for i in range(WORDS.size()):
        var word: String = WORDS[i]
        var width := maxf(37.0, gothic.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 27).x + 22.0)
        var px := PILE.position.x + rng.randf_range(5.0, PILE.size.x - minf(width + 12.0, PILE.size.x))
        var py := PILE.position.y + rng.randf_range(12.0, PILE.size.y - 48.0)
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
    if (wa == "my" and wb == "verse") or (wa == "antique" and wb == "song") or (wa == "your" and wb == "eyes"):
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
            var color: Color = r.get("color",TEAL)
            var edge := _rect(i).end
            draw_line(Vector2(edge.x-2.0,edge.y-17.0),Vector2(edge.x+14.0,edge.y-17.0),color,4.0,true)
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
        draw_rect(r.grow(3),Color(INK,0.88),false,2.0)
        draw_rect(Rect2(r.position+Vector2(2,36),Vector2(6,4)),Color(INK,0.66))
        draw_circle(r.position+Vector2(r.size.x-4,39),3.0,Color(INK,0.62))
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
                draw_rect(target.grow(4),Color(ink_color,0.8),false,2.5)
                draw_circle(Vector2(target.end.x+4,target.get_center().y),5.0,ink_color)

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
            if not bool(pieces[id]["raised"]):
                discoveries.append("Return to the ink. Lift another word.")
            queue_redraw()
            accept_event()
