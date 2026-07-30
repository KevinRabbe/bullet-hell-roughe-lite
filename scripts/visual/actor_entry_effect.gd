class_name ActorEntryEffect
extends Node2D

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const NORMAL_DURATION: float = 0.72
const REDUCED_DURATION: float = 0.30
const SEGMENTS: int = 24

var _elapsed: float = 0.0
var _duration: float = NORMAL_DURATION
var _high_contrast: bool = false

func _ready() -> void:
	z_index = -7
	position.y = 10.0
	_high_contrast = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		_duration = REDUCED_DURATION
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress := clampf(_elapsed / maxf(_duration, 0.01), 0.0, 1.0)
	var reveal := minf(progress / 0.22, 1.0)
	var fade := 1.0 - smoothstep(0.48, 1.0, progress)
	var alpha := reveal * fade
	var radius := lerpf(18.0, 48.0, smoothstep(0.0, 1.0, progress))
	var primary := Color("#FF4F3B") if _high_contrast else Color("#D92E45")
	var secondary := Color("#FFD08A") if _high_contrast else Color("#C86A2A")
	primary.a = alpha * 0.82
	secondary.a = alpha * 0.58
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, SEGMENTS, primary, 2.4, true)
	draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, SEGMENTS, secondary, 1.4, true)
	_draw_ritual_marks(radius, primary, alpha)

func _draw_ritual_marks(radius: float, color: Color, alpha: float) -> void:
	var mark_color := color
	mark_color.a = alpha * 0.72
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var direction := Vector2.from_angle(angle)
		var tangent := direction.rotated(PI * 0.5)
		var inner := direction * (radius * 0.72)
		var outer := direction * (radius * 1.12)
		draw_line(inner, outer, mark_color, 1.8, true)
		draw_line(outer - tangent * 3.0, outer + tangent * 3.0, mark_color, 1.2, true)
