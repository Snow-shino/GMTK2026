extends Node3D

@onready var player: Node = %Player
@onready var hud: CanvasLayer = %LifeHUD


func _ready() -> void:
	hud.bind_player(player)
	player.life_depleted.connect(_on_player_life_depleted)


func _on_player_life_depleted() -> void:
	print("Life Left reached zero.")
