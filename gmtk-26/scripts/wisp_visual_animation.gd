class_name WispVisualAnimation
extends Node3D

@export_category("Idle")
@export_range(0.0, 1.0, 0.01) var idle_bob_amplitude: float = 0.1
@export_range(0.1, 10.0, 0.1) var idle_bob_speed: float = 1.8
@export_range(0.0, 1.0, 0.01) var idle_sway_amplitude: float = 0.05
@export_range(0.0, 0.2, 0.005) var scale_pulse_amount: float = 0.02

@export_category("Movement Visuals")
@export_range(0.0, 1.0, 0.01) var move_bob_amplitude: float = 0.15
@export_range(0.1, 15.0, 0.1) var move_bob_speed: float = 4.2
@export_range(0.0, 1.0, 0.01) var move_weave_amplitude: float = 0.06
@export_range(0.0, 45.0, 0.5) var max_turn_lean_degrees: float = 8.0
@export_range(0.0, 45.0, 0.5) var movement_pitch_degrees: float = 7.0
@export_range(0.1, 30.0, 0.1) var velocity_smoothing: float = 10.0
@export_range(0.1, 30.0, 0.1) var lean_smoothing: float = 9.0
@export_range(0.1, 30.0, 0.1) var visual_smoothing: float = 14.0
@export_range(0.1, 30.0, 0.1) var speed_for_full_effect: float = 16.0

@export_category("Jump and Landing")
@export_range(0.0, 0.5, 0.01) var jump_stretch_amount: float = 0.14
@export_range(0.0, 1.0, 0.01) var jump_impulse_offset: float = 0.14
@export_range(0.0, 0.6, 0.01) var landing_squash_amount: float = 0.18
@export_range(0.0, 1.0, 0.01) var landing_offset_amount: float = 0.14
@export_range(0.1, 30.0, 0.1) var landing_recovery_speed: float = 11.0

@export_category("Ember Trail")
@export_range(0, 60, 1) var minimum_emission_amount: int = 3
@export_range(1, 60, 1) var maximum_emission_amount: int = 48
@export_range(0.2, 4.0, 0.1) var ember_lifetime: float = 1.6
@export_range(0.01, 1.0, 0.01) var ember_scale: float = 0.13
@export_range(0.0, 5.0, 0.1) var upward_velocity: float = 0.65
@export_range(0.0, 5.0, 0.1) var backward_velocity: float = 0.8
@export_range(0.0, 90.0, 1.0) var spread: float = 32.0
@export_range(0.0, 10.0, 0.1) var trail_emission_strength: float = 4.0

@export_category("Life Visuals")
@export_range(0.0, 1.0, 0.01) var min_flame_emission_multiplier: float = 0.38
@export_range(0.1, 2.0, 0.01) var max_flame_emission_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var min_light_energy_multiplier: float = 0.32
@export_range(0.1, 2.0, 0.01) var max_light_energy_multiplier: float = 1.0
@export_range(0.01, 1.0, 0.01) var low_life_flicker_threshold: float = 0.2
@export_range(0.0, 0.5, 0.01) var low_life_flicker_strength: float = 0.12
@export_range(0.0, 1.0, 0.01) var min_trail_multiplier: float = 0.3
@export_range(0.1, 30.0, 0.1) var life_visual_smoothing: float = 6.0

@export_category("Wisp Palette")
@export var core_color: Color = Color(0.82, 0.96, 1.0, 1.0)
@export var inner_flame_color: Color = Color(0.16, 0.76, 1.0, 1.0)
@export var outer_flame_color: Color = Color(0.025, 0.28, 1.0, 1.0)
@export var ember_color: Color = Color(0.2, 0.75, 1.0, 0.8)
@export var light_color: Color = Color(0.25, 0.75, 1.0, 1.0)

@onready var core_mesh: MeshInstance3D = $CoreMesh
@onready var flame_shell: MeshInstance3D = %FlameShell
@onready var inner_flame: MeshInstance3D = %InnerFlame
@onready var ember_trail: GPUParticles3D = %EmberTrail
@onready var ambient_sparks: GPUParticles3D = %AmbientSparks
@onready var wisp_light: OmniLight3D = %WispLight

