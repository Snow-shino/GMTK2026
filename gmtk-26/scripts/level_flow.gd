class_name LevelFlow
extends Node3D

enum LevelState {
	PLAYING,
	COMPLETED,
	FAILED,
}

@export var level_sequence: LevelSequence
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
	if level_sequence == null:
		level_sequence = load("res://Data/level_sequence.tres") as LevelSequence
	var current_path := _get_current_scene_path()
	LevelProgress.mark_visited(current_path)
	_validate_sequence(current_path)
	hud.bind_player(player)
	player.life_depleted.connect(_on_life_depleted)
	goal.level_completed.connect(_on_level_completed)
	if level_sequence != null:
		_start_loop(music_player, level_sequence.base_music, level_sequence.music_volume_db)
		_start_loop(ambience_player, level_sequence.ambient_loop, level_sequence.ambience_volume_db)


func _unhandled_input(event: InputEvent) -> void:
	if state == LevelState.PLAYING and event.is_action_pressed("restart"):
		get_tree().call_deferred("reload_current_scene")


func _on_level_completed(completed_goal: LevelGoal) -> void:
	if not _leave_playing(LevelState.COMPLETED):
		return
	await get_tree().create_timer(completed_goal.completion_delay).timeout
	if state != LevelState.COMPLETED:
		return
	var next_level: PackedScene
	var main_menu: PackedScene
	if level_sequence != null:
		var current_path := _get_current_scene_path()
		next_level = level_sequence.get_next_level(current_path)
		main_menu = level_sequence.main_menu
		_play_state_sound(level_sequence.victory_sound)
	result_screen.show_completion(
		player.get_current_life(),
		next_level,
		main_menu
	)


func _on_life_depleted() -> void:
	if not _leave_playing(LevelState.FAILED):
		return
	if level_sequence != null:
		_play_state_sound(level_sequence.failure_sound)
	await get_tree().create_timer(failure_delay).timeout
	if state == LevelState.FAILED:
		result_screen.show_failure(level_sequence.main_menu if level_sequence != null else null)


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


func _play_state_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	state_audio.stream = stream
	state_audio.play()


func _validate_sequence(current_path: String) -> void:
	if level_sequence == null:
		push_warning("LevelFlow has no LevelSequence resource assigned.")
		return
	if level_sequence.get_level_index(current_path) < 0:
		push_warning("Current scene is not in LevelSequence: %s" % current_path)


func _get_current_scene_path() -> String:
	if get_tree().current_scene != null:
		return get_tree().current_scene.scene_file_path
	return scene_file_path
