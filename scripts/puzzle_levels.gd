extends RefCounted
class_name PuzzleLevels
## Authored discoveries are not machine judgments of poetic beauty.
const LEVELS := [
	{
		"id":"sonnet17_turn",
		"title":"I. The Turn",
		"subtitle":"A poem can change its mind.",
		"instruction":"Arrange these passages. Can the final thought answer the first?",
		"sonnet":17,
		"units":[
			{"id":"doubt","label":"A doubt","text":"And your true rights be term'd a poet's rage\nAnd stretchèd meter of an antique song:"},
			{"id":"condition","label":"A possibility","text":"But were some child of yours alive that time,"},
			{"id":"answer","label":"A consequence","text":"You should live twice; in it, and in my rhyme."}
		],
		"initial_order":["answer","doubt","condition"],
		"discovery":{"before":"doubt","turn":"condition","after":"answer"},
		"next":"sonnet17_full"
	},
	{
		"id":"sonnet17_full",
		"title":"II. The Whole Sonnet",
		"subtitle":"Explore fourteen lines, rhyme, and rhythm.",
		"instruction":"Recompose the poem, or create another from its words.",
		"sonnet":17,
		"mode":"free_composition"
	}
]

static func get_level(id: String) -> Dictionary:
	for level in LEVELS:
		if str(level["id"]) == id:
			return level.duplicate(true)
	return {}

static func valid_order(level: Dictionary, order: Array) -> bool:
	var units: Array = level.get("units",[])
	if order.size() != units.size():
		return false
	var expected := {}
	for unit in units:
		expected[str(unit["id"])] = true
	for id in order:
		if not expected.erase(str(id)):
			return false
	return expected.is_empty()

static func discovered_turn(level: Dictionary, order: Array) -> bool:
	if not valid_order(level,order) or not level.has("discovery"):
		return false
	var rule: Dictionary = level["discovery"]
	return order.find(rule["before"]) < order.find(rule["turn"]) and order.find(rule["turn"]) < order.find(rule["after"])
