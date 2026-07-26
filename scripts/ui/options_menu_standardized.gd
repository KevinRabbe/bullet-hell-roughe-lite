extends "res://scripts/ui/options_menu.gd"

const StandardInfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const StandardUiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

func _apply_tab_button_style(button: Button, is_selected: bool) -> void:
	if button == null:
		return
	StandardInfernalUiStyleRef.apply_button(
		button,
		StandardInfernalUiStyleRef.BUTTON_PRIMARY if is_selected else StandardInfernalUiStyleRef.BUTTON_TAB
	)

func _apply_shared_frame_styles() -> void:
	StandardInfernalUiStyleRef.apply_panel(step_chip, StandardInfernalUiStyleRef.PANEL_CARD)
	StandardInfernalUiStyleRef.apply_panel(nav_panel, StandardInfernalUiStyleRef.PANEL_SHELL)
	StandardInfernalUiStyleRef.apply_panel(content_panel, StandardInfernalUiStyleRef.PANEL_SHELL)
	for panel_variant in find_children("*", "PanelContainer", true, false):
		if not (panel_variant is PanelContainer):
			continue
		var target := panel_variant as PanelContainer
		if target in [step_chip, nav_panel, content_panel]:
			continue
		StandardInfernalUiStyleRef.apply_panel(target, StandardInfernalUiStyleRef.PANEL_SECTION)
	for label_variant in find_children("*", "Label", true, false):
		if label_variant is Label:
			StandardInfernalUiStyleRef.apply_text_role(label_variant as Label, StandardInfernalUiStyleRef.TEXT_BODY)
	StandardInfernalUiStyleRef.apply_text_role(step_chip.get_node_or_null("StepChipMargin/StepChipLabel") as Label, StandardInfernalUiStyleRef.TEXT_SECTION_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(header_copy_label, StandardInfernalUiStyleRef.TEXT_MUTED)
	StandardInfernalUiStyleRef.apply_text_role(nav_title_label, StandardInfernalUiStyleRef.TEXT_SCREEN_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(nav_body_label, StandardInfernalUiStyleRef.TEXT_BODY)
	StandardInfernalUiStyleRef.apply_text_role(hint_label, StandardInfernalUiStyleRef.TEXT_HINT)
	StandardInfernalUiStyleRef.apply_text_role(tab_title_label, StandardInfernalUiStyleRef.TEXT_SCREEN_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(tab_summary_label, StandardInfernalUiStyleRef.TEXT_MUTED)
	for title_name in ["ResolutionTitle", "FullscreenTitle", "PlaceholderTitle", "FocusTitle", "ChecklistTitle"]:
		StandardInfernalUiStyleRef.apply_text_role(find_child(title_name, true, false) as Label, StandardInfernalUiStyleRef.TEXT_SECTION_TITLE)
	for value_label in [resolution_value_label, fullscreen_value_label, placeholder_status_label]:
		StandardInfernalUiStyleRef.apply_text_role(value_label, StandardInfernalUiStyleRef.TEXT_VALUE)
	for button_variant in find_children("*", "Button", true, false):
		if button_variant is Button:
			StandardInfernalUiStyleRef.apply_button(button_variant as Button, StandardInfernalUiStyleRef.BUTTON_SECONDARY)
	for tab_button in [tab_audio_button, tab_video_button, tab_controls_button, tab_accessibility_button]:
		_apply_tab_button_style(tab_button, tab_button == _button_for_tab(current_tab))
	StandardInfernalUiStyleRef.apply_button(apply_button, StandardInfernalUiStyleRef.BUTTON_PRIMARY)
	StandardInfernalUiStyleRef.apply_button(reset_button, StandardInfernalUiStyleRef.BUTTON_SECONDARY)
	StandardInfernalUiStyleRef.apply_button(back_button, StandardInfernalUiStyleRef.BUTTON_SECONDARY)

func _apply_responsive_layout() -> void:
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(staged_accessibility_settings)
	var large_text: bool = AccessibilitySettingsRuntimeRef.is_large_text_enabled(staged_accessibility_settings)
	var viewport_size: Vector2 = get_viewport_rect().size
	var layout_class: int = StandardUiLayoutMetricsRef.layout_class_for_size(viewport_size)
	var tight: bool = layout_class == StandardUiLayoutMetricsRef.LayoutClass.TIGHT
	var compact: bool = layout_class == StandardUiLayoutMetricsRef.LayoutClass.COMPACT
	var dense_tight: bool = tight and (viewport_size.y < 700.0 or viewport_size.x < 1180.0)
	if root_margin != null:
		var horizontal_margin := StandardUiLayoutMetricsRef.screen_margin_horizontal(layout_class)
		var vertical_margin := StandardUiLayoutMetricsRef.screen_margin_vertical(layout_class)
		root_margin.offset_left = horizontal_margin
		root_margin.offset_top = vertical_margin
		root_margin.offset_right = -horizontal_margin
		root_margin.offset_bottom = -vertical_margin
	if root_vbox != null:
		root_vbox.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class) + (2 if dense_tight else 8))
	if header_row != null:
		header_row.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class))
	if header_copy_label != null:
		header_copy_label.visible = not dense_tight
	if main_hbox != null:
		main_hbox.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class) if tight else StandardUiLayoutMetricsRef.row_gap(layout_class) + 6)
	if nav_panel != null:
		nav_panel.custom_minimum_size = Vector2(180 if dense_tight else (220 if tight else (260 if compact else 320)), 0)
	if content_panel != null:
		content_panel.custom_minimum_size = Vector2.ZERO
	if nav_margin != null:
		var nav_pad := StandardUiLayoutMetricsRef.section_padding(layout_class)
		nav_margin.add_theme_constant_override("margin_left", nav_pad)
		nav_margin.add_theme_constant_override("margin_top", nav_pad)
		nav_margin.add_theme_constant_override("margin_right", nav_pad)
		nav_margin.add_theme_constant_override("margin_bottom", nav_pad)
	if nav_vbox != null:
		nav_vbox.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class))
	if content_margin != null:
		var content_pad := StandardUiLayoutMetricsRef.shell_padding(layout_class)
		content_margin.add_theme_constant_override("margin_left", content_pad)
		content_margin.add_theme_constant_override("margin_top", content_pad)
		content_margin.add_theme_constant_override("margin_right", content_pad)
		content_margin.add_theme_constant_override("margin_bottom", content_pad)
	if content_vbox != null:
		content_vbox.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class) + 4)
	if content_shell != null:
		content_shell.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class) + 2)
	if content_scroll != null:
		content_scroll.custom_minimum_size = Vector2.ZERO
	if nav_title_label != null:
		nav_title_label.add_theme_font_size_override("font_size", int(round((20 if dense_tight else (24 if tight else (26 if compact else 30))) * font_scale)))
	if nav_body_label != null:
		nav_body_label.visible = not dense_tight
		nav_body_label.add_theme_font_size_override("font_size", int(round((15 if tight else 17) * font_scale)))
	if hint_label != null:
		hint_label.visible = not dense_tight
		hint_label.add_theme_font_size_override("font_size", int(round((13 if tight else 15) * font_scale)))
	if tab_title_label != null:
		tab_title_label.add_theme_font_size_override("font_size", int(round((24 if dense_tight else (28 if tight else (30 if compact else 34))) * font_scale)))
	if tab_summary_label != null:
		tab_summary_label.add_theme_font_size_override("font_size", int(round((14 if dense_tight else (15 if tight else 17)) * font_scale)))
	if video_content != null:
		video_content.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class) + 4)
	if placeholder_content != null:
		placeholder_content.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class) + 2)
	if resolution_value_label != null:
		resolution_value_label.add_theme_font_size_override("font_size", int(round((16 if dense_tight else (18 if tight else (20 if compact else 22))) * font_scale)))
	if fullscreen_value_label != null:
		fullscreen_value_label.add_theme_font_size_override("font_size", int(round((16 if dense_tight else (18 if tight else (20 if compact else 22))) * font_scale)))
	var nav_button_height := 44.0 if dense_tight else StandardUiLayoutMetricsRef.primary_button_height(layout_class)
	for tab_button in [tab_audio_button, tab_video_button, tab_controls_button, tab_accessibility_button]:
		if tab_button != null:
			tab_button.custom_minimum_size = Vector2(0, nav_button_height)
			tab_button.add_theme_font_size_override("font_size", int(round((16 if large_text else 15) * font_scale)))
	var action_width := 120.0 if dense_tight else (160.0 if tight else 180.0)
	var action_height := 40.0 if dense_tight else StandardUiLayoutMetricsRef.secondary_button_height(layout_class)
	for action_button in [resolution_prev_button, resolution_next_button, fullscreen_toggle_button, apply_button, reset_button, back_button]:
		if action_button != null:
			action_button.custom_minimum_size = Vector2(action_width, action_height)
			action_button.add_theme_font_size_override("font_size", int(round((15 if large_text else 14) * font_scale)))
	if action_row != null:
		action_row.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class))

