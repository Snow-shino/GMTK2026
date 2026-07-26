class_name PauseMenu
extends CanvasLayer

signal restart_requested
signal main_menu_requested

@onready var menu_panel: Control = %MenuPanel
@onready var settings_panel: SettingsPanel = %SettingsPanel
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton

var _open := false
var _paused_music_players: Array[Node] = []
var _music_pause_states: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	resume_button.pressed.connect(close_pause)
	restart_button.pressed.connect(_request_restart)
	settings_button.pressed.connect(_open_settings)
	main_menu_button.pressed.connect(_request_main_menu)
	settings_panel.closed.connect(_close_settings)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _open and settings_panel.visible:
			settings_panel.close()
		elif _open:
			close_pause()
		else:
			open_pause()
	elif _open and event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		_request_restart()


func open_pause() -> void:
	if _open:
		return
	_open = true
	show()
	menu_panel.show()
	settings_panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pause_music_players()
	get_tree().paused = true
	resume_button.grab_focus()


func close_pause() -> void:
	if not _open:
		return
	_open = false
	get_tree().paused = false
	_resume_music_players()
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_settings() -> void:
	menu_panel.hide()
	settings_panel.open()


func _close_settings() -> void:
	if not _open:
		return
	menu_panel.show()
	settings_button.grab_focus()


func _pause_music_players() -> void:
	_paused_music_players.clear()
	_music_pause_states.clear()
	_collect_music_players(get_tree().current_scene)
	for player_node in _paused_music_players:
		_music_pause_states[player_node.get_instance_id()] = player_node.stream_paused
		player_node.stream_paused = true


func _resume_music_players() -> void:
	for player_node in _paused_music_players:
		if not is_instance_valid(player_node):
			continue
		var was_paused: bool = bool(_music_pause_states.get(player_node.get_instance_id(), false))
		player_node.stream_paused = was_paused
	_paused_music_players.clear()
	_music_pause_states.clear()


func _collect_music_players(node: Node) -> void:
	if node == null:
		return
	if (
		node is AudioStreamPlayer
		or node is AudioStreamPlayer2D
		or node is AudioStreamPlayer3D
	):
		if node.bus == &"Music":
			_paused_music_players.append(node)
	for child in node.get_children():
		_collect_music_players(child)


func _request_restart() -> void:
	close_pause()
	restart_requested.emit()


func _request_main_menu() -> void:
	close_pause()
	main_menu_requested.emit()
