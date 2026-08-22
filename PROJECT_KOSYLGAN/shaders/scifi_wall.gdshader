shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 wall_color : source_color = vec4(0.20, 0.24, 0.32, 1.0);
uniform vec4 panel_color : source_color = vec4(0.26, 0.30, 0.39, 1.0);
uniform vec4 hazard_yellow : source_color = vec4(0.95, 0.72, 0.08, 1.0);
uniform vec4 hazard_black : source_color = vec4(0.10, 0.11, 0.14, 1.0);
uniform vec4 led_color : source_color = vec4(0.0, 0.85, 1.0, 1.0);

varying vec3 world_pos;
varying vec3 local_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_pos = VERTEX;
}

void fragment() {
	float y = world_pos.y;
	float horiz_coord = (abs(NORMAL.z) > 0.5) ? world_pos.x : world_pos.z;
	
	// Vertical panel columns (every 2.0m)
	float col_fract = fract(horiz_coord * 0.5);
	float is_vertical_seam = step(0.94, col_fract) + step(col_fract, 0.06);
	
	vec3 col = wall_color.rgb;
	float emit = 0.0;
	
	if (y < 0.45) {
		// Bottom hazard strip
		float stripe_uv = (horiz_coord + y) * 3.5;
		float is_yellow = step(0.5, fract(stripe_uv));
		col = mix(hazard_black.rgb, hazard_yellow.rgb, is_yellow);
	} else if (y < 2.7) {
		// Main wall panel
		float inner_panel = step(0.12, col_fract) * step(col_fract, 0.88) * step(0.55, y) * step(y, 2.55);
		col = mix(wall_color.rgb, panel_color.rgb, inner_panel);
		
		// Tech indicator LED at top of panel
		float is_led = step(abs(col_fract - 0.5), 0.04) * step(abs(y - 2.4), 0.03);
		if (is_led > 0.5) {
			col = led_color.rgb;
			emit = 1.2;
		}
	} else {
		// Top cornice
		col = wall_color.rgb * 0.8;
	}
	
	col = mix(col, hazard_black.rgb, is_vertical_seam * 0.4);
	
	ALBEDO = col;
	METALLIC = 0.7;
	ROUGHNESS = 0.4;
	EMISSION = led_color.rgb * emit;
}
