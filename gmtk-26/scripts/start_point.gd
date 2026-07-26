class_name StartPoint
extends Area3D

## When enabled, entering this area updates the player's respawn location.
@export var register_as_respawn_point: bool = true

## When enabled, Life Essence does not drain while the player is in this area.
@export var pause_life_drain_inside: bool = true

@onready var respawn_marker: Marker3D = %RespawnMarker

var _players_inside: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	_players_inside[body.get_instance_id()] = true

	if register_as_respawn_point and body.has_method("set_respawn_transform"):
		body.set_respawn_transform(respawn_marker.global_transform)

	if pause_life_drain_inside and body.has_method("set_life_drain_enabled"):
		body.set_life_drain_enabled(false)


func _on_body_exited(body: Node3D) -> void:
	if not _players_inside.erase(body.get_instance_id()):
		return

	if pause_life_drain_inside and body.has_method("set_life_drain_enabled"):
		body.set_life_drain_enabled(true)
