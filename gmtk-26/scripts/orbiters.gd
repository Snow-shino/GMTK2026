class_name PowerupFollower
extends Node3D

@export_enum("dash", "flight") var powerup_type := "dash"
@export var orbit_radius := 1.6
@export var orbit_height := 1.1
@export var orbit_speed := 8.55 # radians per second; slow
@export var orbit_phase := 0.0 # lets Dash and Flight start apart

var player: WispPlayer
var _angle := 0.0

func _ready() -> void:
	visible = false
	player = get_parent() as WispPlayer
	if player == null:
		push_error("PowerupFollower must be a child of Player.")
		return

	

func _process(delta: float) -> void:
	if player == null:
		return

	var has_powerup := (
		player.has_dash_powerup
		if powerup_type == "dash"
		else player.has_flight_powerup
	)

	visible = has_powerup
	if not visible:
		return

	_angle = fmod(_angle + orbit_speed * delta, TAU)

	global_position = player.global_position + Vector3(
	cos(_angle + orbit_phase) * orbit_radius,
	orbit_height,
	sin(_angle + orbit_phase) * orbit_radius
)

func _on_powerup_used(used_type: String) -> void:
	if used_type == powerup_type:
		visible = false
