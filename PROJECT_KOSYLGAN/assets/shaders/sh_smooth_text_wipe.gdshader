shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.01, 0.4) = 0.14;

void fragment() {
	vec4 col = COLOR;
	float edge = progress * (1.0 + softness * 2.0) - softness;
	float alpha_mask = 1.0 - smoothstep(edge - softness, edge + softness, UV.x);
	col.a *= clamp(alpha_mask, 0.0, 1.0);
	COLOR = col;
}
