shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform float flame_speed_1 : hint_range(0.0, 5.0, 0.05) = 1.35;
uniform float flame_speed_2 : hint_range(0.0, 5.0, 0.05) = 0.82;
uniform float noise_scale_1 : hint_range(0.5, 12.0, 0.1) = 4.6;
uniform float noise_scale_2 : hint_range(0.5, 12.0, 0.1) = 7.3;
uniform float cutoff : hint_range(0.0, 1.0, 0.01) = 0.48;
uniform float softness : hint_range(0.01, 0.4, 0.01) = 0.22;
uniform float displacement_strength : hint_range(0.0, 0.3, 0.005) = 0.035;
uniform float taper_strength : hint_range(0.0, 1.0, 0.01) = 0.82;
uniform float top_stretch : hint_range(0.0, 0.8, 0.01) = 0.28;
uniform vec4 inner_color : source_color = vec4(0.82, 0.97, 1.0, 1.0);
uniform vec4 outer_color : source_color = vec4(0.04, 0.42, 1.0, 1.0);
uniform float emission_strength : hint_range(0.0, 10.0, 0.05) = 3.0;
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 0.24;

/* NEW: movement drag */
uniform vec3 motion_dir_local = vec3(0.0, 0.0, 0.0);
uniform float motion_strength : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float drag_strength : hint_range(0.0, 0.6, 0.01) = 0.18;
uniform float drag_curve : hint_range(0.5, 4.0, 0.05) = 1.8;
uniform float max_drag_angle_degrees : hint_range(0.0, 90.0, 1.0) = 40.0;
uniform float side_sway_from_motion : hint_range(0.0, 0.4, 0.01) = 0.08;
uniform float motion_stretch_y : hint_range(0.0, 0.4, 0.01) = 0.10;

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

	/* Base silhouette */
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

	/* NEW: drag the flame opposite movement */
	vec3 move_dir = motion_dir_local;
	move_dir.y = 0.0;

	float move_len = length(move_dir);
	if (move_len > 0.0001) {
		move_dir = normalize(move_dir);

		float height_from_base = max(VERTEX.y + 0.725, 0.0);
		float bend_weight = pow(smoothstep(0.12, 1.0, height), drag_curve);
		float drag_response = clamp(drag_strength / 0.4, 0.0, 1.0);
		float bend_angle = radians(max_drag_angle_degrees) * motion_strength * bend_weight * drag_response;
		float horizontal_bend = sin(bend_angle) * height_from_base;
		float vertical_drop = (1.0 - cos(bend_angle)) * height_from_base;

		/* Curve the upper flame backward while its base stays anchored. */
		VERTEX -= move_dir * horizontal_bend;
		VERTEX.y -= vertical_drop;

		/* Add slight sideways lilt for more organic arc */
		vec3 side_dir = normalize(vec3(-move_dir.z, 0.0, move_dir.x));
		VERTEX += side_dir * (flow_1 - 0.5) * side_sway_from_motion * bend_weight * motion_strength;

		/* Slight stretch upward while moving */
		VERTEX.y += motion_stretch_y * bend_weight * motion_strength;
	}

	local_position = VERTEX;
	local_height = height;
}

void fragment() {
	float flow_1 = noise3d(
		flow_position(
			local_position,
			noise_scale_1,
			flame_speed_1,
			vec3(0.0)
		)
	);

	float flow_2 = noise3d(
		flow_position(
			local_position,
			noise_scale_2,
			flame_speed_2,
			vec3(5.2, 11.7, -3.4)
		)
	);

	float flame_noise = mix(flow_1, flow_2, 0.42);
	flame_noise += flow_1 * flow_2 * 0.2;
	flame_noise += (local_height - 0.5) * 0.06;

	float tongues = smoothstep(
		cutoff - softness,
		cutoff + softness,
		flame_noise
	);

	float bottom_fade = smoothstep(0.02, 0.26, local_height);
	float tip_fade = 1.0 - smoothstep(0.82, 1.0, local_height);
	float vertical_mask = bottom_fade * tip_fade;

	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float soft_edge = smoothstep(0.02, 0.58, facing);

	float edge_breakup = smoothstep(
		0.2,
		0.85,
		flow_2 + flow_1 * 0.25
	);

	float flame_mask =
		tongues *
		vertical_mask *
		soft_edge *
		mix(0.65, 1.0, edge_breakup);

	vec3 color = mix(
		inner_color.rgb,
		outer_color.rgb,
		clamp(flow_2 * 0.5 + local_height * 0.32, 0.0, 1.0)
	);

	ALBEDO = color;

	EMISSION =
		color *
		emission_strength *
		(0.75 + flame_noise * 0.45);

	ALPHA = opacity * pow(flame_mask, 1.25);
}
