class_name AreaMusicRegion
extends Area3D

@export var area_music: AudioStream
@export_range(0.0, 10.0, 0.1) var fade_in_duration := 1.0
@export_range(0.0, 10.0, 0.1) var fade_out_duration := 1.0
@export_range(-80.0, 6.0, 0.1) var volume_db := -8.0
@export var restore_previous_music_on_exit := true
@export var one_shot := false
@export_node_path("AudioStreamPlayer") var music_player_path: NodePath

var _used := false
var _inside := false
var _previous_stream: AudioStream
var _previous_volume_db := 0.0
var _fade: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or area_music == null or (one_shot and _used):
		return
	var player := get_node_or_null(music_player_path) as AudioStreamPlayer
	if player == null:
		return
	_inside = true
	_used = true
	_previous_stream = player.stream
	_previous_volume_db = player.volume_db
	_fade_to_stream(player, area_music, volume_db, fade_in_duration)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player") or not _inside:
		return
	_inside = false
	if not restore_previous_music_on_exit:
		return
	var player := get_node_or_null(music_player_path) as AudioStreamPlayer
	if player != null:
		_fade_to_stream(player, _previous_stream, _previous_volume_db, fade_out_duration)


func _fade_to_stream(
	player: AudioStreamPlayer,
	stream: AudioStream,
	target_volume: float,
	duration: float
) -> void:
	if _fade != null:
		_fade.kill()
	if duration <= 0.0:
		player.stream = stream
		player.volume_db = target_volume
		if stream != null:
			player.play()
		return
	_fade = create_tween()
	_fade.tween_property(player, "volume_db", -60.0, duration * 0.5)
	_fade.tween_callback(func() -> void:
		player.stream = stream
		player.volume_db = -60.0
		if stream != null:
			player.play()
	)
	_fade.tween_property(player, "volume_db", target_volume, duration * 0.5)
