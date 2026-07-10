class_name MenuAnimationRuntime
extends RefCounted

static func play_screen_intro(panels: Array[Control]) -> void:
	for index in range(panels.size()):
		var panel := panels[index]
		if panel == null or not is_instance_valid(panel):
			continue
		panel.modulate.a = 0.0
		panel.position.y += 18.0
		var tween := panel.create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_interval(float(index) * 0.04)
		tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.24)
		tween.parallel().tween_property(panel, "position:y", panel.position.y - 18.0, 0.28)

static func pulse_focus(control: Control, scale_amount: float = 1.02) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(scale_amount, scale_amount), 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.12)

static func fade_swap_texture(target: CanvasItem) -> void:
	if target == null or not is_instance_valid(target):
		return
	target.modulate.a = 0.0
	var tween := target.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate:a", 1.0, 0.18)

static func animate_modal_open(scrim: CanvasItem, panel: Control) -> void:
	if scrim != null and is_instance_valid(scrim):
		scrim.modulate.a = 0.0
		var scrim_tween := scrim.create_tween()
		scrim_tween.tween_property(scrim, "modulate:a", 1.0, 0.18)
	if panel != null and is_instance_valid(panel):
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.98, 0.98)
		panel.pivot_offset = panel.size * 0.5
		var panel_tween := panel.create_tween()
		panel_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		panel_tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.18)
		panel_tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2)

static func animate_modal_close(scrim: CanvasItem, panel: Control) -> void:
	if scrim != null and is_instance_valid(scrim):
		var scrim_tween := scrim.create_tween()
		scrim_tween.tween_property(scrim, "modulate:a", 0.0, 0.12)
	if panel != null and is_instance_valid(panel):
		var panel_tween := panel.create_tween()
		panel_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		panel_tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.12)
		panel_tween.parallel().tween_property(panel, "scale", Vector2(0.985, 0.985), 0.12)
