class_name WispVisualAnimation
extends Node3D

@export_category("Idle")
@export_range(0.0, 1.0, 0.01) var idle_bob_amplitude: float = 0.12
@export_range(0.1, 10.0, 0.1) var idle_bob_speed: float = 1.8
@export_range(0.0, 1.0, 0.01) var idle_sway_amplitude: float = 0.07
@export_range(0.0, 0.2, 0.005) var scale_pulse_amount: float = 0.025

@export_category("Movement")
@export_range(0.0, 1.0, 0.01) var move_bob_amplitude: float = 0.2
@export_range(0.1, 15.0, 0.1) var move_bob_speed: float = 4.5
@export_range(0.0, 1.0, 0.01) var move_weave_amplitude: float = 0.12
@export_range(0.0, 45.0, 0.5) var max_turn_lean_degrees: float = 14.0
@export_range(0.1, 30.0, 0.1) var turn_lean_speed: float = 9.0
@export_range(0.0, 45.0, 0.5) var acceleration_pitch_degrees: float = 10.0
@export_range(0.1, 30.0, 0.1) var visual_smoothing: float = 10.0

@export_category("Jump and Landing")
@export_range(0.0, 0.5, 0.01) var jump_stretch_amount: float = 0.14
@export_range(0.0, 1.0, 0.01) var jump_impulse_offset: float = 0.16
@export_range(0.0, 0.6, 0.01) var landing_squash_amount: float = 0.18
@export_range(0.0, 1.0, 0.01) var landing_offset_amount: float = 0.16
@export_range(0.1, 30.0, 0.1) var landing_recovery_speed: float = 10.0

@export_category("Ember Trail")
@export_range(0, 60, 1) var minimum_emission_amount: int = 3
@export_range(1, 60, 1) var maximum_emission_amount: int = 48
@export_range(0.1, 20.0, 0.1) var speed_for_full_emission: float = 6.0
@export_range(0.2, 4.0, 0.1) var ember_lifetime: float = 1.6
@export_range(0.01, 1.0, 0.01) var ember_scale: float = 0.13
@export_range(0.0, 5.0, 0.1) var upward_velocity: float = 0.65
@export_range(0.0, 5.0, 0.1) var backward_velocity: float = 0.8
@export_range(0.0, 90.0, 1.0) var spread: float = 32.0
@export var trail_color: Color = Color(0.2, 0.75, 1.0, 0.8)
@export_range(0.0, 10.0, 0.1) var trail_emission_strength: float = 4.0

var base_position: Vector3
var base_rotation: Vector3
var base_scale: Vector3

var _body: CharacterBody3D
var _previous_velocity := Vector3.ZERO
var _previous_grounded := true
var _previous_direction := Vector3.ZERO
var _time := 0.0
var _phase := 0.0
var _facing_yaw := 0.0
var _jump_time := -1.0
var _jump_offset := 0.0
var _landing_strength := 0.0
var _visual_intensity := 0.0

@onready var flame_shell: MeshInstance3D = %FlameShell
@onready var ember_trail: GPUParticles3D = %EmberTrail
@onready var ambient_sparks: GPUParticles3D = %AmbientSparks
@onready var wisp_light: OmniLight3D = %WispLight

var _flame_material: ShaderMaterial
var _ember_material: ShaderMaterial
var _base_flame_scale: Vector3
var _base_light_energy: float


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	base_position = position
	base_rotation = rotation
	base_scale = scale
	_phase = randf_range(0.0, TAU)
	_previous_grounded = _body.is_on_floor()
	_base_flame_scale = flame_shell.scale
	_base_light_energy = wisp_light.light_energy
	_flame_material = flame_shell.material_override as ShaderMaterial
	_ember_material = ember_trail.draw_pass_1.surface_get_material(0) as ShaderMaterial
	ember_trail.amount = maxi(maximum_emission_amount, 1)
	ember_trail.lifetime = ember_lifetime
	_apply_particle_tuning()