func _refresh_controls_content() -> void:
	if controls_runtime_box == null:
		return
	if tab_summary_label != null:
		tab_summary_label.text = "Review the current keyboard and controller controls for menus and the arena."
	_clear_runtime_box(controls_runtime_box)
	_add_controls_group(
		controls_runtime_box,
		"Movement & Arena Actions",
		[
			{"label": "Move Left", "binding": _format_action_bindings("move_left")},
			{"label": "Move Right", "binding": _format_action_bindings("move_right")},
			{"label": "Move Up", "binding": _format_action_bindings("move_up")},
			{"label": "Move Down", "binding": _format_action_bindings("move_down")},
			{"label": "Interact", "binding": _format_action_bindings("interact")}
		]
	)
	_add_controls_group(
		controls_runtime_box,
		"Menu Flow",
		[
			{"label": "Navigate", "binding": "Arrow Keys / D-pad / Left Stick"},
			{"label": "Confirm", "binding": "Enter / Space / Pad A / Cross"},
			{"label": "Back / close", "binding": "Esc / Pad B / Circle"},
			{"label": "Random starter", "binding": "R (keyboard helper)"},
			{"label": "Default starter", "binding": "T (keyboard helper)"}
		]
	)
	_add_controls_group(
		controls_runtime_box,
		"In-Run Essentials",
		[
			{"label": "Pause", "binding": _format_action_bindings("pause_game")},
			{"label": "Confirm Shop / Level Up", "binding": "Enter / Space / Pad A / Cross"},
			{"label": "Back from menus", "binding": "Esc / Pad B / Circle"}
		]
	)
	var status_label := Label.new()
	status_label.text = "Status: keyboard and controller reference is live. Full rebinding remains deferred until playtest evidence justifies it."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	StandardInfernalUiStyleRef.apply_text_role(status_label, StandardInfernalUiStyleRef.TEXT_VALUE)
	controls_runtime_box.add_child(status_label)
	_refresh_action_row_state()

