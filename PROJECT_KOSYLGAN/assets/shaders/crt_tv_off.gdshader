shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float collapse_v : hint_range(0.0, 1.0) = 0.0; // 0.0 = full screen, 1.0 = collapsed to horizontal line
uniform float collapse_h : hint_range(0.0, 1.0) = 0.0; // 0.0 = full width, 1.0 = collapsed to central dot
uniform float dot_fade : hint_range(0.0, 1.0) = 0.0;   // 0.0 = bright dot, 1.0 = pitch black
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Vertical collapse bounds
	float half_v = max(0.0008, (1.0 - collapse_v) * 0.5);
	float min_y = 0.5 - half_v;
	float max_y = 0.5 + half_v;
	
	// Horizontal collapse bounds
	float half_h = max(0.0008, (1.0 - collapse_h) * 0.5);
	float min_x = 0.5 - half_h;
	float max_x = 0.5 + half_h;
	
	if (uv.y < min_y || uv.y > max_y || uv.x < min_x || uv.x > max_x) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}
	
	vec2 sample_uv = vec2(
		(uv.x - min_x) / (max_x - min_x),
		(uv.y - min_y) / (max_y - min_y)
	);
	
	vec4 screen_col = texture(screen_texture, sample_uv);
	
	// High-energy phosphor beam compression
	float boost = 1.0 + collapse_v * 2.5 + collapse_h * 4.0;
	
	// Center beam glowing line and point
	float dist_y = abs(uv.y - 0.5) / half_v;
	float dist_x = abs(uv.x - 0.5) / half_h;
	float line_intensity = (1.0 - dist_y) * collapse_v * 1.5;
	float dot_intensity = (1.0 - max(dist_x, dist_y)) * collapse_h * 3.0;
	
	vec3 col = screen_col.rgb * boost;
	col += vec3(0.85, 0.95, 1.0) * (line_intensity + dot_intensity);
	col += vec3(1.0, 1.0, 1.0) * flash;
	
	// Phosphor decay to black
	col = mix(col, vec3(0.0), dot_fade);
	
	COLOR = vec4(col, 1.0);
}
