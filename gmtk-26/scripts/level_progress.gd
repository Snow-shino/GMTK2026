class_name LevelProgress
extends RefCounted

const SAVE_PATH := "user://level_progress.cfg"
const SECTION := "visited_levels"


static func mark_visited(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION, scene_path, true)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save level progress. Error: %s" % error_string(error))


static func has_visited(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return config.get_value(SECTION, scene_path, false) as bool


static func is_unlocked(sequence: LevelSequence, level_index: int) -> bool:
	if sequence == null or level_index < 0 or level_index >= sequence.levels.size():
		return false
	if level_index == 0:
		return true
	var level := sequence.levels[level_index]
	return level != null and has_visited(level.resource_path)


static func clear_progress() -> void:
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if error != OK and error != ERR_DOES_NOT_EXIST:
		push_warning("Could not clear level progress. Error: %s" % error_string(error))
