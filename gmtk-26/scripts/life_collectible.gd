class_name LifeCollectible
extends Area3D

signal collected(collector: Node3D, restore_amount: float)

@export_range(0.0, 1000.0, 0.1) var restore_amount: float = 20.0
@export_range(0.1, 60.0, 0.1) var respawn_time: float = 5.0
@export var collect_sound: AudioStream
@export_range(0.0, 2.0, 0.01) var hover_height: float = 0.2
@export_range(0.1, 10.0, 0.1) var hover_speed: float = 2.0

var _collected := false
var _respawn_timer: Timer
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
	if _collected or not body.is_in_group("player") or not body.has_method("add_life"):
		return

	_collected = true
	_set_available(false)
	body.add_life(restore_amount)
	if body.has_method("play_life_collect_sound"):
		body.play_life_collect_sound()
	if collect_sound != null:
		var audio := AudioStreamPlayer3D.new()
		audio.stream = collect_sound
		audio.bus = &"SFX"
		audio.finished.connect(audio.queue_free)
		add_child(audio)
		audio.play()
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
