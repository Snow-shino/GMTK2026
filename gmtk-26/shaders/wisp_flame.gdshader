shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec4 inner_color : source_color = vec4(0.82, 0.96, 1.0, 1.0);
uniform vec4 outer_color : source_color = vec4(0.05, 0.55, 1.0, 1.0);
uniform float emission_strength : hint_range(0.0, 8.0, 0.05) = 2.4;
uniform float flame_speed : hint_range(0.0, 5.0, 0.05) = 1.15;
uniform float distortion_strength : hint_range(0.0, 0.5, 0.005) = 0.18;
uniform float noise_scale : hint_range(0.5, 12.0, 0.1) = 4.2;
uniform float vertical_stretch : hint_range(0.5, 5.0, 0.05) = 2.2;
uniform float edge_power : hint_range(0.2, 8.0, 0.05) = 2.8;
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 0.52;
uniform float flicker_amount : hint_range(0.0, 1.0, 0.01) = 0.3;

varying float vertex_noise;
varying float height_mask;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 fraction = fract(p);
	vec2 smooth_fraction = fraction * fraction * (3.0 - 2.0 * fraction);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, smooth_fraction.x), mix(c, d, smooth_fraction.x), smooth_fraction.y);
}

float layered_noise(vec2 p) {
	float result = value_noise(p) * 0.58;
	result += value_noise(p * 2.07 + 7.3) * 0.28;
	result += value_noise(p * 4.13 + 19.1) * 0.14;
	return result;
}

void vertex() {
	vec2 flame_uv = vec2(UV.x * noise_scale, UV.y * noise_scale / vertical_stretch - TIME * flame_speed);
	vertex_noise = layered_noise(flame_uv);
	float height = clamp(VERTEX.y / 1.45 + 0.5, 0.0, 1.0);
	height_mask = smoothstep(0.04, 0.3, height) * (1.0 - smoothstep(0.92, 1.0, height));
	float lower_rounding = mix(0.76, 1.0, smoothstep(0.0, 0.3, height));
	float upper_taper = 1.0 - smoothstep(0.42, 1.0, height) * 0.9;
	VERTEX.xz *= max(lower_rounding * upper_taper, 0.08);
	VERTEX.y += pow(height, 3.0) * 0.32;
	float flicker = (vertex_noise - 0.5) * distortion_strength * height_mask;
	VERTEX += NORMAL * flicker * 0.55;
	VERTEX.x += flicker * (0.65 + height) + sin(TIME * flame_speed * 2.1 + height * 11.0) * flicker_amount * height * 0.035;
	VERTEX.z += cos(TIME * flame_speed * 1.7 + height * 8.0) * flicker_amount * height * 0.022;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), edge_power);
	float animated_noise = smoothstep(0.2, 0.82, vertex_noise + sin(TIME * flame_speed * 1.7) * flicker_amount * 0.08);
	float flame_mask = mix(0.52, 1.0, animated_noise) * (0.72 + height_mask * 0.28);
	vec3 flame_color = mix(inner_color.rgb, outer_color.rgb, clamp(animated_noise * 0.55 + fresnel * 0.22, 0.0, 1.0));
	ALBEDO = flame_color;
	EMISSION = flame_color * emission_strength * (0.8 + animated_noise * flicker_amount);
	ALPHA = opacity * flame_mask * (0.32 + animated_noise * 0.5 + fresnel * 0.18);
}
