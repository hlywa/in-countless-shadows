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
