class_name LevelResultScreen
extends CanvasLayer

@export var completion_screen_open_sound: AudioStream
@export var failure_screen_open_sound: AudioStream
@export var button_hover_sound: AudioStream
@export var button_pressed_sound: AudioStream

var _next_level_path := ""
var _main_menu_path := ""
var _navigating := false

@onready var title_label: Label = %TitleLabel
@onready var life_label: Label = %LifeLabel
@onready var restart_button: Button = %RestartButton
@onready var next_button: Button = %NextButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var ui_audio: AudioStreamPlayer = %UIAudio


func _ready() -> void:
	hide()
	restart_button.pressed.connect(_restart_level)
	next_button.pressed.connect(_load_next_level)
	main_menu_button.pressed.connect(_load_main_menu)
	for button in [restart_button, next_button, main_menu_button]:
		button.mouse_entered.connect(_play_hover)


func show_completion(remaining_life: float, next_path: String, menu_path: String) -> void:
	_next_level_path = _resolve_scene_path(next_path)
	_main_menu_path = _resolve_scene_path(menu_path)
	title_label.text = "LEVEL COMPLETE"
	life_label.text = "Life Essence Remaining: %.1f" % remaining_life
	life_label.show()
	next_button.visible = _is_valid_scene(_next_level_path)
	main_menu_button.disabled = not _is_valid_scene(_main_menu_path)
	_show_screen(completion_screen_open_sound)


func show_failure(menu_path: String) -> void:
	_next_level_path = ""
	_main_menu_path = _resolve_scene_path(menu_path)
	title_label.text = "LIGHT EXTINGUISHED"
	life_label.hide()
	next_button.hide()
	main_menu_button.disabled = not _is_valid_scene(_main_menu_path)
	_show_screen(failure_screen_open_sound)


func _show_screen(open_sound: AudioStream) -> void:
	_navigating = false
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	restart_button.grab_focus()
	_play_sound(open_sound)


func _restart_level() -> void:
	if _begin_navigation():
		get_tree().reload_current_scene()


func _load_next_level() -> void:
	_change_scene(_next_level_path, "next level")


func _load_main_menu() -> void:
	_change_scene(_main_menu_path, "main menu")


func _change_scene(path: String, label: String) -> void:
	if not _is_valid_scene(path):
		push_warning("Cannot load %s: invalid or empty scene path '%s'." % [label, path])
		return
	if _begin_navigation():
		get_tree().change_scene_to_file(path)


func _begin_navigation() -> bool:
	if _navigating:
		return false
	_navigating = true
	restart_button.disabled = true
	next_button.disabled = true
	main_menu_button.disabled = true
	_play_sound(button_pressed_sound)
	return true


func _is_valid_scene(path: String) -> bool:
	return not path.is_empty() and ResourceLoader.exists(path, "PackedScene")


func _resolve_scene_path(path: String) -> String:
	if not path.begins_with("uid://"):
		return path
	var resource_id := ResourceUID.text_to_id(path)
	if resource_id == ResourceUID.INVALID_ID:
		return ""
	if ResourceUID.has_id(resource_id):
		return ResourceUID.get_id_path(resource_id)
	return _find_scene_by_uid("res://", path)


func _find_scene_by_uid(directory_path: String, uid_text: String) -> String:
	for file_name in DirAccess.get_files_at(directory_path):
		if not file_name.ends_with(".tscn"):
			continue
		var scene_path := directory_path.path_join(file_name)
		var file := FileAccess.open(scene_path, FileAccess.READ)
		if file != null and file.get_line().contains(uid_text):
			return scene_path
	for directory_name in DirAccess.get_directories_at(directory_path):
		if directory_name.begins_with("."):
			continue
		var found := _find_scene_by_uid(directory_path.path_join(directory_name), uid_text)
		if not found.is_empty():
			return found
	return ""


func _play_hover() -> void:
	_play_sound(button_hover_sound)


func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	ui_audio.stream = stream
	ui_audio.play()
