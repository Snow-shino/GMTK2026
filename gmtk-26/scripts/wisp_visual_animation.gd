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


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	base_position = position
	base_rotation = rotation
	base_scale = scale
	_phase = randf_range(0.0, TAU)
	_previous_grounded = _body.is_on_floor()


func _process(delta: float) -> void:
	if not is_instance_valid(_body):
		return

	_time += delta
	var grounded := _body.is_on_floor()
	var horizontal_velocity := Vector3(_body.velocity.x, 0.0, _body.velocity.z)
	var horizontal_speed := horizontal_velocity.length()
	var speed_ratio := clampf(horizontal_speed / 6.0, 0.0, 1.0)
	var movement_direction := horizontal_velocity.normalized() if horizontal_speed > 0.05 else Vector3.ZERO

	if _previous_grounded and not grounded and _body.velocity.y > 0.0:
		_jump_time = 0.0
		_jump_offset = jump_impulse_offset
	if not _previous_grounded and grounded:
		_landing_strength = clampf(absf(_previous_velocity.y) / 14.0, 0.35, 1.0)

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

	_previous_velocity = _body.velocity
	_previous_grounded = grounded
	if not movement_direction.is_zero_approx():
		_previous_direction = movement_direction


func _smooth_weight(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)
