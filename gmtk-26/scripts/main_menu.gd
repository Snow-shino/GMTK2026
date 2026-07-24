class_name MainMenu
extends Control

@export_file("*.tscn") var first_level_path := "res://main.tscn"
@export var menu_music: AudioStream
@export var button_hover_sound: AudioStream
@export var button_pressed_sound: AudioStream

var _loading := false

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton
@onready var music_player: AudioStreamPlayer = %MenuMusic
@onready var ui_audio: AudioStreamPlayer = %UIAudio


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_button.pressed.connect(_play_game)
	quit_button.pressed.connect(_quit_game)
	play_button.mouse_entered.connect(_play_hover)
	quit_button.mouse_entered.connect(_play_hover)
	play_button.grab_focus()
	if menu_music != null:
		music_player.stream = menu_music
		music_player.finished.connect(music_player.play)
		music_player.play()


func _play_game() -> void:
	if _loading:
		return
	if first_level_path.is_empty() or not ResourceLoader.exists(first_level_path, "PackedScene"):
		push_warning("Cannot start game: invalid scene path '%s'." % first_level_path)
		return
	_loading = true
	_disable_buttons()
	_play_sound(button_pressed_sound)
	get_tree().change_scene_to_file(first_level_path)


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
	quit_button.disabled = true


func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	ui_audio.stream = stream
	ui_audio.play()
