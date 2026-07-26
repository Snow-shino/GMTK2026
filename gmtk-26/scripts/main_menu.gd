class_name MainMenu
extends Control

@export var level_sequence: Resource
@export var menu_music: AudioStream
@export var button_hover_sound: AudioStream
@export var button_pressed_sound: AudioStream

var _loading := false

@onready var play_button: Button = %PlayButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var level_select_screen: Control = %LevelSelectScreen
@onready var settings_panel: SettingsPanel = %SettingsPanel
@onready var music_player: AudioStreamPlayer = %MenuMusic
@onready var ui_audio: AudioStreamPlayer = %UIAudio


func _ready() -> void:
	if level_sequence == null:
		level_sequence = load("res://Data/level_sequence.tres")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_button.pressed.connect(_play_game)
	level_select_button.pressed.connect(_open_level_select)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_quit_game)
	play_button.mouse_entered.connect(_play_hover)
	level_select_button.mouse_entered.connect(_play_hover)
	settings_button.mouse_entered.connect(_play_hover)
	quit_button.mouse_entered.connect(_play_hover)
	var has_levels: bool = level_sequence != null and not level_sequence.levels.is_empty()
	play_button.disabled = not has_levels
	level_select_button.disabled = not has_levels
	play_button.grab_focus()
	if menu_music != null:
		music_player.stream = menu_music
		music_player.finished.connect(music_player.play)
		music_player.play()


func _play_game() -> void:
	if _loading:
		return
	if level_sequence == null or level_sequence.levels.is_empty():
		push_warning("Cannot start game: LevelSequence has no levels configured.")
		return
	var first_level: PackedScene = level_sequence.levels[0]
	if first_level == null:
		push_warning("Cannot start game: the first LevelSequence entry is empty.")
		return
	_loading = true
	_disable_buttons()
	_play_sound(button_pressed_sound)
	var error := get_tree().change_scene_to_packed(first_level)
	if error != OK:
		_loading = false
		push_warning("Could not start game. Error: %s" % error_string(error))


func _open_level_select() -> void:
	if level_sequence == null:
		push_warning("Cannot open Level Select: no LevelSequence is assigned.")
		return
	level_select_screen.open(level_sequence)


func _open_settings() -> void:
	settings_panel.open()


func _quit_game() -> void:
	if _loading:
		return
	_loading = true
	_disable_buttons()
	_play_sound(button_pressed_sound)
	get_tree().quit()


func _play_hover() -> void:
	_play_sound(button_hover_sound)


func _disable_buttons() -> void:
	play_button.disabled = true
	level_select_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true


func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	ui_audio.stream = stream
	ui_audio.play()
