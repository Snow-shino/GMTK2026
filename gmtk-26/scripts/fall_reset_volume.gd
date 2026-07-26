class_name FallResetVolume
extends Area3D

## When enabled, only bodies in the "player" group can trigger the volume.
@export var require_player_group: bool = true

var _triggered_bodies: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if require_player_group and not body.is_in_group("player"):
		return
	if not body.has_method("respawn"):
		push_warning("FallResetVolume detected a player without a respawn() method.")
		return

	var body_id := body.get_instance_id()
	if _triggered_bodies.has(body_id):
		return
	_triggered_bodies[body_id] = true
	body.call_deferred("respawn")


func _on_body_exited(body: Node3D) -> void:
	_triggered_bodies.erase(body.get_instance_id())
