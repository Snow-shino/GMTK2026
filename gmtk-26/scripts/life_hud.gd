class_name LifeHUD
extends CanvasLayer

@onready var life_bar: ProgressBar = %LifeBar


func bind_player(player: Node) -> void:
	if not is_node_ready():
		await ready
	player.life_changed.connect(_on_life_changed)
	_on_life_changed(player.get_current_life(), player.get_max_life())


func _on_life_changed(current_life: float, max_life: float) -> void:
	life_bar.max_value = max_life
	life_bar.value = current_life
