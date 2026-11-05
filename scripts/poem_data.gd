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
