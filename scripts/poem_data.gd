extends RefCounted
class_name PoemData

## Hand-authored formal data. Indices are zero-based.
## A metrical expectation is not an automatic judgment of actual scansion.

const METER_EXPECTATION := [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
const FEATURED_WORD := {
	"text": "stretchèd",
	"line_index": 11,
	"syllables": ["stretch", "èd"],
	"syllable_count": 2
}
const RHYME_PAIRS := [
	{"a": 0, "b": 2, "words": ["come", "tomb"], "class": "A"},
	{"a": 1, "b": 3, "words": ["deserts", "parts"], "class": "B"},
	{"a": 4, "b": 6, "words": ["eyes", "lies"], "class": "C"},
	{"a": 5, "b": 7, "words": ["graces", "faces"], "class": "D"},
	{"a": 8, "b": 10, "words": ["age", "rage"], "class": "E"},
	{"a": 9, "b": 11, "words": ["tongue", "song"], "class": "F"},
	{"a": 12, "b": 13, "words": ["time", "rhyme"], "class": "G"}
]

static func rhyme_partner(line_index: int) -> int:
	for pair in RHYME_PAIRS:
		if pair.a == line_index:
			return pair.b
		if pair.b == line_index:
			return pair.a
	return -1

# A small, explicitly provisional phonological lexicon. Unlike a list of
# original line endings, these families apply wherever a word is placed.
# The historical / slant pairings are hypotheses, not exact-rhyme proofs.
const SOUND_FAMILIES := {
	"come":"UM", "tomb":"UM", "some":"UM",
	"deserts":"ERTS", "parts":"ERTS",
	"eyes":"EYES", "lies":"EYES",
	"graces":"ACES", "faces":"ACES",
	"age":"AGE", "rage":"AGE",
	"tongue":"UNG", "song":"UNG",
	"time":"IME", "rhyme":"IME",
	"life":"IFE", "wife":"IFE",
	"will":"ILL", "fill'd":"ILL",
	"high":"EYE", "my":"EYE",
	"true":"OO", "you":"OO",
	"knows":"OZE", "shows":"OZE",
	"write":"ITE", "right":"ITE",
	"verse":"ERSE", "worse":"ERSE",
	"men":"EN", "then":"EN"
}
const HISTORICAL_OR_SLANT := ["UM","ERTS","UNG"]
const SYLLABLE_OVERRIDES := {
	"believe":2, "deserts":2, "heaven":2, "beauty":2, "numbers":2,
	"number":2, "graces":2, "poet":2, "heavenly":3, "earthly":2,
	"faces":2, "papers":2, "yellow'd":2, "scorn'd":1, "stretchèd":2,
	"meter":2, "antique":2, "alive":2, "twice":1, "would":1,
	"touches":2, "less":1, "term'd":1, "rage":1, "should":1
}
const ECHO_GROUPS := [["number","numbers"],["poet","poet's"],["touches","touch'd"],["age"],["time"]]
const TENSIONS := [
	["truth","lies"],["beauty","eyes"],["child","rhyme"],
	["verse","truth"],["poet","lies"],["life","tomb"]
]

static func normalize_word(word: String) -> String:
	var result := word.to_lower().strip_edges()
	while not result.is_empty() and not _is_letter(result.unicode_at(0)):
		result = result.substr(1)
	while not result.is_empty() and not _is_letter(result.unicode_at(result.length()-1)):
		result = result.substr(0,result.length()-1)
	return result

static func _is_letter(code: int) -> bool:
	return (code >= 97 and code <= 122) or code == 232

static func syllable_count(word: String) -> int:
	return int(SYLLABLE_OVERRIDES.get(normalize_word(word),1))

static func sound_family(word: String) -> String:
	return str(SOUND_FAMILIES.get(normalize_word(word),""))

static func rhyme_evidence(a: String,b: String) -> String:
	var family_a := sound_family(a)
	var family_b := sound_family(b)
	if family_a.is_empty() or family_a != family_b:
		return "unknown"
	if family_a in HISTORICAL_OR_SLANT:
		return "possible"
	return "supported"

static func echo_key(word: String) -> String:
	var normalized := normalize_word(word)
	for group in ECHO_GROUPS:
		if normalized in group:
			return str(group[0])
	return normalized

# Stress templates are pronunciation hypotheses, not definitive scansion.
# A question mark means the lexicon cannot responsibly assign stress.
const STRESS_PATTERNS := {
	"who":"1","will":"0","believe":"01","my":"0","verse":"1","in":"0",
	"time":"1","to":"0","come":"1","if":"0","it":"0","were":"0",
	"with":"0","your":"0","most":"1","high":"1","deserts":"01",
	"though":"1","yet":"1","heaven":"10","knows":"1","is":"0",
	"but":"1","as":"0","a":"0","tomb":"1","which":"0","hides":"1",
	"life":"1","and":"0","shows":"1","not":"1","half":"1",
	"parts":"1","i":"0","could":"1","write":"1","the":"0",
	"beauty":"10","of":"0","eyes":"1","fresh":"1","numbers":"10",
	"number":"10","all":"1","graces":"10","age":"1","would":"0",
	"say":"1","this":"0","poet":"10","lies":"1","such":"1",
	"heavenly":"100","touches":"10","earthly":"10","faces":"10",
	"so":"1","should":"0","papers":"10","yellow'd":"10",
	"be":"0","scorn'd":"1","like":"1","old":"1","men":"1",
	"less":"1","truth":"1","than":"0","tongue":"1","true":"1",
	"rights":"1","term'd":"1","rage":"1","stretchèd":"10",
	"meter":"10","an":"0","antique":"01","song":"1","some":"1",
	"child":"1","yours":"1","alive":"01","that":"0","you":"0",
	"live":"1","twice":"1","rhyme":"1","ne'er":"1","touch'd":"1",
	"fill'd":"1"
}
const RHETORICAL_MARKERS := ["but","yet","though","so","then","if"]
static func stress_pattern(word: String) -> String:
	var key := normalize_word(word)
	return str(STRESS_PATTERNS.get(key,"?"))

static func metrical_evidence(words: Array[String]) -> Dictionary:
	var pattern := ""
	var uncertain := 0
	for word in words:
		var stress := stress_pattern(word)
		if stress == "?":
			uncertain += 1
			for i in range(syllable_count(word)):
				pattern += "?"
		else:
			pattern += stress
	var deviations := 0
	for i in range(mini(pattern.length(),METER_EXPECTATION.size())):
		var symbol := pattern.substr(i,1)
		if symbol != "?" and int(symbol) != int(METER_EXPECTATION[i]):
			deviations += 1
	return {"pattern":pattern,"unknown_words":uncertain,"deviations":deviations,
		"syllables":pattern.length(),"candidate":pattern.length() == 10,
		"stress_verified":uncertain == 0 and deviations == 0 and pattern.length() == 10}

static func turn_evidence(previous_words: Array[String], current_words: Array[String], line_index: int) -> Dictionary:
	if current_words.is_empty():
		return {"possible":false,"reason":""}
	var first := normalize_word(current_words[0])
	if first in RHETORICAL_MARKERS and line_index > 0:
		return {"possible":true,"reason":"discourse marker, interpretation required"}
	return {"possible":false,"reason":""}
