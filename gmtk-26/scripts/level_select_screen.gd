class_name LevelSelectScreen
extends Control

@export var button_hover_sound: AudioStream
@export var button_pressed_sound: AudioStream

var _sequence: Resource
var _loading := false

@onready var level_list: VBoxContainer = %LevelList
@onready var back_button: Button = %BackButton
@onready var ui_audio: AudioStreamPlayer = %UIAudio


func _ready() -> void:
	hide()
	back_button.pressed.connect(hide)
	back_button.mouse_entered.connect(_play_hover)


func open(sequence: Resource) -> void:
	_sequence = sequence
	_loading = false
	_rebuild_level_list()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	back_button.grab_focus()


func _rebuild_level_list() -> void:
	for child in level_list.get_children():
		child.queue_free()
	if _sequence == null or _sequence.levels.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No levels configured"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_list.add_child(empty_label)
		return
	for index in _sequence.levels.size():
		var level: PackedScene = _sequence.levels[index]
		var button := Button.new()
		button.custom_minimum_size.y = 46.0
		button.text = _get_level_label(level, index)
		button.disabled = level == null or not LevelProgress.is_unlocked(_sequence, index)
		button.mouse_entered.connect(_play_hover)
		button.pressed.connect(_load_level.bind(level))
		level_list.add_child(button)


func _get_level_label(level: PackedScene, index: int) -> String:
	if level == null:
		return "Level %d — Missing Scene" % (index + 1)
	var scene_name := level.resource_path.get_file().get_basename().capitalize()
	return "Level %d — %s" % [index + 1, scene_name]


func _load_level(level: PackedScene) -> void:
	if _loading or level == null:
		return
	_loading = true
	_play_sound(button_pressed_sound)
	var error := get_tree().change_scene_to_packed(level)
	if error != OK:
		_loading = false
		push_warning("Could not load selected level. Error: %s" % error_string(error))


func _play_hover() -> void:
	_play_sound(button_hover_sound)


func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	ui_audio.stream = stream
	ui_audio.play()
