class_name LifeHUD
extends CanvasLayer

@export_range(0.05, 0.95, 0.05) var low_life_threshold := 0.3
@export var normal_color := Color(0.25, 0.82, 1.0, 1.0)
@export var low_life_color := Color(1.0, 0.12, 0.08, 1.0)
@export_range(1.0, 2.0, 0.05) var low_life_scale := 1.15

@onready var life_bar: ProgressBar = %LifeBar
var _is_low_life := false
var _fill_style: StyleBoxFlat


func bind_player(player: Node) -> void:
	if not is_node_ready():
		await ready
	if not player.life_changed.is_connected(_on_life_changed):
		player.life_changed.connect(_on_life_changed)
	_on_life_changed(player.get_current_life(), player.get_max_life())


func _on_life_changed(current_life: float, max_life: float) -> void:
	life_bar.max_value = max_life
	life_bar.value = current_life
	var ratio := current_life / max_life if max_life > 0.0 else 0.0
	var should_be_low := ratio <= low_life_threshold
	if should_be_low != _is_low_life:
		_is_low_life = should_be_low
		_update_urgency_style()


func _ready() -> void:
	_fill_style = life_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	life_bar.add_theme_stylebox_override("fill", _fill_style)
	_update_urgency_style()


func _update_urgency_style() -> void:
	if _fill_style == null:
		return
	_fill_style.bg_color = low_life_color if _is_low_life else normal_color
	var target_scale := Vector2.ONE * (low_life_scale if _is_low_life else 1.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(life_bar, "scale", target_scale, 0.18)
