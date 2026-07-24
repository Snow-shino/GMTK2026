class_name LevelGoal
extends Area3D

signal level_completed(goal: LevelGoal)
signal goal_feedback_requested

@export_file("*.tscn") var next_level_path: String
@export_file("*.tscn") var main_menu_path: String
@export_range(0.0, 10.0, 0.1) var completion_delay: float = 0.75
@export var goal_enabled := true
@export var goal_reached_sound: AudioStream

var _completed := false
@onready var audio_player: AudioStreamPlayer3D = %GoalAudio


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func set_goal_enabled(enabled: bool) -> void:
	goal_enabled = enabled
	monitoring = enabled and not _completed


func _on_body_entered(body: Node3D) -> void:
	if not goal_enabled or _completed or not body.is_in_group("player"):
		return
	_completed = true
	monitoring = false
	if goal_reached_sound != null:
		audio_player.stream = goal_reached_sound
		audio_player.play()
	goal_feedback_requested.emit()
	level_completed.emit(self)