func _format_action_bindings(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return "-"
	var parts: Array[String] = []
	for event_variant in InputMap.action_get_events(action_name):
		var label := ""
		if event_variant is InputEventKey:
			var key_event := event_variant as InputEventKey
			label = OS.get_keycode_string(key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode)
		elif event_variant is InputEventMouseButton:
			label = "Mouse %d" % (event_variant as InputEventMouseButton).button_index
		elif event_variant is InputEventJoypadButton:
			label = _joy_button_label((event_variant as InputEventJoypadButton).button_index)
		elif event_variant is InputEventJoypadMotion:
			var motion := event_variant as InputEventJoypadMotion
			label = _joy_axis_label(motion.axis, motion.axis_value)
		if label != "" and not parts.has(label):
			parts.append(label)
	return ", ".join(parts) if not parts.is_empty() else "-"

func _joy_button_label(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A:
			return "Pad A / Cross"
		JOY_BUTTON_B:
			return "Pad B / Circle"
		JOY_BUTTON_X:
			return "Pad X / Square"
		JOY_BUTTON_Y:
			return "Pad Y / Triangle"
		JOY_BUTTON_START:
			return "Pad Menu"
		JOY_BUTTON_BACK:
			return "Pad View"
		JOY_BUTTON_DPAD_LEFT:
			return "D-pad Left"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-pad Right"
		JOY_BUTTON_DPAD_UP:
			return "D-pad Up"
		JOY_BUTTON_DPAD_DOWN:
			return "D-pad Down"
		_:
			return "Pad Button %d" % button_index

func _joy_axis_label(axis: int, axis_value: float) -> String:
	match axis:
		JOY_AXIS_LEFT_X:
			return "Left Stick Left" if axis_value < 0.0 else "Left Stick Right"
		JOY_AXIS_LEFT_Y:
			return "Left Stick Up" if axis_value < 0.0 else "Left Stick Down"
		JOY_AXIS_RIGHT_X:
			return "Right Stick Left" if axis_value < 0.0 else "Right Stick Right"
		JOY_AXIS_RIGHT_Y:
			return "Right Stick Up" if axis_value < 0.0 else "Right Stick Down"
		_:
			return "Pad Axis %d" % axis
