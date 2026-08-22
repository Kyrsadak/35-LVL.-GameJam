shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 tile_color : source_color = vec4(0.88, 0.84, 0.77, 1.0);       // Warm cream stone
uniform vec4 inner_tile_color : source_color = vec4(0.92, 0.89, 0.83, 1.0); // Soft ivory center
uniform vec4 grout_color : source_color = vec4(0.72, 0.67, 0.60, 1.0);      // Subtle warm grout
uniform float tile_scale = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Simple procedural hash for subtle surface grain
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = world_pos.xz * tile_scale;
	vec2 grid = fract(uv);
	vec2 f_dist = abs(grid - vec2(0.5));
	float border = max(f_dist.x, f_dist.y);
	
	// Smooth grout seam
	float is_grout = smoothstep(0.46, 0.49, border);
	
	// Subtle inner bevel
	float is_center = 1.0 - smoothstep(0.20, 0.45, border);
	
	// Subtle natural stone grain
	float grain = (hash(floor(world_pos.xz * 64.0)) - 0.5) * 0.03;
	
	vec3 base = mix(tile_color.rgb, inner_tile_color.rgb, is_center * 0.5);
	base = mix(base, grout_color.rgb, is_grout);
	base += vec3(grain);
	
	ALBEDO = base;
	METALLIC = 0.02;
	ROUGHNESS = mix(0.80, 0.95, is_grout);
	EMISSION = vec3(0.0);
}
