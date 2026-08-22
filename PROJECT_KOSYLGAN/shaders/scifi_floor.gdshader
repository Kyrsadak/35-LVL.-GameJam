shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 tile_color : source_color = vec4(0.13, 0.16, 0.22, 1.0);
uniform vec4 inner_tile_color : source_color = vec4(0.18, 0.22, 0.29, 1.0);
uniform vec4 seam_color : source_color = vec4(0.06, 0.08, 0.11, 1.0);
uniform vec4 node_glow_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform float tile_scale = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz * tile_scale;
	vec2 grid = fract(uv);
	vec2 f_dist = abs(grid - vec2(0.5));
	float border = max(f_dist.x, f_dist.y);
	
	// Seam lines
	float is_seam = step(0.46, border);
	
	// Inner bevel
	float is_inner = step(border, 0.40);
	
	// Corner nodes
	float corner_dist = distance(grid, round(grid));
	float is_node = 1.0 - smoothstep(0.04, 0.09, corner_dist);
	
	// Diamond grip in center
	float diamond = abs(grid.x - 0.5) + abs(grid.y - 0.5);
	float is_diamond = 1.0 - step(0.16, diamond);
	
	vec3 base = mix(tile_color.rgb, inner_tile_color.rgb, is_inner);
	base = mix(base, tile_color.rgb * 0.8, is_diamond * 0.5);
	base = mix(base, seam_color.rgb, is_seam);
	
	ALBEDO = base;
	METALLIC = mix(0.7, 0.2, is_seam);
	ROUGHNESS = mix(0.35, 0.8, is_seam);
	
	// Glow on corner nodes
	EMISSION = node_glow_color.rgb * is_node * 0.6;
}
