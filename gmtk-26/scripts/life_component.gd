class_name LifeComponent
extends Node

signal life_changed(current_life: float, max_life: float)
signal life_depleted

@export_category("Life Left")
@export_range(0.1, 1000.0, 0.1) var max_life: float = 100.0
@export_range(0.0, 1000.0, 0.1) var starting_life: float = 100.0
@export_range(0.0, 100.0, 0.1) var drain_rate: float = 2.0

var current_life: float
var drain_enabled := true
var _depleted_emitted := false


func _ready() -> void:
	reset_life()


func _process(delta: float) -> void:
	if drain_enabled:
		remove_life(drain_rate * delta)


func set_drain_enabled(enabled: bool) -> void:
	drain_enabled = enabled


func add_life(amount: float) -> void:
	_set_life(current_life + maxf(amount, 0.0))


func remove_life(amount: float) -> void:
	_set_life(current_life - maxf(amount, 0.0))


func reset_life() -> void:
	_depleted_emitted = false
	_set_life(starting_life)


func get_life_percent() -> float:
	if max_life <= 0.0:
		return 0.0
	return current_life / max_life


func _set_life(value: float) -> void:
	var clamped_max := maxf(max_life, 0.0)
	var next_life := clampf(value, 0.0, clamped_max)
	if not is_equal_approx(next_life, current_life):
		current_life = next_life
		life_changed.emit(current_life, clamped_max)

	if current_life <= 0.0 and not _depleted_emitted:
		_depleted_emitted = true
		life_depleted.emit()
	elif current_life > 0.0:
		_depleted_emitted = false
