extends Node
## One persisted sound preference shared by every scene.
const SETTINGS_PATH := "user://settings.cfg"
var sound_enabled := true

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		sound_enabled = bool(config.get_value("audio", "sound_enabled", true))
	_apply_audio()

func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	_apply_audio()
	var config := ConfigFile.new()
	config.set_value("audio", "sound_enabled", sound_enabled)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save sound preference: %s" % error)

func _apply_audio() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, not sound_enabled)
