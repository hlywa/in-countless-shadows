extends RefCounted
class_name PuzzleNavigation
## Shared navigation for canvas-drawn experiments.
## The rectangle is expressed in the Control's local coordinate space.
const MENU_SCENE := "res://main.tscn"
const MENU_RECT := Rect2(1030, 20, 215, 48)
const MENU_COLOR := Color("#477e7b")
const PAPER_COLOR := Color("#f4efe3")

static func is_primary_press(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed

static func is_menu_press(event: InputEvent) -> bool:
	return is_primary_press(event) and MENU_RECT.has_point(event.position)

static func return_to_menu(screen: Control) -> void:
	screen.get_tree().change_scene_to_file(MENU_SCENE)

static func draw_menu(screen: Control, font: Font) -> void:
	screen.draw_rect(MENU_RECT, MENU_COLOR)
	screen.draw_string(font, MENU_RECT.position + Vector2(14, 31), "← Main menu", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, PAPER_COLOR)