func _process(delta: float) -> void:
	if not is_instance_valid(_body):
		return

	_time += delta
	var grounded := _body.is_on_floor()
	var horizontal_velocity := Vector3(_body.velocity.x, 0.0, _body.velocity.z)
	var horizontal_speed := horizontal_velocity.length()
	var speed_ratio := clampf(horizontal_speed / maxf(speed_for_full_emission, 0.1), 0.0, 1.0)
	_visual_intensity = lerpf(_visual_intensity, speed_ratio, _smooth_weight(6.0, delta))
	var movement_direction := horizontal_velocity.normalized() if horizontal_speed > 0.05 else Vector3.ZERO

	if _previous_grounded and not grounded and _body.velocity.y > 0.0:
		_jump_time = 0.0
		_jump_offset = jump_impulse_offset
		_emit_ember_burst(7, 1.5)
	if not _previous_grounded and grounded:
		_landing_strength = clampf(absf(_previous_velocity.y) / 14.0, 0.35, 1.0)
		_emit_ember_burst(11, 2.6)

	var bob_speed := lerpf(idle_bob_speed, move_bob_speed, speed_ratio)
	var bob_amplitude := lerpf(idle_bob_amplitude, move_bob_amplitude, speed_ratio)
	var bob := sin(_time * bob_speed + _phase) * bob_amplitude
	bob += sin(_time * bob_speed * 1.73 + _phase * 0.37) * bob_amplitude * 0.3

	var idle_sway := Vector3(
		sin(_time * idle_bob_speed * 0.71 + _phase) * idle_sway_amplitude,
		0.0,
		sin(_time * idle_bob_speed * 0.47 + _phase * 1.9) * idle_sway_amplitude * 0.65
	) * (1.0 - speed_ratio)

	var weave_offset := Vector3.ZERO
	if not movement_direction.is_zero_approx():
		var movement_right := Vector3(-movement_direction.z, 0.0, movement_direction.x)
		weave_offset = movement_right * sin(_time * move_bob_speed * 0.85 + _phase) * move_weave_amplitude * speed_ratio

	var turn_amount := 0.0
	if not movement_direction.is_zero_approx() and not _previous_direction.is_zero_approx():
		turn_amount = clampf(
			_previous_direction.signed_angle_to(movement_direction, Vector3.UP) / maxf(delta * 8.0, 0.001),
			-1.0,
			1.0
		)
	var turn_lean := deg_to_rad(max_turn_lean_degrees) * turn_amount
	var turn_curve_offset := Vector3.ZERO
	if not movement_direction.is_zero_approx():
		turn_curve_offset = Vector3(-movement_direction.z, 0.0, movement_direction.x) * turn_amount * move_weave_amplitude * 0.65

	var horizontal_acceleration := (horizontal_velocity - Vector3(_previous_velocity.x, 0.0, _previous_velocity.z)) / maxf(delta, 0.001)
	var forward_acceleration := horizontal_acceleration.dot(movement_direction) if not movement_direction.is_zero_approx() else 0.0
	var acceleration_pitch := -deg_to_rad(acceleration_pitch_degrees) * clampf(forward_acceleration / 24.0, -1.0, 1.0)

	if not movement_direction.is_zero_approx():
		var target_yaw := atan2(-movement_direction.x, -movement_direction.z)
		_facing_yaw = lerp_angle(_facing_yaw, target_yaw, _smooth_weight(turn_lean_speed, delta))

	var procedural_scale := Vector3.ONE
	var pulse := sin(_time * idle_bob_speed * 1.31 + _phase) * scale_pulse_amount
	procedural_scale += Vector3(pulse, -pulse * 0.35, pulse)

	if _jump_time >= 0.0:
		_jump_time += delta
		if _jump_time < 0.055:
			procedural_scale += Vector3(jump_stretch_amount * 0.2, -jump_stretch_amount * 0.4, jump_stretch_amount * 0.2)
		elif _jump_time < 0.2:
			var takeoff_strength := 1.0 - ((_jump_time - 0.055) / 0.145)
			procedural_scale += Vector3(-jump_stretch_amount * 0.3, jump_stretch_amount, -jump_stretch_amount * 0.3) * takeoff_strength
		else:
			_jump_time = -1.0

	if not grounded and _body.velocity.y > 0.0:
		var rise_strength := clampf(_body.velocity.y / 9.5, 0.0, 1.0)
		procedural_scale += Vector3(-0.25, 1.0, -0.25) * jump_stretch_amount * rise_strength
	elif not grounded and _body.velocity.y < 0.0:
		var fall_strength := clampf(absf(_body.velocity.y) / 12.0, 0.0, 1.0)
		procedural_scale += Vector3(0.35, -0.45, 0.35) * jump_stretch_amount * fall_strength

	_jump_offset = lerpf(_jump_offset, 0.0, _smooth_weight(8.0, delta))
	_landing_strength = lerpf(_landing_strength, 0.0, _smooth_weight(landing_recovery_speed, delta))
	procedural_scale += Vector3(0.5, -1.0, 0.5) * landing_squash_amount * _landing_strength

	var target_position := base_position
	target_position += Vector3.UP * (bob + _jump_offset - landing_offset_amount * _landing_strength)
	target_position += idle_sway + weave_offset + turn_curve_offset
	var target_rotation := base_rotation + Vector3(acceleration_pitch, _facing_yaw, -turn_lean)
	var target_scale := base_scale * procedural_scale
	var smoothing := _smooth_weight(visual_smoothing, delta)
	position = position.lerp(target_position, smoothing)
	rotation.x = lerp_angle(rotation.x, target_rotation.x, smoothing)
	rotation.y = lerp_angle(rotation.y, target_rotation.y, smoothing)
	rotation.z = lerp_angle(rotation.z, target_rotation.z, smoothing)
	scale = scale.lerp(target_scale, smoothing)
	_update_effect_intensity(delta, speed_ratio, grounded)

	_previous_velocity = _body.velocity
	_previous_grounded = grounded
	if not movement_direction.is_zero_approx():
		_previous_direction = movement_direction


