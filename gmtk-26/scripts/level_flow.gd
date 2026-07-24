class_name LevelFlow
extends Node3D

enum LevelState {
	PLAYING,
	COMPLETED,
	FAILED,
}

@export_category("Level Audio")
@export var background_music: AudioStream
@export var ambient_loop: AudioStream
@export var level_failed_sound: AudioStream
@export_range(-80.0, 6.0, 0.1) var music_volume_db := -8.0
@export_range(-80.0, 6.0, 0.1) var ambience_volume_db := -12.0
@export_range(0.0, 10.0, 0.1) var failure_delay := 0.5

var state := LevelState.PLAYING

@onready var player: WispPlayer = get_node("Player")
@onready var goal: LevelGoal = get_node("LevelGoal")
@onready var hud: CanvasLayer = get_node("LifeHUD")
@onready var result_screen: LevelResultScreen = get_node("LevelResultScreen")
@onready var music_player: AudioStreamPlayer = get_node("BackgroundMusic")
@onready var ambience_player: AudioStreamPlayer = get_node("AmbientLoop")
@onready var state_audio: AudioStreamPlayer = get_node("StateAudio")


func _ready() -> void:
	hud.bind_player(player)
	player.life_depleted.connect(_on_life_depleted)
	goal.level_completed.connect(_on_level_completed)
	_start_loop(music_player, background_music, music_volume_db)
	_start_loop(ambience_player, ambient_loop, ambience_volume_db)


func _unhandled_input(event: InputEvent) -> void:
	if state == LevelState.PLAYING and event.is_action_pressed("restart"):
		get_tree().call_deferred("reload_current_scene")


func _on_level_completed(completed_goal: LevelGoal) -> void:
	if not _leave_playing(LevelState.COMPLETED):
		return
	await get_tree().create_timer(completed_goal.completion_delay).timeout
	if state != LevelState.COMPLETED:
		return
	result_screen.show_completion(
		player.get_current_life(),
		completed_goal.next_level_path,
		completed_goal.main_menu_path
	)


func _on_life_depleted() -> void:
	if not _leave_playing(LevelState.FAILED):
		return
	if level_failed_sound != null:
		state_audio.stream = level_failed_sound
		state_audio.play()
	await get_tree().create_timer(failure_delay).timeout
	if state == LevelState.FAILED:
		result_screen.show_failure(goal.main_menu_path)


func _leave_playing(next_state: LevelState) -> bool:
	if state != LevelState.PLAYING:
		return false
	state = next_state
	player.set_control_enabled(false)
	player.set_life_drain_enabled(false)
	goal.set_goal_enabled(false)
	return true


func _start_loop(player_node: AudioStreamPlayer, stream: AudioStream, volume_db: float) -> void:
	player_node.volume_db = volume_db
	if stream == null:
		return
	player_node.stream = stream
	if not player_node.finished.is_connected(player_node.play):
		player_node.finished.connect(player_node.play)
	player_node.play()
