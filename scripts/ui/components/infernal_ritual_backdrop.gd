extends Control

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const COLOR_CRIMSON := Color(0.62, 0.11, 0.18, 0.13)
const COLOR_ORANGE := Color(0.94, 0.42, 0.10, 0.16)
const COLOR_BONE := Color(0.91, 0.84, 0.69, 0.12)
const RUNE_COUNT := 8

var _elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	visibility_changed.connect(_sync_process_state)
	_sync_process_state()
	queue_redraw()

func _sync_process_state() -> void:
	set_process(is_visible_in_tree() and not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled())
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed = fmod(_elapsed + delta, TAU * 8.0)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var high_contrast := AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var center := Vector2(size.x * 0.5, size.y * 0.53)
	var base_radius := minf(size.y * 0.34, size.x * 0.18)
	var pulse := 0.0 if reduced_motion else sin(_elapsed * 1.6) * 2.0
	var rotation := 0.0 if reduced_motion else _elapsed * 0.08
	var crimson := COLOR_CRIMSON
	var orange := COLOR_ORANGE
	var bone := COLOR_BONE
	if high_contrast:
		crimson.a = 0.18
		orange.a = 0.22
		bone.a = 0.18

	_draw_edge_accents(orange, bone)
	draw_arc(center, base_radius + pulse, rotation, rotation + TAU, 48, crimson, 2.0, true)
	draw_arc(center, base_radius * 0.72, -rotation, -rotation + TAU, 40, orange, 1.0, true)
	draw_arc(center, base_radius * 0.43, rotation * 1.4, rotation * 1.4 + TAU, 32, bone, 1.0, true)

	for index in RUNE_COUNT:
		var angle := rotation + (TAU * float(index) / float(RUNE_COUNT))
		var inner := center + Vector2.from_angle(angle) * (base_radius * 0.48)
		var outer := center + Vector2.from_angle(angle) * (base_radius * 0.92)
		draw_line(inner, outer, crimson, 1.0, true)
		_draw_diamond(outer, 3.0 if index % 2 == 0 else 2.0, orange)

func _draw_edge_accents(orange: Color, bone: Color) -> void:
	var center_x := size.x * 0.5
	var gap := minf(size.x * 0.16, 150.0)
	var edge := 22.0
	draw_line(Vector2(edge, 10.0), Vector2(center_x - gap, 10.0), orange, 1.0, true)
	draw_line(Vector2(center_x + gap, 10.0), Vector2(size.x - edge, 10.0), orange, 1.0, true)
	draw_line(Vector2(edge, size.y - 10.0), Vector2(center_x - gap, size.y - 10.0), bone, 1.0, true)
	draw_line(Vector2(center_x + gap, size.y - 10.0), Vector2(size.x - edge, size.y - 10.0), bone, 1.0, true)
	_draw_diamond(Vector2(center_x, 10.0), 4.0, orange)
	_draw_diamond(Vector2(center_x, size.y - 10.0), 3.0, bone)

func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
		center + Vector2(0.0, -radius),
	])
	draw_polyline(points, color, 1.0, true)
