extends SceneTree
# Run with: godot --headless --path . --script res://tests/test_puzzle_levels.gd
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var level := PuzzleLevels.get_level("sonnet17_turn")
	check(not level.is_empty(),"Opening level must exist")
	check(PuzzleLevels.get_level("sonnet17_full").get("mode","") == "free_composition","Full-sonnet mode must be defined")
	var rhyme := PuzzleLevels.get_level("sonnet17_rhyme")
	check(rhyme.get("mode","") == "rhyme_pair","Rhyme level must exist")
	check(level.get("next","") == "sonnet17_rhyme","Turn must lead to rhyme")
	check(rhyme.get("next","") == "sonnet17_measure","Rhyme must lead to measure")
	var meter := PuzzleLevels.get_level("sonnet17_measure")
	check(meter.get("next","") == "sonnet17_full","Measure must lead to full sonnet")
	check(meter.get("mode","") == "meter_experiment","Measure level must exist")
	for reading in meter["readings"]:
		var estimate: Dictionary = PuzzleLevels.meter_reading(reading["words"])
		check(int(estimate["syllables"]) == 10,"Both authored readings should have ten estimated syllables")
		check(estimate["ten_positions"],"Ten-position result must be explicit")
		var alternate: Array = []
		for i in range(int(estimate["syllables"])):
			alternate.append(i % 2 == 1)
		var standard: Dictionary = PuzzleLevels.stress_comparison(reading["words"],alternate)
		check(standard["valid"] and int(standard["departures"]) == 0,"Alternating emphasis should match its own model")
		alternate[0] = not bool(alternate[0])
		var varied: Dictionary = PuzzleLevels.stress_comparison(reading["words"],alternate)
		check(varied["valid"] and int(varied["departures"]) == 1,"Player emphasis change must register as a departure")
		check(not PuzzleLevels.stress_comparison(reading["words"],[true])["valid"],"Wrong-sized emphasis array must be rejected")
	check(PuzzleLevels.rhyme_match(rhyme,["time","rhyme"]),"Authored rhyme should complete")
	check(not PuzzleLevels.rhyme_match(rhyme,["song","age"]),"Unrelated endings must not complete")
	check(PuzzleLevels.rhyme_match(rhyme,["eyes","lies"]),"Alternative supported rhyme should complete")
	check(PuzzleLevels.rhyme_match(rhyme,["age","rage"]),"Another supported rhyme should complete")
	check(PuzzleLevels.rhyme_evaluation(rhyme,["eyes","lies"]).get("original",true) == false,"Alternative rhyme must not be called Shakespeare's original")
	check(PuzzleLevels.rhyme_evaluation(rhyme,["time","rhyme"]).get("original",false) == true,"Original rhyme should be identified")
	check(PuzzleLevels.rhyme_evaluation(rhyme,["","rhyme"]).get("status","") == "incomplete","Incomplete rhyme should not be scored")
	check(PuzzleLevels.rhyme_evaluation(rhyme,["age","eyes"]).get("status","") == "unknown","Unsupported rhyme should be uncertain, not called bad")
	check(not PuzzleLevels.rhyme_match(rhyme,["rhyme","time"]),"Reversed endings must not count as original couplet")
	var alternative := PuzzleLevels.turn_reading(level,["answer","doubt","condition"])
	check(str(alternative.get("heading","")) == "A promise before its premise","Alternative ordering should have distinct reading")
	check(PuzzleLevels.valid_order(level,["doubt","condition","answer"]),"All authored units should be recognized")
	check(not PuzzleLevels.valid_order(level,["doubt","doubt","answer"]),"Duplicate units should be rejected")
	check(not PuzzleLevels.valid_order(level,["doubt","answer"]),"Missing units should be rejected")
	check(not PuzzleLevels.discovered_turn(level,level["initial_order"]),"Initial order must not already satisfy the discovery")
	check(PuzzleLevels.discovered_turn(level,["doubt","condition","answer"]),"Turn between doubt and answer should count as a discovery")
	check(not PuzzleLevels.discovered_turn(level,["condition","doubt","answer"]),"Turn placed before doubt should not count")
	check(not PuzzleLevels.discovered_turn(level,["doubt","answer","condition"]),"Turn placed after consequence should not count")
	print("Puzzle levels: PASS" if failures == 0 else "Puzzle levels: %d failures" % failures)
	quit(0 if failures == 0 else 1)
