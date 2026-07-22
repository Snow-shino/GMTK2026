class_name WispPlayer
extends CharacterBody3D

signal life_changed(current_life: float, max_life: float)
signal life_depleted

@export_category("Movement")
@export_range(0.1, 30.0, 0.1) var move_speed: float = 6.0
@export_range(0.1, 100.0, 0.1) var acceleration: float = 24.0
@export_range(0.1, 100.0, 0.1) var deceleration: float = 30.0
@export_range(0.1, 30.0, 0.1) var jump_velocity: float = 9.5

@export_category("Air Movement")
@export_range(0.1, 100.0, 0.1) var upward_gravity: float = 16.0
@export_range(0.1, 100.0, 0.1) var downward_gravity: float = 22.0
@export_range(0.0, 1.0, 0.05) var jump_cut_multiplier: float = 0.45
@export_range(0.1, 100.0, 0.1) var air_acceleration: float = 22.0
@export_range(0.0, 100.0, 0.1) var air_deceleration: float = 5.0
@export_range(0.1, 30.0, 0.1) var max_air_speed: float = 6.5

@export_category("Camera")
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.15
@export_range(-89.0, 0.0, 1.0) var min_camera_pitch: float = -60.0
@export_range(0.0, 89.0, 1.0) var max_camera_pitch: float = 35.0

@onready var camera: Camera3D = %Camera3D
@onready var camera_pivot: Node3D = %CameraPivot
@onready var life: Node = %LifeComponent

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
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
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= jump_cut_multiplier

	if not is_on_floor():
		var gravity := upward_gravity if velocity.y > 0.0 else downward_gravity
		velocity.y -= gravity * delta

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var camera_forward := -camera.global_basis.z
	var camera_right := camera.global_basis.x
	camera_forward.y = 0.0
	camera_right.y = 0.0
	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()
	var move_direction := (camera_right * input_vector.x + camera_forward * -input_vector.y).normalized()

	var target_speed := move_speed if is_on_floor() else max_air_speed
	var target_velocity := move_direction * target_speed
	var change_rate: float
	if is_on_floor():
		change_rate = acceleration if not move_direction.is_zero_approx() else deceleration
	else:
		change_rate = air_acceleration if not move_direction.is_zero_approx() else air_deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, change_rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, change_rate * delta)

	move_and_slide()


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
