extends Control
## The original UnifrakturCook Label stays intact; an ink mask reveals its glyphs.
const REVEAL_DURATION := 2.3
var title_label: Label
var begin_label: Label
var settings_label: Label
var elapsed := 0.0
var ink_material: ShaderMaterial

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	title_label = get_node("Title") as Label
	begin_label = get_node("StartButton") as Label
	settings_label = get_node("SettingsButton") as Label
	# Render the font ONCE. Earlier overlapping draw_string passes caused
	# doubled gray shadows and incorrect letter spacing.
	title_label.visible = true
	var ink_shader := Shader.new()
	ink_shader.code = """
shader_type canvas_item;
render_mode unshaded;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
	vec4 glyph = texture(TEXTURE, UV) * COLOR;
	// The front advances across the line with fine irregularities like
	// ink catching in the paper. This is a glyph reveal, not handwriting
	// stroke-order reconstruction.
	float grain = hash21(floor(UV * vec2(720.0, 130.0))) - 0.5;
	float flow = UV.x * 0.93 + UV.y * 0.07 + grain * 0.045;
	float reveal = 1.0 - smoothstep(progress - 0.045, progress + 0.035, flow);
	COLOR = vec4(glyph.rgb, glyph.a * reveal);
}
"""
	ink_material = ShaderMaterial.new()
	ink_material.shader = ink_shader
	title_label.material = ink_material
	ink_material.set_shader_parameter("progress",0.0)
	begin_label.modulate.a = 0.0
	settings_label.modulate.a = 0.0
	begin_label.mouse_filter = Control.MOUSE_FILTER_STOP
	begin_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	begin_label.gui_input.connect(_on_begin_input)

func _process(delta: float) -> void:
	elapsed += delta
	var t := clampf(elapsed / REVEAL_DURATION,0.0,1.0)
	# The ink first touches the left edge, then advances to the right.
	ink_material.set_shader_parameter("progress",t * 1.12)
	var buttons := smoothstep(1.55,2.3,elapsed)
	begin_label.modulate.a = buttons
	settings_label.modulate.a = buttons
	if elapsed >= REVEAL_DURATION:
		set_process(false)

func _on_begin_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://scenes/sonnet_player.tscn")
