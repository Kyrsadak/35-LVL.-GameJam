shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 tile_color : source_color = vec4(0.80, 0.76, 0.70, 1.0);       // Warm architectural composite tile
uniform vec4 inner_tile_color : source_color = vec4(0.86, 0.83, 0.77, 1.0); // Soft center
uniform vec4 grout_color : source_color = vec4(0.48, 0.43, 0.36, 1.0);      // Distinct dark warm grout
uniform float tile_scale = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = world_pos.xz * tile_scale;
	vec2 grid = fract(uv);
	vec2 f_dist = abs(grid - vec2(0.5));
	float border = max(f_dist.x, f_dist.y);
	
	// Crisp, well-defined grout lines
	float is_grout = smoothstep(0.44, 0.48, border);
	
	// Subtle inner tile bevel
	float is_center = 1.0 - smoothstep(0.25, 0.44, border);
	
	// Subtle natural fine composite grain
	float grain = (hash(floor(world_pos.xz * 48.0)) - 0.5) * 0.025;
	
	vec3 base = mix(tile_color.rgb, inner_tile_color.rgb, is_center * 0.4);
	base = mix(base, grout_color.rgb, is_grout);
	base += vec3(grain);
	
	ALBEDO = base;
	METALLIC = 0.05;
	ROUGHNESS = mix(0.75, 0.92, is_grout);
	EMISSION = vec3(0.0);
}
