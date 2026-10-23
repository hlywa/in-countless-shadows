extends Control

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    var begin_label := get_node("StartButton") as Label
    begin_label.mouse_filter = Control.MOUSE_FILTER_STOP
    begin_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    begin_label.gui_input.connect(_on_begin_input)

func _on_begin_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        get_tree().change_scene_to_file("res://scenes/sonnet_player.tscn")
