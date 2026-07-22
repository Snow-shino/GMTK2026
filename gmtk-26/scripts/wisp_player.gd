class_name WispPlayer
extends CharacterBody3D

signal life_changed(current_life: float, max_life: float)
signal life_depleted

@export_category("Ground Movement")
@export_range(0.1, 30.0, 0.1) var max_ground_speed: float = 16.0
@export_range(0.1, 100.0, 0.1) var ground_acceleration: float = 56.0
@export_range(0.1, 100.0, 0.1) var ground_deceleration: float = 68.0
@export_range(0.1, 120.0, 0.1) var turn_acceleration: float = 82.0
@export_range(0.1, 30.0, 0.1) var rotation_speed: float = 16.0
@export_range(0.0, 0.9, 0.01) var input_deadzone: float = 0.12

@export_category("Air Movement")
@export_range(0.1, 30.0, 0.1) var max_air_speed: float = 17.0
@export_range(0.1, 100.0, 0.1) var air_acceleration: float = 38.0
@export_range(0.0, 100.0, 0.1) var air_deceleration: float = 8.0

@export_category("Jump")
@export_range(0.1, 30.0, 0.1) var jump_velocity: float = 17.0
@export_range(0.1, 100.0, 0.1) var upward_gravity: float = 14.0
@export_range(0.1, 100.0, 0.1) var downward_gravity: float = 26.0
@export_range(0.0, 1.0, 0.05) var jump_cut_multiplier: float = 0.45
@export_range(1.0, 100.0, 0.5) var max_fall_speed: float = 32.0

@export_category("Camera")
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.15
@export_range(-89.0, 0.0, 1.0) var min_camera_pitch: float = -60.0
@export_range(0.0, 89.0, 1.0) var max_camera_pitch: float = 35.0

@onready var camera: Camera3D = %Camera3D
@onready var camera_pivot: Node3D = %CameraPivot
@onready var life: Node = %LifeComponent

var _camera_follow_offset := Vector3.ZERO


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	floor_snap_length = 0.3
	floor_stop_on_slope = true

	# Keep camera-relative input independent from gameplay-facing rotation.
	_camera_follow_offset = camera_pivot.global_position - global_position
	var camera_transform := camera_pivot.global_transform
	camera_pivot.top_level = true
	camera_pivot.global_transform = camera_transform

	life.life_changed.connect(_on_life_changed)
	life.life_depleted.connect(_on_life_depleted)
	life.life_changed.emit(life.current_life, life.max_life)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= deg_to_rad(event.relative.x * mouse_sensitivity)
		camera_pivot.rotation.x -= deg_to_rad(event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clampf(
			camera_pivot.rotation.x,
			deg_to_rad(min_camera_pitch),
			deg_to_rad(max_camera_pitch)
		)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var grounded := is_on_floor()
	_handle_jump_and_gravity(delta, grounded)

	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward",
		input_deadzone
	)
	var input_strength := minf(input_vector.length(), 1.0)
	var move_direction := _get_camera_relative_direction(input_vector)
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)

	if grounded:
		horizontal_velocity = _update_ground_velocity(
			horizontal_velocity,
			move_direction,
			input_strength,
			delta
		)
	else:
		horizontal_velocity = _update_air_velocity(
			horizontal_velocity,
			move_direction,
			input_strength,
			delta
		)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	_update_facing(move_direction, input_strength, delta)
	move_and_slide()
	camera_pivot.global_position = global_position + _camera_follow_offset


func _handle_jump_and_gravity(delta: float, grounded: bool) -> void:
	if grounded and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= jump_cut_multiplier

	if not grounded or velocity.y > 0.0:
		var gravity := upward_gravity if velocity.y > 0.0 else downward_gravity
		velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length_squared() <= input_deadzone * input_deadzone:
		return Vector3.ZERO

	var camera_forward := -camera.global_basis.z
	var camera_right := camera.global_basis.x
	camera_forward.y = 0.0
	camera_right.y = 0.0

	if camera_forward.length_squared() > 0.0001:
		camera_forward = camera_forward.normalized()
	if camera_right.length_squared() > 0.0001:
		camera_right = camera_right.normalized()

	var direction := (
		camera_right * input_vector.x
		+ camera_forward * -input_vector.y
	)
	if direction.length_squared() <= 0.0001:
		return Vector3.ZERO
	return direction.normalized()


func _update_ground_velocity(
	current: Vector3,
	direction: Vector3,
	input_strength: float,
	delta: float
) -> Vector3:
	if direction.is_zero_approx() or input_strength <= input_deadzone:
		return current.move_toward(Vector3.ZERO, ground_deceleration * delta)

	var target := direction * max_ground_speed * input_strength
	var rate := ground_acceleration
	if current.length_squared() > 0.01 and current.dot(direction) < 0.0:
		rate = turn_acceleration
	return current.move_toward(target, rate * delta)


func _update_air_velocity(
	current: Vector3,
	direction: Vector3,
	input_strength: float,
	delta: float
) -> Vector3:
	var result := current
	if direction.is_zero_approx() or input_strength <= input_deadzone:
		result = result.move_toward(Vector3.ZERO, air_deceleration * delta)
	else:
		var target := direction * max_air_speed * input_strength
		result = result.move_toward(target, air_acceleration * delta)

	if result.length() > max_air_speed:
		result = result.normalized() * max_air_speed
	return result


func _update_facing(direction: Vector3, input_strength: float, delta: float) -> void:
	if direction.is_zero_approx() or input_strength <= input_deadzone:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(
		rotation.y,
		target_yaw,
		1.0 - exp(-rotation_speed * delta)
	)


func add_life(amount: float) -> void:
	life.add_life(amount)


func remove_life(amount: float) -> void:
	life.remove_life(amount)


func reset_life() -> void:
	life.reset_life()


func get_life_percent() -> float:
	return life.get_life_percent()


func get_current_life() -> float:
	return life.current_life


func get_max_life() -> float:
	return life.max_life


func _on_life_changed(current_life: float, max_life: float) -> void:
	life_changed.emit(current_life, max_life)


func _on_life_depleted() -> void:
	life_depleted.emit()
