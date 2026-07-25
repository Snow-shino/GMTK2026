class_name CollectibleWispVisual
extends Node3D

@export_category("Idle")
@export_range(0.0, 1.0, 0.01) var bob_amplitude := 0.15
@export_range(0.1, 10.0, 0.1) var bob_speed := 1.8
@export_range(0.0, 1.0, 0.01) var sway_amplitude := 0.05
@export_range(0.0, 0.2, 0.005) var scale_pulse_amount := 0.03
@export_range(0.0, 45.0, 0.1) var rotation_speed := 12.0

@export_category("Visual Flicker")
@export_range(0.0, 1.0, 0.01) var flicker_strength := 0.06
@export_range(0.1, 30.0, 0.1) var flicker_speed := 4.0

@onready var core_mesh: MeshInstance3D = $CoreMesh
@onready var flame_shell: MeshInstance3D = %FlameShell
@onready var inner_flame: MeshInstance3D = %InnerFlame
@onready var ember_trail: GPUParticles3D = %EmberTrail
@onready var ambient_sparks: GPUParticles3D = %AmbientSparks
@onready var wisp_light: OmniLight3D = %WispLight

var _base_position := Vector3.ZERO
var _base_scale := Vector3.ONE

var _core_material: StandardMaterial3D
var _flame_material: ShaderMaterial
var _inner_flame_material: ShaderMaterial
var _ember_material: ShaderMaterial
var _ambient_material: ShaderMaterial

var _time := 0.0
var _phase := 0.0

var _base_core_emission := 1.0
var _base_outer_emission := 1.0
var _base_inner_emission := 1.0
var _base_light_energy := 1.0


func _ready() -> void:
	_base_position = position
	_base_scale = scale
	_base_light_energy = wisp_light.light_energy

	_phase = randf() * TAU

	_make_materials_instance_local()
	_cache_material_strengths()


func _process(delta: float) -> void:
	_time += delta

	_update_idle_motion()
	_update_flicker()


func _update_idle_motion() -> void:
	var bob := sin(_time * bob_speed + _phase) * bob_amplitude

	var sway := Vector3(
		sin(_time * bob_speed * 0.6 + _phase),
		0.0,
		cos(_time * bob_speed * 0.4 + _phase)
	) * sway_amplitude

	position = _base_position + Vector3.UP * bob + sway

	rotation.y += deg_to_rad(rotation_speed) * get_process_delta_time()

	var pulse := sin(_time * bob_speed * 1.4 + _phase)
	scale = _base_scale * (1.0 + pulse * scale_pulse_amount)


func _update_flicker() -> void:
	var flicker := 1.0 + (
		sin(_time * flicker_speed * 10.0 + _phase)
		* flicker_strength
	)

	if _core_material:
		_core_material.emission_energy_multiplier = (
			_base_core_emission * flicker
		)

	if _flame_material:
		_flame_material.set_shader_parameter(
			"emission_strength",
			_base_outer_emission * flicker
		)

	if _inner_flame_material:
		_inner_flame_material.set_shader_parameter(
			"emission_strength",
			_base_inner_emission * flicker
		)

	wisp_light.light_energy = _base_light_energy * flicker


func _make_materials_instance_local() -> void:
	var active_core := core_mesh.get_active_material(0)

	if active_core is StandardMaterial3D:
		_core_material = active_core.duplicate()
		core_mesh.material_override = _core_material

	_flame_material = flame_shell.material_override.duplicate()
	flame_shell.material_override = _flame_material

	_inner_flame_material = inner_flame.material_override.duplicate()
	inner_flame.material_override = _inner_flame_material

	var ember_source := ember_trail.draw_pass_1.surface_get_material(0)
	if ember_source is ShaderMaterial:
		_ember_material = ember_source.duplicate()
		ember_trail.material_override = _ember_material

	var ambient_source := ambient_sparks.draw_pass_1.surface_get_material(0)
	if ambient_source is ShaderMaterial:
		_ambient_material = ambient_source.duplicate()
		ambient_sparks.material_override = _ambient_material


func _cache_material_strengths() -> void:
	if _core_material:
		_base_core_emission = _core_material.emission_energy_multiplier

	if _flame_material:
		_base_outer_emission = float(
			_flame_material.get_shader_parameter("emission_strength")
		)

	if _inner_flame_material:
		_base_inner_emission = float(
			_inner_flame_material.get_shader_parameter("emission_strength")
		)
