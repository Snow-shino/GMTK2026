class_name FlightCollectible
extends Area3D

signal collected(collector: Node3D, restore_amount: float)

@export_range(0.0, 1000.0, 0.1) var restore_amount: float = 20.0
@export_range(0.1, 60.0, 0.1) var respawn_time: float = 5.0

var _collected := false
var _respawn_timer: Timer


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_respawn)
	add_child(_respawn_timer)


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player") or not body.has_method("_handle_flight"):
		return

	_collected = true
	_set_available(false)
	if "has_flight_powerup" in body:
		body.has_flight_powerup = true
	body.add_life(restore_amount)
	collected.emit(body, restore_amount)
	_respawn_timer.start(respawn_time)


func _respawn() -> void:
	if not is_inside_tree():
		return
	_collected = false
	_set_available(true)


func _set_available(available: bool) -> void:
	set_deferred("monitoring", available)
	set_deferred("monitorable", available)
	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", not available)
		elif child is VisualInstance3D:
			child.visible = available
