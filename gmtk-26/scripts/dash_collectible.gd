class_name DashCollectible
extends Area3D

signal collected(collector: Node3D, restore_amount: float)
@export_range(0.0, 1000.0, 0.1) var restore_amount: float = 20.0
var _collected = false
func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player") or not body.has_method("dash"):
		return

	_collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
		elif child is VisualInstance3D:
			child.hide()
		# Give dash powerup
	
	if "has_dash_powerup" in body:
		body.has_dash_powerup = true

	body.add_life(restore_amount)
	collected.emit(body, restore_amount)
	queue_free()


	
	
	
