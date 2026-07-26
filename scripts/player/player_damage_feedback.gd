class_name PlayerDamageFeedback
extends Node

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

const DAMAGE_FLASH := Color(1.0, 0.34, 0.22, 1.0)
const DAMAGE_FLASH_HIGH_CONTRAST := Color(1.6, 1.6, 1.6, 1.0)
const CAMERA_KICK := Vector2(5.0, -3.0)

var _player: Node
var _visual: CanvasItem
var _camera: Camera2D
var _last_hp: float = 0.0
var _initialized: bool = false
var _base_visual_modulate: Color = Color.WHITE
var _base_camera_offset: Vector2 = Vector2.ZERO
var _flash_tween: Tween
var _camera_tween: Tween

func _ready() -> void:
	_player = get_parent()
	if _player == null:
		return
	_visual = _player.get_node_or_null("Visual") as CanvasItem
	_camera = _player.get_node_or_null("Camera2D") as Camera2D
	if _player.has_signal("ui_snapshot_changed"):
		_player.connect("ui_snapshot_changed", _on_player_snapshot_changed)
	call_deferred("_initialize_from_player")

func _initialize_from_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_last_hp = maxf(float(_player.get("current_hp")), 0.0)
	if _visual != null and is_instance_valid(_visual):
		_base_visual_modulate = _visual.modulate
	if _camera != null and is_instance_valid(_camera):
		_base_camera_offset = _camera.offset
	_initialized = true

func _on_player_snapshot_changed() -> void:
	if not _initialized or _player == null or not is_instance_valid(_player):
		return
	var current_hp := maxf(float(_player.get("current_hp")), 0.0)
	if current_hp < _last_hp - 0.001:
		_play_damage_feedback()
	_last_hp = current_hp

func _play_damage_feedback() -> void:
	SfxRuntimeRef.play(self, "player_hit", -8.0, 1.0, 120)
	_play_visual_flash()
	_play_camera_kick()

func _play_visual_flash() -> void:
	if _visual == null or not is_instance_valid(_visual):
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_visual.modulate = _resolve_damage_flash_color()
	_flash_tween = _visual.create_tween()
	_flash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(_visual, "modulate", _base_visual_modulate, 0.12)

func _play_camera_kick() -> void:
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		return
	if _camera == null or not is_instance_valid(_camera):
		return
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera.offset = _base_camera_offset + CAMERA_KICK
	_camera_tween = _camera.create_tween()
	_camera_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "offset", _base_camera_offset, 0.10)

func _resolve_damage_flash_color() -> Color:
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		return DAMAGE_FLASH_HIGH_CONTRAST
	return DAMAGE_FLASH
