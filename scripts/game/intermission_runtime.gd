class_name IntermissionRuntime
extends RefCounted

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

static func begin_intermission(owner: Node, wave_panel: Control, level_up_panel: Control, shop_enabled: bool) -> void:
	if owner == null:
		return
	if owner.has_method("_set_combat_active"):
		owner.call("_set_combat_active", false)
	if owner.has_method("_clear_combat_entities"):
		owner.call("_clear_combat_entities")
	if shop_enabled:
		if wave_panel != null:
			wave_panel.visible = false
		if level_up_panel != null:
			level_up_panel.visible = false
	else:
		if owner.has_method("_hide_run_overlays"):
			owner.call("_hide_run_overlays")
	if not shop_enabled and wave_panel != null:
		_prepare_fallback_intermission(wave_panel)
		wave_panel.visible = true
		var continue_button := wave_panel.get_node_or_null("ContinueButton") as Button
		if continue_button != null and not continue_button.disabled:
			continue_button.grab_focus()

static func end_intermission(owner: Node) -> void:
	if owner == null:
		return
	if owner.has_method("_hide_run_overlays"):
		owner.call("_hide_run_overlays")

static func start_next_wave(owner: Node, enemy_spawner: Node) -> void:
	if owner != null:
		if owner.has_method("_heal_player_to_full"):
			owner.call("_heal_player_to_full")
		if owner.has_method("_set_combat_active"):
			owner.call("_set_combat_active", true)
	if enemy_spawner != null and enemy_spawner.has_method("start_next_wave"):
		enemy_spawner.call("start_next_wave")

static func _prepare_fallback_intermission(wave_panel: Control) -> void:
	var viewport_size := wave_panel.get_viewport_rect().size
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(viewport_size)
	var tight := layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var panel_width := 440.0 if tight else 520.0
	var panel_height := 190.0 if tight else 210.0
	wave_panel.set_anchors_preset(Control.PRESET_CENTER)
	wave_panel.offset_left = -panel_width * 0.5
	wave_panel.offset_top = -panel_height * 0.5
	wave_panel.offset_right = panel_width * 0.5
	wave_panel.offset_bottom = panel_height * 0.5
	InfernalUiStyleRef.apply_panel(wave_panel, InfernalUiStyleRef.PANEL_MODAL)

	var label := wave_panel.get_node_or_null("Label") as Label
	if label != null:
		label.text = "WAVE COMPLETE\nCatch your breath. The next push is ready."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.offset_left = UiLayoutMetricsRef.shell_padding(layout_class)
		label.offset_top = 20.0
		label.offset_right = panel_width - UiLayoutMetricsRef.shell_padding(layout_class)
		label.offset_bottom = 110.0 if tight else 124.0
		label.add_theme_font_size_override("font_size", 17 if tight else 19)
		InfernalUiStyleRef.apply_text_role(label, InfernalUiStyleRef.TEXT_BODY)

	var continue_button := wave_panel.get_node_or_null("ContinueButton") as Button
	if continue_button != null:
		var button_width := 180.0 if tight else 220.0
		var button_height := float(UiLayoutMetricsRef.primary_button_height(layout_class))
		continue_button.text = "NEXT WAVE"
		continue_button.offset_left = (panel_width - button_width) * 0.5
		continue_button.offset_top = panel_height - button_height - 20.0
		continue_button.offset_right = continue_button.offset_left + button_width
		continue_button.offset_bottom = continue_button.offset_top + button_height
		InfernalUiStyleRef.apply_button(continue_button, InfernalUiStyleRef.BUTTON_PRIMARY)
