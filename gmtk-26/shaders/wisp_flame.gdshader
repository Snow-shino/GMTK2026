shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform float flame_speed_1 : hint_range(0.0, 5.0, 0.05) = 1.35;
uniform float flame_speed_2 : hint_range(0.0, 5.0, 0.05) = 0.82;
uniform float noise_scale_1 : hint_range(0.5, 12.0, 0.1) = 4.6;
uniform float noise_scale_2 : hint_range(0.5, 12.0, 0.1) = 7.3;
uniform float cutoff : hint_range(0.0, 1.0, 0.01) = 0.54;
uniform float softness : hint_range(0.01, 0.4, 0.01) = 0.11;
uniform float displacement_strength : hint_range(0.0, 0.3, 0.005) = 0.075;
uniform float taper_strength : hint_range(0.0, 1.0, 0.01) = 0.82;
uniform float top_stretch : hint_range(0.0, 0.8, 0.01) = 0.28;
uniform vec4 inner_color : source_color = vec4(0.82, 0.97, 1.0, 1.0);
uniform vec4 outer_color : source_color = vec4(0.04, 0.42, 1.0, 1.0);
uniform float emission_strength : hint_range(0.0, 10.0, 0.05) = 3.0;
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 0.34;

varying vec3 local_position;
varying float vertex_flow;
varying float local_height;

float hash31(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3d(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(cell + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(cell + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(cell + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(cell + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(cell + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(cell + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(cell + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(cell + vec3(1.0, 1.0, 1.0));
	float x00 = mix(n000, n100, f.x);
	float x10 = mix(n010, n110, f.x);
	float x01 = mix(n001, n101, f.x);
	float x11 = mix(n011, n111, f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

vec3 flow_position(vec3 position, float scale, float speed, vec3 offset) {
	vec3 p = position * vec3(scale, scale * 0.58, scale);
	p.y -= TIME * speed;
	return p + offset;
}

void vertex() {
	float height = clamp(VERTEX.y / 1.45 + 0.5, 0.0, 1.0);
	float broad_base = mix(0.76, 1.0, smoothstep(0.02, 0.3, height));
	float top_taper = 1.0 - smoothstep(0.34, 1.0, height) * taper_strength;
	VERTEX.xz *= max(broad_base * top_taper, 0.08);

	float flow_1 = noise3d(flow_position(VERTEX, noise_scale_1, flame_speed_1, vec3(0.0)));
	float flow_2 = noise3d(flow_position(VERTEX, noise_scale_2, flame_speed_2, vec3(5.2, 11.7, -3.4)));
	vertex_flow = flow_1 * 0.68 + flow_2 * 0.32;
	float upper_influence = smoothstep(0.12, 0.88, height);
	float displacement = (vertex_flow - 0.5) * displacement_strength * upper_influence;
	VERTEX += NORMAL * displacement;
	VERTEX.x += (flow_1 - flow_2) * displacement_strength * upper_influence * 0.55;
	VERTEX.y += pow(height, 2.4) * top_stretch * (0.72 + flow_1 * 0.28);

	local_position = VERTEX;
	local_height = height;
}

void fragment() {
	float flow_1 = noise3d(flow_position(local_position, noise_scale_1, flame_speed_1, vec3(0.0)));
	float flow_2 = noise3d(flow_position(local_position, noise_scale_2, flame_speed_2, vec3(5.2, 11.7, -3.4)));
	float broken_flow = flow_1 * 0.72 + flow_2 * 0.42 - abs(flow_1 - flow_2) * 0.24;
	broken_flow += (local_height - 0.5) * 0.08;
	float tongues = smoothstep(cutoff - softness, cutoff + softness, broken_flow);
	float bottom_fade = smoothstep(0.08, 0.3, local_height);
	float tip_fade = 1.0 - smoothstep(0.94, 1.0, local_height);
	float vertical_mask = bottom_fade * tip_fade;
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.5);
	float flame_mask = tongues * vertical_mask;
	vec3 color = mix(inner_color.rgb, outer_color.rgb, clamp(flow_2 * 0.55 + local_height * 0.28, 0.0, 1.0));
	ALBEDO = color;
	EMISSION = color * emission_strength * (0.85 + flow_1 * 0.35);
	ALPHA = opacity * flame_mask * (0.92 + fresnel * 0.08);
}