func _smooth_weight(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)


func _apply_particle_tuning() -> void:
	var trail_process := ember_trail.process_material as ParticleProcessMaterial
	if trail_process:
		trail_process.direction = Vector3(0.0, upward_velocity, backward_velocity).normalized()
		trail_process.initial_velocity_min = maxf(backward_velocity * 0.55, 0.1)
		trail_process.initial_velocity_max = maxf(backward_velocity, 0.2)
		trail_process.spread = spread
		trail_process.scale_min = ember_scale * 0.7
		trail_process.scale_max = ember_scale * 1.25
	if _ember_material:
		_ember_material.set_shader_parameter("particle_color", trail_color)
		_ember_material.set_shader_parameter("emission_strength", trail_emission_strength)


func _update_effect_intensity(delta: float, speed_ratio: float, grounded: bool) -> void:
	var minimum_ratio := float(minimum_emission_amount) / float(maxi(maximum_emission_amount, 1))
	var jump_boost := 0.25 if not grounded else 0.0
	ember_trail.amount_ratio = lerpf(
		ember_trail.amount_ratio,
		clampf(lerpf(minimum_ratio, 1.0, _visual_intensity) + jump_boost, minimum_ratio, 1.0),
		_smooth_weight(7.0, delta)
	)

	var flame_energy := 2.4 + _visual_intensity * 0.9 + jump_boost
	if _flame_material:
		_flame_material.set_shader_parameter("emission_strength", flame_energy)
		_flame_material.set_shader_parameter("flicker_amount", 0.18 + _visual_intensity * 0.14)
	var flame_stretch := 1.0 + _visual_intensity * 0.12 + clampf(_body.velocity.y / 18.0, -0.08, 0.18)
	var target_flame_scale := _base_flame_scale * Vector3(1.0 - _visual_intensity * 0.03, flame_stretch, 1.0 - _visual_intensity * 0.03)
	flame_shell.scale = flame_shell.scale.lerp(target_flame_scale, _smooth_weight(8.0, delta))

	var light_pulse := sin(_time * 2.3 + _phase) * 0.08
	var target_light_energy := _base_light_energy * (1.0 + light_pulse + _visual_intensity * 0.22)
	wisp_light.light_energy = lerpf(wisp_light.light_energy, target_light_energy, _smooth_weight(6.0, delta))
	ambient_sparks.amount_ratio = lerpf(ambient_sparks.amount_ratio, 0.65 + _visual_intensity * 0.2, _smooth_weight(3.0, delta))


func _emit_ember_burst(count: int, outward_speed: float) -> void:
	for index in count:
		var direction := Vector3(randf_range(-1.0, 1.0), randf_range(0.25, 1.0), randf_range(-1.0, 1.0)).normalized()
		var particle_velocity := direction * outward_speed + Vector3.UP * upward_velocity
		ember_trail.emit_particle(
			Transform3D.IDENTITY,
			particle_velocity,
			trail_color,
			Color(1.0, 1.0, 1.0, 1.0),
			GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_VELOCITY | GPUParticles3D.EMIT_FLAG_COLOR
		)
