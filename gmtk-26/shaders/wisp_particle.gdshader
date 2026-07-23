shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 particle_color : source_color = vec4(0.25, 0.78, 1.0, 1.0);
uniform float emission_strength : hint_range(0.0, 10.0, 0.1) = 3.5;

varying float lifetime_fade;

void vertex() {
	float lifetime = clamp(INSTANCE_CUSTOM.y, 0.0, 1.0);
	float shrink = mix(1.0, 0.08, smoothstep(0.2, 1.0, lifetime));
	VERTEX *= shrink;
	lifetime_fade = 1.0 - smoothstep(0.62, 1.0, lifetime);
}

void fragment() {
	float distance_from_center = length(UV - vec2(0.5));
	float soft_circle = smoothstep(0.5, 0.08, distance_from_center);
	float hot_core = smoothstep(0.28, 0.0, distance_from_center);
	vec3 color = particle_color.rgb * mix(vec3(1.0), vec3(1.35), hot_core * 0.8);
	ALBEDO = color;
	EMISSION = color * emission_strength;
	ALPHA = soft_circle * particle_color.a * lifetime_fade;
}