var _body: CharacterBody3D
var _base_position := Vector3.ZERO
var _base_rotation := Vector3.ZERO
var _base_scale := Vector3.ONE
var _base_flame_scale := Vector3.ONE
var _base_inner_flame_scale := Vector3.ONE
var _base_light_energy := 1.0
var _base_light_range := 1.0
var _base_core_emission := 1.0
var _base_outer_emission := 1.0
var _base_inner_emission := 1.0
var _base_trail_emission := 1.0

var _core_material: StandardMaterial3D
var _flame_material: ShaderMaterial
var _inner_flame_material: ShaderMaterial
var _ember_material: ShaderMaterial
var _ambient_material: ShaderMaterial

var _default_core_color: Color
var _default_inner_color: Color
var _default_outer_color: Color
var _default_ember_color: Color
var _default_light_color: Color

var _time := 0.0
var _phase := 0.0
var _bob_phase := 0.0
var _smoothed_local_velocity := Vector3.ZERO
var _smoothed_speed_ratio := 0.0
var _smoothed_lateral_lean := 0.0
var _smoothed_pitch := 0.0
var _target_life_ratio := 1.0
var _life_ratio := 1.0
var _previous_grounded := true
var _airborne_time := 0.0
var _previous_vertical_velocity := 0.0
var _jump_time := -1.0
var _jump_offset := 0.0
var _landing_strength := 0.0


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	if not is_instance_valid(_body):
		push_error("WispVisualAnimation must be a direct child of CharacterBody3D.")
		set_process(false)
		return

	_base_position = position
	_base_rotation = rotation
	_base_scale = scale
	_base_flame_scale = flame_shell.scale
	_base_inner_flame_scale = inner_flame.scale
	_base_light_energy = wisp_light.light_energy
	_base_light_range = wisp_light.omni_range
	_phase = randf_range(0.0, TAU)
	_previous_grounded = _body.is_on_floor()
	_previous_vertical_velocity = _body.velocity.y

	_make_materials_instance_local()
	_cache_material_strengths()
	_cache_default_palette()
	_apply_wisp_colors()
	_apply_particle_tuning()

	if _body.has_signal("life_changed"):
		_body.connect("life_changed", _on_life_changed)
	call_deferred("_initialize_life_ratio")


func _process(delta: float) -> void:
	if not is_instance_valid(_body):
		return

	_time += delta
	var grounded := _body.is_on_floor()
	var world_horizontal_velocity := Vector3(_body.velocity.x, 0.0, _body.velocity.z)
	var local_velocity := _body.global_basis.inverse() * world_horizontal_velocity
	local_velocity.y = 0.0
	_smoothed_local_velocity = _smoothed_local_velocity.lerp(
		local_velocity,
		_smooth_weight(velocity_smoothing, delta)
	)

	var target_speed_ratio := clampf(
		world_horizontal_velocity.length() / maxf(speed_for_full_effect, 0.1),
		0.0,
		1.0
	)
	_smoothed_speed_ratio = lerpf(
		_smoothed_speed_ratio,
		target_speed_ratio,
		_smooth_weight(velocity_smoothing, delta)
	)
	_life_ratio = lerpf(
		_life_ratio,
		_target_life_ratio,
		_smooth_weight(life_visual_smoothing, delta)
	)

	_update_grounded_events(grounded, delta)
	_update_lean(delta)
	_update_visual_transform(grounded, delta)
	_update_flame_drag(delta)
	_update_effect_intensity(grounded, delta)

	_previous_grounded = grounded
	_previous_vertical_velocity = _body.velocity.y


func _update_lean(delta: float) -> void:
	var target_lateral := clampf(
		_smoothed_local_velocity.x / maxf(speed_for_full_effect, 0.1),
		-1.0,
		1.0
	)
	var target_pitch := deg_to_rad(movement_pitch_degrees) * clampf(
		_smoothed_local_velocity.z / maxf(speed_for_full_effect, 0.1),
		-1.0,
		1.0
	)
	if _smoothed_local_velocity.length_squared() < 0.0025:
		target_lateral = 0.0
		target_pitch = 0.0

	var weight := _smooth_weight(lean_smoothing, delta)
	_smoothed_lateral_lean = lerpf(_smoothed_lateral_lean, target_lateral, weight)
	_smoothed_pitch = lerpf(_smoothed_pitch, target_pitch, weight)


