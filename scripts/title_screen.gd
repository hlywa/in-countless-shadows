extends Control
## The original UnifrakturCook Label stays intact; an ink mask reveals its glyphs.
const REVEAL_DURATION := 3.1
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
uniform float glyph_count = 21.0;
float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}
void fragment() {
	vec4 glyph = texture(TEXTURE, UV) * COLOR;
	// Each approximate glyph cell receives its own pen gesture instead
	// of exposing the entire line behind one left-to-right wipe.
	float cell = floor(UV.x * glyph_count);
	float local_x = fract(UV.x * glyph_count);
	float local_y = UV.y;
	float phase = clamp(progress * glyph_count - cell, 0.0, 1.0);
	float stroke_a = 0.0;
	float stroke_b = 0.0;
	float stroke_c = 0.0;
	// Downstroke, return diagonal, and finishing stroke. These are
	// editorial writing gestures, not authentic font stroke outlines.
	float a = clamp(phase * 2.8,0.0,1.0);
	float b = clamp((phase-0.34)*3.1,0.0,1.0);
	float c = clamp((phase-0.67)*3.3,0.0,1.0);
	float direction = mod(cell,2.0);
	float down = mix(local_y,1.0-local_y,direction);
	float grain = (hash21(floor(UV*vec2(880.0,260.0)))-0.5)*0.055;
	stroke_a = 1.0-smoothstep(a-0.10,a+0.07,down*0.72+local_x*0.28+grain);
	stroke_b = 1.0-smoothstep(b-0.10,b+0.08,(1.0-local_x)*0.68+(1.0-down)*0.32+grain);
	stroke_c = 1.0-smoothstep(c-0.12,c+0.06,local_x*0.75+down*0.25+grain);
	float revealed = max(stroke_a,max(stroke_b,stroke_c));
	// The whole glyph is fully opaque once its writing interval ends.
	revealed = max(revealed,step(0.999,phase));
	COLOR = vec4(glyph.rgb,glyph.a*revealed);
}
"""
	ink_material = ShaderMaterial.new()
	ink_material.shader = ink_shader
	title_label.material = ink_material
	ink_material.set_shader_parameter("progress",0.0)
	ink_material.set_shader_parameter("glyph_count",float(maxi(1,title_label.text.length())))
	begin_label.modulate.a = 0.0
	settings_label.modulate.a = 0.0
	begin_label.mouse_filter = Control.MOUSE_FILTER_STOP
	begin_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	begin_label.gui_input.connect(_on_begin_input)

func _process(delta: float) -> void:
	elapsed += delta
	var t := clampf(elapsed / REVEAL_DURATION,0.0,1.0)
	# Each letter receives several directional reveals, followed by an ink-settling finish.
	ink_material.set_shader_parameter("progress",t)
	var buttons := smoothstep(2.2,3.1,elapsed)
	begin_label.modulate.a = buttons
	settings_label.modulate.a = buttons
	if elapsed >= REVEAL_DURATION:
		set_process(false)

func _on_begin_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://scenes/sonnet_player.tscn")
