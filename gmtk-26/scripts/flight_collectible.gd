class_name FlightCollectible
extends Area3D

signal collected(collector: Node3D, restore_amount: float)

@export_range(0.0, 1000.0, 0.1) var restore_amount: float = 20.0
@export_range(0.1, 60.0, 0.1) var respawn_time: float = 5.0
@export_range(0.0, 2.0, 0.01) var hover_height: float = 0.2
@export_range(0.1, 10.0, 0.1) var hover_speed: float = 2.0

var _collected := false
var _respawn_timer: Timer
static var _has_shown_pickup_prompt := false
var _base_y := 0.0
var _hover_time := 0.0


func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_respawn)
	add_child(_respawn_timer)


func _process(delta: float) -> void:
	_hover_time += delta * hover_speed
	position.y = _base_y + sin(_hover_time) * hover_height


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player") or not body.has_method("_handle_flight"):
		return

	_collected = true
	_set_available(false)
	if "has_flight_powerup" in body:
		body.has_flight_powerup = true
		_show_pickup_prompt()
	if "is_flying" in body:
		body.flight_decay = 4.5
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
		elif child is Node3D:
			child.visible = available


func _show_pickup_prompt() -> void:
	if _has_shown_pickup_prompt:
		return
	_has_shown_pickup_prompt = true

	var layer := CanvasLayer.new()
	layer.layer = 10
	get_tree().current_scene.add_child(layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-170.0, 80.0)
	panel.size = Vector2(340.0, 82.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.08, 0.13, 0.9)
	style.border_color = Color(0.45, 0.85, 1.0, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var label := Label.new()
	label.text = "FLIGHT\nHold SPACE to fly"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	panel.add_child(label)

	var tween := layer.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(layer, "modulate:a", 0.0, 0.25)
	tween.tween_callback(layer.queue_free)
