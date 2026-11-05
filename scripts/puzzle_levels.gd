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
		"next":"sonnet17_rhyme"
	},
	{
		"id":"sonnet17_rhyme",
		"title":"II. The Echo",
		"subtitle":"An ending makes a promise.",
		"instruction":"Choose the two line endings that answer each other in sound.",
		"sonnet":17,
		"mode":"rhyme_pair",
		"first_stem":"But were some child of yours alive that",
		"second_stem":"You should live twice; in it, and in my",
		"choices":["time","rhyme","eyes","lies","age","rage"],
		"solution":["time","rhyme"],
		"next":"sonnet17_measure"
	},
	{
		"id":"sonnet17_measure",
		"title":"III. The Measure",
		"subtitle":"A line has a pulse.",
		"instruction":"Choose a reading, then explore its ten syllable positions.",
		"sonnet":17,
		"mode":"meter_experiment",
		"readings":[
			{"id":"couplet","text":"You should live twice; in it, and in my rhyme.","words":["You","should","live","twice;","in","it,","and","in","my","rhyme."]},
			{"id":"stretch","text":"And stretchèd meter of an antique song:","words":["And","stretchèd","meter","of","an","antique","song:"]}
		],
		"next":"sonnet17_full"
	},
	{
		"id":"sonnet17_full",
		"title":"IV. The Whole Sonnet",
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

# A description of the rhetorical effect of a given ordering, not a quality score.
static func turn_reading(level: Dictionary, order: Array) -> Dictionary:
	if not valid_order(level,order):
		return {"heading":"Incomplete arrangement","lines":["All three passages are needed."]}
	if discovered_turn(level,order):
		return {"heading":"A conditional answer","lines":["The poet's doubt comes first.","'But' introduces another possibility.","The final line offers a consequence."]}
	var first: String = str(order[0])
	if first == "answer":
		return {"heading":"A promise before its premise","lines":["The promise of living twice comes first.","The explanation arrives only afterward.","How does that change its force?"]}
	if first == "condition":
		return {"heading":"A condition before the doubt","lines":["The possible child leads the passage.","The poet's doubt now interrupts it.","Which thought feels like a reply?"]}
	return {"heading":"An unsettled turn","lines":["The doubt begins the passage.","The final thought changes its direction.","Try placing the condition between them."]}

static func rhyme_evaluation(level: Dictionary, selected: Array) -> Dictionary:
	if str(level.get("mode","")) != "rhyme_pair" or selected.size() != 2:
		return {"status":"incomplete","heading":"Choose two endings","detail":"Place one word in each line."}
	var a := str(selected[0])
	var b := str(selected[1])
	if a.is_empty() or b.is_empty():
		return {"status":"incomplete","heading":"An echo is waiting","detail":"Choose an ending for each line."}
	if a == b:
		return {"status":"invalid","heading":"One word, two places","detail":"Each movable word can only be used once."}
	var evidence: String = PoemData.rhyme_evidence(a,b)
	if evidence == "supported":
		var solution: Array = level.get("solution",[])
		var original := a == str(solution[0]) and b == str(solution[1])
		return {"status":"supported","heading":"A rhyme connects these lines","detail":"These endings share a recorded sound family.","original":original}
	if evidence == "possible":
		return {"status":"possible","heading":"A possible echo","detail":"This pairing has an editorial or historical uncertainty."}
	return {"status":"unknown","heading":"No recorded rhyme yet","detail":"Try another pair. This lexicon is incomplete."}

static func rhyme_match(level: Dictionary, selected: Array) -> bool:
	return str(rhyme_evaluation(level,selected).get("status","")) == "supported"

static func meter_reading(words: Array) -> Dictionary:
	var total := 0
	var unknown := 0
	var slots: Array = []
	for word in words:
		var spelling := str(word)
		var count := PoemData.syllable_count(spelling)
		var key := PoemData.normalize_word(spelling)
		var documented := PoemData.SYLLABLE_OVERRIDES.has(key) or PoemData.STRESS_PATTERNS.has(key)
		if not documented:
			unknown += 1
		for i in range(count):
			slots.append({"word":spelling,"position":total+i+1})
		total += count
	return {"syllables":total,"unknown_words":unknown,"slots":slots,"ten_positions":total == 10}

# User-marked emphasis is an experiment, not an automatic scansion.
# Each index corresponds to a syllable position in meter_reading().
static func stress_comparison(words: Array, emphasized: Array) -> Dictionary:
	var reading: Dictionary = meter_reading(words)
	var count: int = int(reading["syllables"])
	if emphasized.size() != count:
		return {"valid":false,"aligned":0,"departures":0,"count":count}
	var aligned := 0
	var departures := 0
	for i in range(count):
		if not (emphasized[i] is bool):
			return {"valid":false,"aligned":0,"departures":0,"count":count}
		var expected_strong := i % 2 == 1
		if bool(emphasized[i]) == expected_strong:
			aligned += 1
		else:
			departures += 1
	return {"valid":true,"aligned":aligned,"departures":departures,"count":count}