func _update_visual_transform(grounded: bool, delta: float) -> void:
	var bob_speed := lerpf(idle_bob_speed, move_bob_speed, _smoothed_speed_ratio)
	var bob_amount := lerpf(idle_bob_amplitude, move_bob_amplitude, _smoothed_speed_ratio)
	_bob_phase = fmod(_bob_phase + bob_speed * delta, TAU)
	var bob := sin(_bob_phase + _phase) * bob_amount
	bob += sin(_bob_phase * 1.71 + _phase * 0.43) * bob_amount * 0.24

	var idle_weight := 1.0 - _smoothed_speed_ratio
	var sway := Vector3(
		sin(_time * idle_bob_speed * 0.67 + _phase),
		0.0,
		sin(_time * idle_bob_speed * 0.43 + _phase * 1.8) * 0.6
	) * idle_sway_amplitude * idle_weight
	var weave := Vector3(
		sin(_time * move_bob_speed * 0.72 + _phase),
		0.0,
		cos(_time * move_bob_speed * 0.51 + _phase) * 0.35
	) * move_weave_amplitude * _smoothed_speed_ratio
	var movement_arc := Vector3.RIGHT * _smoothed_lateral_lean * move_weave_amplitude * 0.35

	var target_position := _base_position + Vector3.UP * (
		bob + _jump_offset - landing_offset_amount * _landing_strength
	)
	target_position += sway + weave + movement_arc
	var target_rotation := _base_rotation + Vector3(
		_smoothed_pitch,
		0.0,
		-deg_to_rad(max_turn_lean_degrees) * _smoothed_lateral_lean
	)
	var target_scale := _base_scale * _calculate_scale(grounded, delta)
	var weight := _smooth_weight(visual_smoothing, delta)
	position = position.lerp(target_position, weight)
	rotation.x = lerp_angle(rotation.x, target_rotation.x, weight)
	rotation.y = lerp_angle(rotation.y, _base_rotation.y, weight)
	rotation.z = lerp_angle(rotation.z, target_rotation.z, weight)
	scale = scale.lerp(target_scale, weight)


func _calculate_scale(grounded: bool, delta: float) -> Vector3:
	var result := Vector3.ONE
	var pulse := sin(_time * idle_bob_speed * 1.31 + _phase) * scale_pulse_amount
	result += Vector3(pulse, -pulse * 0.35, pulse)

	if _jump_time >= 0.0:
		_jump_time += delta
		if _jump_time < 0.05:
			result += Vector3(0.04, -0.08, 0.04)
		elif _jump_time < 0.2:
			var takeoff := 1.0 - ((_jump_time - 0.05) / 0.15)
			result += Vector3(-0.25, 1.0, -0.25) * jump_stretch_amount * takeoff
		else:
			_jump_time = -1.0

	if not grounded and _body.velocity.y > 0.0:
		var rising := clampf(_body.velocity.y / 17.0, 0.0, 1.0)
		result += Vector3(-0.22, 1.0, -0.22) * jump_stretch_amount * rising
	elif not grounded and _body.velocity.y < 0.0:
		var falling := clampf(absf(_body.velocity.y) / 14.0, 0.0, 1.0)
		result += Vector3(0.3, -0.38, 0.3) * jump_stretch_amount * falling

	_jump_offset = lerpf(_jump_offset, 0.0, _smooth_weight(8.0, delta))
	_landing_strength = lerpf(
		_landing_strength,
		0.0,
		_smooth_weight(landing_recovery_speed, delta)
	)
	result += Vector3(0.5, -1.0, 0.5) * landing_squash_amount * _landing_strength
	return result


func _update_grounded_events(grounded: bool, delta: float) -> void:
	if grounded:
		if not _previous_grounded and _airborne_time >= 0.06:
			_landing_strength = clampf(absf(_previous_vertical_velocity) / 16.0, 0.25, 1.0)
			_emit_ember_burst(10, 2.4)
		_airborne_time = 0.0
	else:
		_airborne_time += delta
		if _previous_grounded and _body.velocity.y > 0.0:
			_jump_time = 0.0
			_jump_offset = jump_impulse_offset
			_emit_ember_burst(7, 1.5)


