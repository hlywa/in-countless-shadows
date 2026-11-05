extends SceneTree
## Run: godot --headless --path . --editor --quit
## Then: godot --headless --path . --script res://tests/test_scene_smoke.gd
## Scene loading checks resources and script parsing, not visual correctness.
var failures := 0

func _initialize() -> void:
	for path in [
		"res://main.tscn",
		"res://scenes/title_screen.tscn",
		"res://scenes/volta_level.tscn",
		"res://scenes/rhyme_level.tscn",
		"res://scenes/meter_level.tscn",
		"res://scenes/sonnet_player.tscn"
	]:
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("Cannot load scene: " + path)
			failures += 1
			continue
		var instance := packed.instantiate()
		if instance == null:
			push_error("Cannot instantiate scene: " + path)
			failures += 1
		else:
			instance.free()
	print("Scene smoke: PASS" if failures == 0 else "Scene smoke: %d failures" % failures)
	quit(0 if failures == 0 else 1)
