extends SceneTree
## Headless guard for shared navigation and the introductory escape path.
const Navigation = preload("res://scripts/puzzle_navigation.gd")

func _initialize() -> void:
	var failures := 0
	var center := Navigation.MENU_RECT.get_center()
	var menu_click := InputEventMouseButton.new()
	menu_click.button_index = MOUSE_BUTTON_LEFT
	menu_click.pressed = true
	menu_click.position = center
	if not Navigation.is_menu_press(menu_click):
		push_error("Main-menu button does not accept primary clicks.")
		failures += 1
	menu_click.position = Vector2(200, 200)
	if Navigation.is_menu_press(menu_click):
		push_error("Outside click was mistaken for menu navigation.")
		failures += 1
	menu_click.position = center
	menu_click.pressed = false
	if Navigation.is_menu_press(menu_click):
		push_error("Release was mistaken for menu navigation.")
		failures += 1
	var turn := load("res://scenes/volta_level.tscn") as PackedScene
	if turn == null:
		push_error("Turn scene missing.")
		failures += 1
	else:
		var instance := turn.instantiate()
		if instance == null:
			push_error("Turn scene cannot be instantiated.")
			failures += 1
		else:
			if not instance.get("showing_introduction"):
				push_error("Turn introduction no longer starts visible.")
				failures += 1
			instance.free()
	print("Navigation tests: PASS" if failures == 0 else "Navigation tests: %d failures" % failures)
	quit(0 if failures == 0 else 1)
