class_name WispPlayer
extends CharacterBody3D

signal life_changed(current_life: float, max_life: float)
signal life_depleted

@export_category("Movement")
@export_range(0.1, 30.0, 0.1) var move_speed: float = 6.0
@export_range(0.1, 100.0, 0.1) var acceleration: float = 24.0
@export_range(0.1, 100.0, 0.1) var deceleration: float = 30.0
@export_range(0.1, 30.0, 0.1) var rotation_speed: float = 10.0
@export_range(0.1, 30.0, 0.1) var jump_velocity: float = 7.0

@onready var camera: Camera3D = %Camera3D
@onready var visual: Node3D = %Visual
@onready var life: Node = %LifeComponent

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	add_to_group("player")
	life.life_changed.connect(_on_life_changed)
	life.life_depleted.connect(_on_life_depleted)
	life.life_changed.emit(life.current_life, life.max_life)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var camera_forward := -camera.global_basis.z
	var camera_right := camera.global_basis.x
	camera_forward.y = 0.0
	camera_right.y = 0.0
	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()
	var move_direction := (camera_right * input_vector.x + camera_forward * -input_vector.y).normalized()

	var target_velocity := move_direction * move_speed
	var change_rate := acceleration if not move_direction.is_zero_approx() else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, change_rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, change_rate * delta)

	if not move_direction.is_zero_approx():
		var target_angle := atan2(-move_direction.x, -move_direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, rotation_speed * delta)

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
