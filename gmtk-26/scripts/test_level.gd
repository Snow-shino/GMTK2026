extends LevelFlow

const GOAL_SCENE := preload("res://scenes/level_goal.tscn")
const RESULT_SCREEN_SCENE := preload("res://scenes/level_result_screen.tscn")
const MUSIC_REGION_SCENE := preload("res://scenes/area_music_region.tscn")

@export_category("Test Level Flow")
@export var goal_position := Vector3(-14.0, 8.0, -112.0)
@export var area_music_position := Vector3(-8.0, 2.0, -45.0)
@export_file("*.tscn") var next_level_path: String
@export_file("*.tscn") var main_menu_path := "res://scenes/main_menu.tscn"
@export_range(0.0, 10.0, 0.1) var completion_delay := 0.75


func _enter_tree() -> void:
	if not has_node("LevelGoal"):
		var level_goal := GOAL_SCENE.instantiate() as LevelGoal
		level_goal.name = "LevelGoal"
		level_goal.unique_name_in_owner = true
		level_goal.position = goal_position
		level_goal.next_level_path = next_level_path
		level_goal.main_menu_path = main_menu_path
		level_goal.completion_delay = completion_delay
		add_child(level_goal)
	else:
		var existing_goal := get_node("LevelGoal") as LevelGoal
		if existing_goal.main_menu_path.is_empty():
			existing_goal.main_menu_path = main_menu_path

	if not has_node("LevelResultScreen"):
		var screen := RESULT_SCREEN_SCENE.instantiate() as LevelResultScreen
		screen.name = "LevelResultScreen"
		screen.unique_name_in_owner = true
		add_child(screen)

	for audio_name in ["BackgroundMusic", "AmbientLoop", "StateAudio"]:
		if not has_node(audio_name):
			_add_audio_player(audio_name)

	if not has_node("AreaMusicRegion"):
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