func _update_flame_drag(delta: float) -> void:
	var direction := Vector3.ZERO
	var speed := _smoothed_local_velocity.length()
	if speed > 0.05:
		direction = _smoothed_local_velocity / speed
	var strength := clampf(speed / maxf(speed_for_full_effect, 0.1), 0.0, 1.0)
	var weight := _smooth_weight(9.0, delta)

	for material in [_flame_material, _inner_flame_material]:
		if material:
			var current_direction: Vector3 = material.get_shader_parameter("motion_dir_local")
			var current_strength: float = material.get_shader_parameter("motion_strength")
			material.set_shader_parameter("motion_dir_local", current_direction.lerp(direction, weight))
			material.set_shader_parameter("motion_strength", lerpf(current_strength, strength, weight))


func _update_effect_intensity(grounded: bool, delta: float) -> void:
	var life_curve := pow(clampf(_life_ratio, 0.0, 1.0), 0.65)
	var flame_life := lerpf(
		min_flame_emission_multiplier,
		max_flame_emission_multiplier,
		life_curve
	)
	var light_life := lerpf(
		min_light_energy_multiplier,
		max_light_energy_multiplier,
		life_curve
	)
	var low_life_amount := 0.0
	if _life_ratio < low_life_flicker_threshold:
		low_life_amount = 1.0 - _life_ratio / maxf(low_life_flicker_threshold, 0.01)
	var flicker := 1.0 + sin(_time * 13.0 + _phase) * low_life_flicker_strength * low_life_amount
	var jump_boost := 0.12 if not grounded else 0.0
	var movement_boost := 1.0 + _smoothed_speed_ratio * 0.22 + jump_boost

	if _flame_material:
		_flame_material.set_shader_parameter(
			"emission_strength",
			_base_outer_emission * flame_life * movement_boost * flicker
		)
	if _inner_flame_material:
		_inner_flame_material.set_shader_parameter(
			"emission_strength",
			_base_inner_emission * flame_life * movement_boost * flicker
		)
	if _core_material:
		_core_material.emission_energy_multiplier = (
			_base_core_emission * flame_life * (1.0 + _smoothed_speed_ratio * 0.08) * flicker
		)

	var flame_stretch := 1.0 + _smoothed_speed_ratio * 0.1
	flame_stretch += clampf(_body.velocity.y / 22.0, -0.07, 0.16)
	flame_shell.scale = flame_shell.scale.lerp(
		_base_flame_scale * Vector3(0.98, flame_stretch, 0.98),
		_smooth_weight(8.0, delta)
	)
	inner_flame.scale = inner_flame.scale.lerp(
		_base_inner_flame_scale * Vector3(0.99, 1.0 + (flame_stretch - 1.0) * 0.7, 0.99),
		_smooth_weight(9.0, delta)
	)

	wisp_light.light_energy = lerpf(
		wisp_light.light_energy,
		_base_light_energy * light_life * (1.0 + _smoothed_speed_ratio * 0.14) * flicker,
		_smooth_weight(life_visual_smoothing, delta)
	)
	wisp_light.omni_range = lerpf(
		wisp_light.omni_range,
		_base_light_range * lerpf(0.65, 1.0, life_curve),
		_smooth_weight(life_visual_smoothing, delta)
	)

	var life_trail := lerpf(min_trail_multiplier, 1.0, life_curve)
	var minimum_ratio := float(minimum_emission_amount) / float(maxi(maximum_emission_amount, 1))
	var target_trail := lerpf(minimum_ratio, 1.0, _smoothed_speed_ratio) * life_trail
	ember_trail.amount_ratio = lerpf(
		ember_trail.amount_ratio,
		clampf(target_trail + jump_boost, minimum_ratio * min_trail_multiplier, 1.0),
		_smooth_weight(7.0, delta)
	)
	ambient_sparks.amount_ratio = lerpf(
		ambient_sparks.amount_ratio,
		(0.45 + _smoothed_speed_ratio * 0.15) * life_trail,
		_smooth_weight(3.0, delta)
	)
	if _ember_material:
		_ember_material.set_shader_parameter(
			"emission_strength",
			_base_trail_emission * flame_life
		)


func set_wisp_colors(
	new_core: Color,
	new_inner: Color,
	new_outer: Color,
	new_ember: Color,
	new_light: Color
) -> void:
	core_color = new_core
	inner_flame_color = new_inner
	outer_flame_color = new_outer
	ember_color = new_ember
	light_color = new_light
	_apply_wisp_colors()


