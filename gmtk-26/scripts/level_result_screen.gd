class_name LevelResultScreen
extends CanvasLayer

signal restart_requested

@export var completion_screen_open_sound: AudioStream
@export var failure_screen_open_sound: AudioStream
@export var button_hover_sound: AudioStream
@export var button_pressed_sound: AudioStream

var _next_level: PackedScene
var _main_menu: PackedScene
var _navigating := false

@onready var title_label: Label = %TitleLabel
@onready var life_label: Label = %LifeLabel
@onready var restart_button: Button = %RestartButton
@onready var next_button: Button = %NextButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var settings_panel: SettingsPanel = %SettingsPanel
@onready var ui_audio: AudioStreamPlayer = %UIAudio


func _ready() -> void:
	hide()
	restart_button.pressed.connect(_restart_level)
	next_button.pressed.connect(_load_next_level)
	settings_button.pressed.connect(_open_settings)
	main_menu_button.pressed.connect(_load_main_menu)
	for button in [restart_button, next_button, settings_button, main_menu_button]:
		button.mouse_entered.connect(_play_hover)


func show_completion(
	remaining_life: float,
	next_level: PackedScene,
	main_menu: PackedScene
) -> void:
	_next_level = next_level
	_main_menu = main_menu
	title_label.text = "LEVEL COMPLETE"
	life_label.text = "Life Essence Remaining: %.1f" % remaining_life
	life_label.show()
	next_button.visible = _next_level != null
	main_menu_button.disabled = _main_menu == null
	_show_screen(completion_screen_open_sound)


func show_failure(main_menu: PackedScene) -> void:
	_next_level = null
	_main_menu = main_menu
	title_label.text = "LIGHT EXTINGUISHED"
	life_label.hide()
	next_button.hide()
	main_menu_button.disabled = _main_menu == null
	_show_screen(failure_screen_open_sound)


func _show_screen(open_sound: AudioStream) -> void:
	_navigating = false
	settings_panel.hide()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	restart_button.grab_focus()
	_play_sound(open_sound)


func _restart_level() -> void:
	if _begin_navigation():
		restart_requested.emit()


func reset_screen() -> void:
	_navigating = false
	restart_button.disabled = false
	next_button.disabled = false
	settings_button.disabled = false
	main_menu_button.disabled = _main_menu == null
	settings_panel.hide()
	hide()


func _load_next_level() -> void:
	_change_scene(_next_level, "next level")


func _load_main_menu() -> void:
	_change_scene(_main_menu, "main menu")


func _open_settings() -> void:
	settings_panel.open()


func _change_scene(scene: PackedScene, label: String) -> void:
	if scene == null:
		push_warning("Cannot load %s: no PackedScene is assigned." % label)
		return
	if _begin_navigation():
		var error := get_tree().change_scene_to_packed(scene)
		if error != OK:
			_navigating = false
			push_warning("Could not load %s. Error: %s" % [label, error_string(error)])


func _begin_navigation() -> bool:
	if _navigating:
		return false
	_navigating = true
	restart_button.disabled = true
	next_button.disabled = true
	settings_button.disabled = true
	main_menu_button.disabled = true
	_play_sound(button_pressed_sound)
	return true


func _play_hover() -> void:
	_play_sound(button_hover_sound)


func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	ui_audio.stream = stream
	ui_audio.play()
