class_name SettingsPanel
extends Control

signal closed
signal volume_changed

const SETTINGS_PATH := "user://audio_settings.cfg"
const SECTION := "audio"
const BUS_NAMES := [&"Master", &"Music", &"SFX", &"UI"]

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue
@onready var ui_value: Label = %UIValue
@onready var close_button: Button = %CloseButton

var _loading_values := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	master_slider.value_changed.connect(_on_slider_changed.bind(0))
	music_slider.value_changed.connect(_on_slider_changed.bind(1))
	sfx_slider.value_changed.connect(_on_slider_changed.bind(2))
	ui_slider.value_changed.connect(_on_slider_changed.bind(3))
	close_button.pressed.connect(close)
	_load_settings()


func open() -> void:
	show()
	master_slider.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _load_settings() -> void:
	_loading_values = true
	var config := ConfigFile.new()
	var has_saved_settings := config.load(SETTINGS_PATH) == OK
	var sliders := [master_slider, music_slider, sfx_slider, ui_slider]

	for index in BUS_NAMES.size():
		var bus_index := AudioServer.get_bus_index(BUS_NAMES[index])
		if bus_index < 0:
			continue
		var current_percent := _db_to_percent(AudioServer.get_bus_volume_db(bus_index))
		var saved_percent: float = float(config.get_value(
			SECTION,
			String(BUS_NAMES[index]),
			current_percent
		)) if has_saved_settings else current_percent
		sliders[index].value = clampf(saved_percent, 0.0, 100.0)
		_apply_bus_volume(index, sliders[index].value)

	_loading_values = false
	_update_labels()


func _on_slider_changed(value: float, bus_slot: int) -> void:
	_apply_bus_volume(bus_slot, value)
	_update_labels()
	volume_changed.emit()
	if not _loading_values:
		_save_settings()


func _apply_bus_volume(bus_slot: int, percent: float) -> void:
	if bus_slot < 0 or bus_slot >= BUS_NAMES.size():
		return
	var bus_index := AudioServer.get_bus_index(BUS_NAMES[bus_slot])
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, _percent_to_db(percent))
	AudioServer.set_bus_mute(bus_index, percent <= 0.0)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "Master", master_slider.value)
	config.set_value(SECTION, "Music", music_slider.value)
	config.set_value(SECTION, "SFX", sfx_slider.value)
	config.set_value(SECTION, "UI", ui_slider.value)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save audio settings: %s" % error_string(error))


func _update_labels() -> void:
	master_value.text = "%d%%" % roundi(master_slider.value)
	music_value.text = "%d%%" % roundi(music_slider.value)
	sfx_value.text = "%d%%" % roundi(sfx_slider.value)
	ui_value.text = "%d%%" % roundi(ui_slider.value)


func _percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0
	return linear_to_db(percent / 100.0)


func _db_to_percent(db: float) -> float:
	if db <= -80.0:
		return 0.0
	return db_to_linear(db) * 100.0
