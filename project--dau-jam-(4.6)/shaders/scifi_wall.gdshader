shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 wall_color : source_color = vec4(0.91, 0.88, 0.82, 1.0);       // Warm cream linen wall
uniform vec4 panel_color : source_color = vec4(0.85, 0.81, 0.74, 1.0);      // Soft sand panel
uniform vec4 trim_color : source_color = vec4(0.35, 0.30, 0.25, 1.0);       // Warm matte walnut/bronze trim
uniform vec4 seam_color : source_color = vec4(0.70, 0.65, 0.58, 1.0);       // Subtle recessed panel seam

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float y = world_pos.y;
	float horiz_coord = (abs(NORMAL.z) > 0.5) ? world_pos.x : world_pos.z;
	
	// Vertical panel columns (every 2.0m)
	float col_fract = fract(horiz_coord * 0.5);
	float is_vertical_seam = smoothstep(0.96, 0.98, col_fract) + (1.0 - smoothstep(0.02, 0.04, col_fract));
	
	vec3 col = wall_color.rgb;
	float roughness_val = 0.85;
	
	if (y < 0.25) {
		// Clean warm dark baseboard trim
		col = trim_color.rgb;
		roughness_val = 0.75;
	} else if (y < 2.7) {
		// Main architectural panel
		float inner_panel = step(0.08, col_fract) * step(col_fract, 0.92) * step(0.35, y) * step(y, 2.6);
		col = mix(wall_color.rgb, panel_color.rgb, inner_panel * 0.6);
	} else {
		// Top cornice trim
		col = trim_color.rgb * 1.2;
		roughness_val = 0.75;
	}
	
	col = mix(col, seam_color.rgb, is_vertical_seam * 0.5);
	
	// Subtle fine plaster/matte grain
	float grain = (hash(floor(world_pos.xy * 48.0)) - 0.5) * 0.02;
	col += vec3(grain);
	
	ALBEDO = col;
	METALLIC = 0.02;
	ROUGHNESS = roughness_val;
	EMISSION = vec3(0.0);
}
