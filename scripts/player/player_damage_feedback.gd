class_name PlayerDamageFeedback
extends Node

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

const DAMAGE_FLASH := Color(1.0, 0.34, 0.22, 1.0)
const DAMAGE_FLASH_HIGH_CONTRAST := Color(1.6, 1.6, 1.6, 1.0)
const LEVEL_UP_COLOR := Color(1.0, 0.50, 0.16, 0.92)
const LEVEL_UP_COLOR_HIGH_CONTRAST := Color(1.0, 0.92, 0.68, 1.0)
const FULL_HEAL_COLOR := Color(0.98, 0.72, 0.30, 0.88)
const FULL_HEAL_COLOR_HIGH_CONTRAST := Color(1.0, 0.96, 0.76, 1.0)
const PASSIVE_ACTIVE_COLOR := Color(0.96, 0.14, 0.42, 0.90)
const PASSIVE_ACTIVE_COLOR_HIGH_CONTRAST := Color(1.0, 0.80, 0.34, 1.0)
const CAMERA_KICK := Vector2(5.0, -3.0)

var _player: Node
var _visual: CanvasItem
var _camera: Camera2D
var _last_hp: float = 0.0
var _last_level: int = 1
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
	if _player.has_signal("passive_activated"):
		_player.connect("passive_activated", _on_passive_activated)
	call_deferred("_initialize_from_player")

func _initialize_from_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_last_hp = maxf(float(_player.get("current_hp")), 0.0)
	_last_level = maxi(int(_player.get("current_level")), 1)
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
	elif current_hp > _last_hp + 0.001 and _is_at_full_health(current_hp):
		_play_full_heal_feedback()
	var current_level := maxi(int(_player.get("current_level")), 1)
	if current_level > _last_level:
		_play_level_up_feedback()
	_last_hp = current_hp
	_last_level = current_level

func _on_passive_activated() -> void:
	if not _initialized:
		return
	_play_passive_activation_feedback()

func _play_damage_feedback() -> void:
	SfxRuntimeRef.play(self, "player_hit", -8.0, 1.0, 120)
	_play_visual_flash()
	_play_camera_kick()
	_play_damage_burst()

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

func _play_damage_burst() -> void:
	var player_node := _player as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	var color := _resolve_damage_flash_color()
	var burst := Node2D.new()
	burst.name = "PlayerHitBurst"
	burst.z_index = 4
	burst.scale = Vector2.ONE * 0.72
	player_node.add_child(burst)

	var ring := Line2D.new()
	ring.points = _build_ring_points(24.0, 16)
	ring.closed = true
	ring.width = 2.6
	ring.default_color = color
	burst.add_child(ring)

	for slash_index in range(2):
		var slash_angle: float = -0.72 if slash_index == 0 else 0.72
		var slash := Line2D.new()
		var direction := Vector2.from_angle(slash_angle)
		slash.points = PackedVector2Array([
			direction * -18.0,
			direction * 20.0
		])
		slash.width = 2.2
		slash.default_color = Color(color, color.a * 0.78)
		burst.add_child(slash)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.10 if reduced_motion else 0.18
	var tween := burst.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(burst, "scale", Vector2.ONE * 1.36, duration)
	tween.tween_property(burst, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)

func _play_level_up_feedback() -> void:
	var player_node := _player as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	var color := (
		LEVEL_UP_COLOR_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else LEVEL_UP_COLOR
	)
	var burst := Node2D.new()
	burst.name = "LevelUpBurst"
	burst.z_index = -1
	burst.scale = Vector2.ONE * 0.62
	player_node.add_child(burst)

	var ring := Line2D.new()
	ring.points = _build_ring_points(34.0, 28)
	ring.closed = true
	ring.width = 3.0
	ring.default_color = color
	burst.add_child(ring)

	var diamond := Line2D.new()
	diamond.points = PackedVector2Array([
		Vector2(0.0, -28.0),
		Vector2(28.0, 0.0),
		Vector2(0.0, 28.0),
		Vector2(-28.0, 0.0),
		Vector2(0.0, -28.0)
	])
	diamond.width = 2.0
	diamond.default_color = Color(color, color.a * 0.72)
	burst.add_child(diamond)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.16 if reduced_motion else 0.30
	var tween := burst.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(burst, "scale", Vector2.ONE * 1.55, duration)
	tween.tween_property(burst, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)

func _play_full_heal_feedback() -> void:
	var player_node := _player as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	var color := (
		FULL_HEAL_COLOR_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else FULL_HEAL_COLOR
	)
	var burst := Node2D.new()
	burst.name = "FullHealBurst"
	burst.z_index = -1
	burst.scale = Vector2.ONE * 0.72
	player_node.add_child(burst)

	var ring := Line2D.new()
	ring.points = _build_ring_points(28.0, 24)
	ring.closed = true
	ring.width = 2.8
	ring.default_color = color
	burst.add_child(ring)

	var cross := Line2D.new()
	cross.points = PackedVector2Array([
		Vector2(-6.0, -16.0),
		Vector2(6.0, -16.0),
		Vector2(6.0, -6.0),
		Vector2(16.0, -6.0),
		Vector2(16.0, 6.0),
		Vector2(6.0, 6.0),
		Vector2(6.0, 16.0),
		Vector2(-6.0, 16.0),
		Vector2(-6.0, 6.0),
		Vector2(-16.0, 6.0),
		Vector2(-16.0, -6.0),
		Vector2(-6.0, -6.0),
		Vector2(-6.0, -16.0)
	])
	cross.width = 2.0
	cross.default_color = Color(color, color.a * 0.76)
	burst.add_child(cross)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.14 if reduced_motion else 0.26
	var tween := burst.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(burst, "scale", Vector2.ONE * 1.42, duration)
	tween.tween_property(burst, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)

func _play_passive_activation_feedback() -> void:
	var player_node := _player as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	var color := (
		PASSIVE_ACTIVE_COLOR_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else PASSIVE_ACTIVE_COLOR
	)
	var burst := Node2D.new()
	burst.name = "PassiveActivationBurst"
	burst.z_index = -1
	burst.scale = Vector2.ONE * 0.66
	player_node.add_child(burst)

	var ring := Line2D.new()
	ring.points = _build_ring_points(30.0, 20)
	ring.closed = true
	ring.width = 2.6
	ring.default_color = color
	burst.add_child(ring)

	for ray_index in range(4):
		var ray := Line2D.new()
		var angle: float = PI * 0.5 * float(ray_index)
		var direction := Vector2.from_angle(angle)
		ray.points = PackedVector2Array([direction * 22.0, direction * 38.0])
		ray.width = 2.2
		ray.default_color = Color(color, color.a * 0.72)
		burst.add_child(ray)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.12 if reduced_motion else 0.22
	var tween := burst.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(burst, "scale", Vector2.ONE * 1.34, duration)
	tween.tween_property(burst, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)

func _is_at_full_health(current_hp: float) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var stats_variant: Variant = _player.get("stats")
	if not (stats_variant is Object):
		return false
	var max_hp := maxf(float((stats_variant as Object).get("max_hp")), 0.0)
	return max_hp > 0.0 and is_equal_approx(current_hp, max_hp)

func _build_ring_points(radius: float, segment_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_segment_count := maxi(segment_count, 3)
	for index in range(safe_segment_count):
		var angle := TAU * float(index) / float(safe_segment_count)
		points.append(Vector2.from_angle(angle) * radius)
	return points

func _resolve_damage_flash_color() -> Color:
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		return DAMAGE_FLASH_HIGH_CONTRAST
	return DAMAGE_FLASH
