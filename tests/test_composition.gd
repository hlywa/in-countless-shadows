extends SceneTree
# Run: godot --headless --path . --script res://tests/test_composition.gd
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/sonnet_player.tscn")
	var player = scene.instantiate()
	root.add_child(player)
	await process_frame
	var state: CompositionState = player.composition
	check(state.placed_count() == 0,"Initial stage should be empty")
	var original: Array = []
	for n in range(14):
		original.append([])
	for i in range(player.pieces.size()):
		var n: int = player.pieces[i]["line"]
		original[n].append(i)
	check(state.restore(original),"Original word ordering must be restorable")
	player._layout_composition()
	var model: Dictionary = player._analyze_composition(false)
	check(model["complete"],"Reconstructed original must contain all words")
	check(model["filled"] == 14,"Reconstructed original must fill fourteen lines")
	check(model["rhymes"] == 7,"All seven original editorial rhyme relationships should be recognized")
	check(model["tentative_rhymes"] == 3,"Three original rhyme relationships remain editorial hypotheses")
	var original_snapshot := state.capture()
	check(not state.insert_word(-1,0,0),"Invalid word ID must be rejected")
	check(not state.insert_word(0,14,0),"Invalid line must be rejected")
	check(not state.restore([[0]]),"Invalid number of lines must be rejected")
	var duplicate: Array = state.capture()
	duplicate[1].append(duplicate[0][0])
	check(not state.restore(duplicate),"Duplicate IDs must be rejected")
	check(state.capture() == original_snapshot,"Rejected restores must not mutate composition")
	state.remove_word(0)
	check(state.placed_count() == player.pieces.size()-1,"Removing a word makes poem incomplete")
	check(not player._analyze_composition(false)["complete"],"Incomplete composition must not pass")
	check(state.restore(original_snapshot),"Undo-like restoration must work")
	var before := state.capture()
	check(state.insert_word(0,1,0),"Word must move to a new line")
	check(state.find_line(0) == 1,"Word moves between lines by ID")
	check(state.capture() != before,"Alternative arrangement changes composition")
	check(state.restore(before),"Snapshot restores exact ordered IDs")
	var poetry = load("res://scripts/poem_data.gd")
	var separated: Array = []
	for n in range(14):
		separated.append([])
	separated[0] = ["life","tomb"]
	separated[12] = ["child","rhyme"]
	var readings: Array[String] = poetry.reading_hypotheses(separated)
	check(readings.size() >= 2,"Multiple arrangement-sensitive readings can coexist")
	separated[0] = ["life"]
	separated[12] = ["child"]
	check(poetry.reading_hypotheses(separated).size() < readings.size(),"Moving words changes readings")
	print("Composition regression: PASS" if failures == 0 else "Composition regression: %d failures" % failures)
	quit(0 if failures == 0 else 1)
