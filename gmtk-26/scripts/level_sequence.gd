class_name LevelSequence
extends Resource

@export var levels: Array[PackedScene] = []
@export var main_menu: PackedScene

@export_category("Shared Level Audio")
@export var base_music: AudioStream
@export var ambient_loop: AudioStream
@export var victory_sound: AudioStream
@export var failure_sound: AudioStream
@export_range(-80.0, 6.0, 0.1) var music_volume_db := -8.0
@export_range(-80.0, 6.0, 0.1) var ambience_volume_db := -12.0


func get_level_index(current_scene_path: String) -> int:
	if current_scene_path.is_empty():
		return -1
	for index in levels.size():
		var level := levels[index]
		if level != null and level.resource_path == current_scene_path:
			return index
	return -1


func get_current_level_index(current_scene_path: String) -> int:
	return get_level_index(current_scene_path)


func get_next_level(current_scene_path: String) -> PackedScene:
	var current_index := get_level_index(current_scene_path)
	var next_index := current_index + 1
	if current_index < 0 or next_index >= levels.size():
		return null
	return levels[next_index]


func has_next_level(current_scene_path: String) -> bool:
	return get_next_level(current_scene_path) != null
