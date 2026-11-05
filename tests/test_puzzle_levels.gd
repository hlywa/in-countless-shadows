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
	check(PuzzleLevels.valid_order(level,["doubt","condition","answer"]),"All authored units should be recognized")
	check(not PuzzleLevels.valid_order(level,["doubt","doubt","answer"]),"Duplicate units should be rejected")
	check(not PuzzleLevels.valid_order(level,["doubt","answer"]),"Missing units should be rejected")
	check(not PuzzleLevels.discovered_turn(level,level["initial_order"]),"Initial order must not already satisfy the discovery")
	check(PuzzleLevels.discovered_turn(level,["doubt","condition","answer"]),"Turn between doubt and answer should count as a discovery")
	check(not PuzzleLevels.discovered_turn(level,["condition","doubt","answer"]),"Turn placed before doubt should not count")
	check(not PuzzleLevels.discovered_turn(level,["doubt","answer","condition"]),"Turn placed after consequence should not count")
	print("Puzzle levels: PASS" if failures == 0 else "Puzzle levels: %d failures" % failures)
	quit(0 if failures == 0 else 1)