func reset_wisp_colors() -> void:
	set_wisp_colors(
		_default_core_color,
		_default_inner_color,
		_default_outer_color,
		_default_ember_color,
		_default_light_color
	)


func _apply_wisp_colors() -> void:
	if _core_material:
		_core_material.albedo_color = core_color
		_core_material.emission = core_color
	if _inner_flame_material:
		_inner_flame_material.set_shader_parameter("inner_color", core_color.lerp(inner_flame_color, 0.25))
		_inner_flame_material.set_shader_parameter("outer_color", inner_flame_color)
	if _flame_material:
		_flame_material.set_shader_parameter("inner_color", inner_flame_color)
		_flame_material.set_shader_parameter("outer_color", outer_flame_color)
	if _ember_material:
		_ember_material.set_shader_parameter("particle_color", ember_color)
	if _ambient_material:
		_ambient_material.set_shader_parameter("particle_color", ember_color.lerp(core_color, 0.35))
	wisp_light.light_color = light_color


func _on_life_changed(current_life: float, max_life: float) -> void:
	_target_life_ratio = 0.0 if max_life <= 0.0 else clampf(current_life / max_life, 0.0, 1.0)


func _initialize_life_ratio() -> void:
	if _body.has_method("get_life_percent"):
		_target_life_ratio = clampf(float(_body.call("get_life_percent")), 0.0, 1.0)
		_life_ratio = _target_life_ratio


func _make_materials_instance_local() -> void:
	var active_core := core_mesh.get_active_material(0)
	if active_core is StandardMaterial3D:
		_core_material = active_core.duplicate() as StandardMaterial3D
		core_mesh.material_override = _core_material
	_flame_material = flame_shell.material_override.duplicate() as ShaderMaterial
	flame_shell.material_override = _flame_material
	_inner_flame_material = inner_flame.material_override.duplicate() as ShaderMaterial
	inner_flame.material_override = _inner_flame_material

	var ember_source := ember_trail.draw_pass_1.surface_get_material(0)
	if ember_source is ShaderMaterial:
		_ember_material = ember_source.duplicate() as ShaderMaterial
		ember_trail.material_override = _ember_material
	var ambient_source := ambient_sparks.draw_pass_1.surface_get_material(0)
	if ambient_source is ShaderMaterial:
		_ambient_material = ambient_source.duplicate() as ShaderMaterial
		ambient_sparks.material_override = _ambient_material


func _cache_material_strengths() -> void:
	if _core_material:
		_base_core_emission = _core_material.emission_energy_multiplier
	if _flame_material:
		_base_outer_emission = float(_flame_material.get_shader_parameter("emission_strength"))
	if _inner_flame_material:
		_base_inner_emission = float(_inner_flame_material.get_shader_parameter("emission_strength"))
	if _ember_material:
		_base_trail_emission = float(_ember_material.get_shader_parameter("emission_strength"))


func _cache_default_palette() -> void:
	_default_core_color = core_color
	_default_inner_color = inner_flame_color
	_default_outer_color = outer_flame_color
	_default_ember_color = ember_color
	_default_light_color = light_color


func _apply_particle_tuning() -> void:
	ember_trail.amount = maxi(maximum_emission_amount, 1)
	ember_trail.lifetime = ember_lifetime
	var process_material := ember_trail.process_material as ParticleProcessMaterial
	if process_material:
		process_material.direction = Vector3(0.0, upward_velocity, backward_velocity).normalized()
		process_material.initial_velocity_min = maxf(backward_velocity * 0.55, 0.1)
		process_material.initial_velocity_max = maxf(backward_velocity, 0.2)
		process_material.spread = spread
		process_material.scale_min = ember_scale * 0.7
		process_material.scale_max = ember_scale * 1.25


func _emit_ember_burst(count: int, outward_speed: float) -> void:
	for _index in range(count):
		var direction := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.25, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		ember_trail.emit_particle(
			Transform3D.IDENTITY,
			direction * outward_speed + Vector3.UP * upward_velocity,
			ember_color,
			Color.WHITE,
			GPUParticles3D.EMIT_FLAG_POSITION
			| GPUParticles3D.EMIT_FLAG_VELOCITY
			| GPUParticles3D.EMIT_FLAG_COLOR
		)


func _smooth_weight(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)
