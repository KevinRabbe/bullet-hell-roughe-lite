class_name ActorGroundShadow
extends Node2D

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

@export var visual_path: NodePath = NodePath("../Visual")

var _outer_points := PackedVector2Array()
var _inner_points := PackedVector2Array()

func _ready() -> void:
	z_index = -9
	call_deferred("_refresh_from_visual")

func _draw() -> void:
	if _outer_points.is_empty():
		return
	var high_contrast := AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
	var outer_alpha := 0.34 if high_contrast else 0.22
	var inner_alpha := 0.46 if high_contrast else 0.30
	draw_colored_polygon(_outer_points, Color(0.015, 0.0, 0.02, outer_alpha))
	draw_colored_polygon(_inner_points, Color(0.01, 0.0, 0.015, inner_alpha))

func _refresh_from_visual() -> void:
	var visual := get_node_or_null(visual_path) as Sprite2D
	if visual == null or visual.texture == null:
		return
	var texture_size := visual.texture.get_size()
	var rendered_width := texture_size.x * absf(visual.scale.x)
	var rendered_height := texture_size.y * absf(visual.scale.y)
	var shadow_width := clampf(rendered_width * 0.44, 24.0, 96.0)
	var shadow_height := clampf(shadow_width * 0.28, 7.0, 24.0)
	position.y = clampf(rendered_height * 0.34, 10.0, 44.0)
	_outer_points = _build_ellipse_points(Vector2(shadow_width, shadow_height), 20)
	_inner_points = _build_ellipse_points(Vector2(shadow_width * 0.72, shadow_height * 0.62), 18)
	queue_redraw()

func _build_ellipse_points(size: Vector2, segment_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius := size * 0.5
	for index in range(maxi(segment_count, 8)):
		var angle := TAU * float(index) / float(maxi(segment_count, 8))
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points
