extends SceneTree
# Run with: godot --headless --path . --script res://tests/test_poem_data.gd
# These are deterministic lexical and interpretive regressions, not performance proof.
var failures := 0

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	var poem = load("res://scripts/poem_data.gd")
	_check(poem.syllable_count("poet's") == 2, "poet's is two syllables")
	_check(poem.syllable_count("stretchèd") == 2, "stretchèd preserves two syllables")
	_check(poem.syllable_count("believe") == 2, "believe has two syllables")
	_check(poem.rhyme_evidence("eyes","lies;") == "supported", "eyes / lies rhyme")
	_check(poem.rhyme_evidence("high","eyes") == "supported", "high / eyes share rime")
	_check(poem.rhyme_evidence("come,","tomb") == "possible", "original A pair is editorial")
	_check(poem.rhyme_evidence("deserts?","parts.") == "possible", "original B pair is editorial")
	_check(poem.rhyme_evidence("tongue,","song:") == "possible", "original F pair is editorial")
	_check(poem.rhyme_evidence("beauty","rhyme") == "unknown", "unrelated ending not forced")
	var empty: Array[String] = []
	_check(not poem.turn_evidence(empty,empty,12)["possible"], "empty line cannot turn")
	var marker: Array[String] = ["But","were","some","child"]
	_check(poem.turn_evidence(empty,marker,12)["possible"], "line-13 But is a turn clue")
	var ambiguous: Array[String] = ["the","will","of","time"]
	_check(poem.metrical_evidence(ambiguous)["unknown_words"] > 0, "function-word stress is uncertain")
	var reading: Array = []
	for n in range(14):
		reading.append([])
	reading[0] = ["life","tomb","truth","lies"]
	_check(poem.reading_hypotheses(reading).size() >= 2, "interpretations can coexist")
	print("PoemData regressions: ", "PASS" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
