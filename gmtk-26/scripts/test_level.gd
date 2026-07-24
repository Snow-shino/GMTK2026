extends LevelFlow

const GOAL_SCENE := preload("res://scenes/level_goal.tscn")
const RESULT_SCREEN_SCENE := preload("res://scenes/level_result_screen.tscn")
const MUSIC_REGION_SCENE := preload("res://scenes/area_music_region.tscn")

@export_category("Test Level Flow")
@export var goal_position := Vector3(-14.0, 8.0, -112.0)
@export var area_music_position := Vector3(-8.0, 2.0, -45.0)


func _enter_tree() -> void:
	var level_goal := GOAL_SCENE.instantiate() as LevelGoal
	level_goal.name = "LevelGoal"
	level_goal.unique_name_in_owner = true
	level_goal.position = goal_position
	add_child(level_goal)

	var screen := RESULT_SCREEN_SCENE.instantiate() as LevelResultScreen
	screen.name = "LevelResultScreen"
	screen.unique_name_in_owner = true
	add_child(screen)

	_add_audio_player("BackgroundMusic")
	_add_audio_player("AmbientLoop")
	_add_audio_player("StateAudio")

	var music_region := MUSIC_REGION_SCENE.instantiate() as AreaMusicRegion
	music_region.name = "AreaMusicRegion"
	music_region.position = area_music_position
	music_region.music_player_path = NodePath("../BackgroundMusic")
	add_child(music_region)


func _ready() -> void:
	super._ready()


func _add_audio_player(node_name: String) -> void:
	var audio_player := AudioStreamPlayer.new()
	audio_player.name = node_name
	audio_player.unique_name_in_owner = true
	add_child(audio_player)
