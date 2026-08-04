class_name EventBannerRuntime
extends RefCounted

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const InfernalRitualBackdropRef = preload("res://scripts/ui/components/infernal_ritual_backdrop.gd")

const DEFAULT_SECONDS := 1.65
const PANEL_WIDTH := 560.0
const PANEL_TOP := 84.0
const PANEL_HEIGHT := 126.0
const LARGE_TEXT_PANEL_HEIGHT := 150.0

static func show(
	owner: Node,
	eyebrow_text: String,
	title_text: String,
	body_text: String,
	duration_seconds: float = DEFAULT_SECONDS
) -> void:
	if owner == null or not is_instance_valid(owner) or owner.get_tree() == null:
		return
	var scene := owner.get_tree().current_scene
	if scene == null:
		return

	var accessibility_settings := AccessibilitySettingsRuntimeRef.get_active_settings()
	var font_scale := AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	var large_text := AccessibilitySettingsRuntimeRef.is_large_text_enabled(accessibility_settings)
	var high_contrast := AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	var viewport_width := scene.get_viewport().get_visible_rect().size.x
	var target_width := PANEL_WIDTH * (1.08 if large_text else 1.0)
	var panel_width := minf(target_width, maxf(viewport_width - 32.0, 320.0))
	var panel_height := LARGE_TEXT_PANEL_HEIGHT if large_text else PANEL_HEIGHT

	var layer := CanvasLayer.new()
	layer.layer = 42
	layer.name = "EventBanner"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	scene.add_child(layer)

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	InfernalUiStyleRef.apply_panel(panel, InfernalUiStyleRef.PANEL_MODAL)
	root.add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -panel_width * 0.5
	panel.offset_right = panel_width * 0.5
	panel.offset_top = PANEL_TOP
	panel.offset_bottom = PANEL_TOP + panel_height

	var ritual_backdrop := InfernalRitualBackdropRef.new() as Control
	ritual_backdrop.name = "RitualBackdrop"
	panel.add_child(ritual_backdrop)
	ritual_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	margin.add_child(content)

	var eyebrow := Label.new()
	eyebrow.text = eyebrow_text
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", int(round(12.0 * font_scale)))
	InfernalUiStyleRef.apply_text_role(eyebrow, InfernalUiStyleRef.TEXT_WARNING)
	if high_contrast:
		eyebrow.add_theme_color_override("font_color", Color(1.0, 0.82, 0.38, 1.0))
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(round(28.0 * font_scale)))
	InfernalUiStyleRef.apply_text_role(title, InfernalUiStyleRef.TEXT_DISPLAY_TITLE)
	if high_contrast:
		title.add_theme_color_override("font_color", Color.WHITE)
	content.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", int(round(13.0 * font_scale)))
	InfernalUiStyleRef.apply_text_role(body, InfernalUiStyleRef.TEXT_BODY)
	if high_contrast:
		body.add_theme_color_override("font_color", Color.WHITE)
	content.add_child(body)

	_play_lifetime(layer, panel, maxf(duration_seconds, 0.5))

static func _play_lifetime(layer: CanvasLayer, panel: PanelContainer, duration_seconds: float) -> void:
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		var timer := layer.get_tree().create_timer(duration_seconds)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(layer):
				layer.queue_free()
		)
		return

	var rest_position := panel.position
	panel.position.y -= 10.0
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position", rest_position, 0.16)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.14)
	tween.tween_interval(maxf(duration_seconds - 0.30, 0.20))
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.14)
	tween.finished.connect(func() -> void:
		if is_instance_valid(layer):
			layer.queue_free()
	)
