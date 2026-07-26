extends "res://scripts/ui/character_select_screen.gd"

const StandardInfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const StandardUiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")
const StandardAccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const StandardChoiceCardScene = preload("res://scenes/ui/components/StandardChoiceCard.tscn")
const StandardTagChipScene = preload("res://scenes/ui/components/StandardTagChip.tscn")

func _apply_shell_styles() -> void:
	StandardInfernalUiStyleRef.apply_panel(roster_panel, StandardInfernalUiStyleRef.PANEL_SHELL)
	StandardInfernalUiStyleRef.apply_panel(showcase_panel, StandardInfernalUiStyleRef.PANEL_SECTION)
	StandardInfernalUiStyleRef.apply_panel(detail_panel, StandardInfernalUiStyleRef.PANEL_SECTION)
	StandardInfernalUiStyleRef.apply_panel(starter_modal_panel, StandardInfernalUiStyleRef.PANEL_MODAL)
	StandardInfernalUiStyleRef.apply_panel(portrait_stage, StandardInfernalUiStyleRef.PANEL_CARD)
	for detail_card_path in [
		"RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/IdentityCard",
		"RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/PassiveCard",
		"RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/OpeningWeaponCard"
	]:
		StandardInfernalUiStyleRef.apply_panel(get_node_or_null(detail_card_path), StandardInfernalUiStyleRef.PANEL_CARD)

	StandardInfernalUiStyleRef.apply_text_role(header_title, StandardInfernalUiStyleRef.TEXT_SCREEN_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(header_status, StandardInfernalUiStyleRef.TEXT_MUTED)
	StandardInfernalUiStyleRef.apply_text_role(selected_name, StandardInfernalUiStyleRef.TEXT_SCREEN_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(selected_tagline, StandardInfernalUiStyleRef.TEXT_MUTED)
	for value_label in [family_value, difficulty_value, signature_value]:
		StandardInfernalUiStyleRef.apply_text_role(value_label, StandardInfernalUiStyleRef.TEXT_VALUE)
	for heading_variant in find_children("Heading", "Label", true, false):
		if heading_variant is Label:
			StandardInfernalUiStyleRef.apply_text_role(heading_variant as Label, StandardInfernalUiStyleRef.TEXT_SECTION_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(identity_summary, StandardInfernalUiStyleRef.TEXT_BODY)
	StandardInfernalUiStyleRef.apply_text_role(identity_fantasy_hook, StandardInfernalUiStyleRef.TEXT_MUTED)
	StandardInfernalUiStyleRef.apply_text_role(passive_name, StandardInfernalUiStyleRef.TEXT_CARD_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(passive_summary, StandardInfernalUiStyleRef.TEXT_BODY)
	StandardInfernalUiStyleRef.apply_text_role(opening_weapon_name, StandardInfernalUiStyleRef.TEXT_CARD_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(opening_weapon_summary, StandardInfernalUiStyleRef.TEXT_BODY)
	StandardInfernalUiStyleRef.apply_text_role(starter_modal_title, StandardInfernalUiStyleRef.TEXT_SCREEN_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(starter_modal_hunter_label, StandardInfernalUiStyleRef.TEXT_MUTED)
	StandardInfernalUiStyleRef.apply_text_role(starter_selected_name, StandardInfernalUiStyleRef.TEXT_CARD_TITLE)
	StandardInfernalUiStyleRef.apply_text_role(starter_selected_description, StandardInfernalUiStyleRef.TEXT_BODY)
	StandardInfernalUiStyleRef.apply_text_role(starter_selected_tags, StandardInfernalUiStyleRef.TEXT_HINT)
	StandardInfernalUiStyleRef.apply_button(back_button, StandardInfernalUiStyleRef.BUTTON_SECONDARY)
	StandardInfernalUiStyleRef.apply_button(confirm_button, StandardInfernalUiStyleRef.BUTTON_PRIMARY)
	StandardInfernalUiStyleRef.apply_button(starter_modal_back_button, StandardInfernalUiStyleRef.BUTTON_SECONDARY)
	StandardInfernalUiStyleRef.apply_button(starter_modal_start_button, StandardInfernalUiStyleRef.BUTTON_PRIMARY)
	portrait_placeholder.color = Color(0.23, 0.17, 0.12, 0.82)
	_apply_standard_layout()

func _apply_standard_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var layout_class := StandardUiLayoutMetricsRef.layout_class_for_size(viewport_size)
	var tight := layout_class == StandardUiLayoutMetricsRef.LayoutClass.TIGHT
	var root_margin := get_node_or_null("RootMargin") as MarginContainer
	var root_vbox := get_node_or_null("RootMargin/RootVBox") as VBoxContainer
	var header := get_node_or_null("RootMargin/RootVBox/Header") as Control
	var main_hbox := get_node_or_null("RootMargin/RootVBox/MainHBox") as HBoxContainer
	var roster_margin := get_node_or_null("RootMargin/RootVBox/MainHBox/RosterPanel/RosterMargin") as MarginContainer
	var showcase_margin := get_node_or_null("RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin") as MarginContainer
	var starter_margin := get_node_or_null("StarterModalCenter/StarterModalPanel/StarterModalMargin") as MarginContainer
	if root_margin != null:
		var horizontal_margin := StandardUiLayoutMetricsRef.screen_margin_horizontal(layout_class)
		var vertical_margin := StandardUiLayoutMetricsRef.screen_margin_vertical(layout_class)
		root_margin.offset_left = horizontal_margin
		root_margin.offset_top = vertical_margin
		root_margin.offset_right = -horizontal_margin
		root_margin.offset_bottom = -vertical_margin
	if root_vbox != null:
		root_vbox.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class))
	if header != null:
		header.custom_minimum_size.y = 52.0 if tight else 72.0
	if main_hbox != null:
		main_hbox.custom_minimum_size.y = 462.0
		main_hbox.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class) + 4)
	if roster_margin != null:
		var dense := StandardUiLayoutMetricsRef.dense_gap(layout_class)
		roster_margin.add_theme_constant_override("margin_left", dense)
		roster_margin.add_theme_constant_override("margin_top", dense)
		roster_margin.add_theme_constant_override("margin_right", dense)
		roster_margin.add_theme_constant_override("margin_bottom", dense)
	if showcase_margin != null:
		var section_padding := StandardUiLayoutMetricsRef.section_padding(layout_class)
		showcase_margin.add_theme_constant_override("margin_left", section_padding)
		showcase_margin.add_theme_constant_override("margin_top", StandardUiLayoutMetricsRef.dense_gap(layout_class))
		showcase_margin.add_theme_constant_override("margin_right", section_padding)
		showcase_margin.add_theme_constant_override("margin_bottom", StandardUiLayoutMetricsRef.dense_gap(layout_class))
	if roster_grid != null:
		roster_grid.add_theme_constant_override("h_separation", StandardUiLayoutMetricsRef.dense_gap(layout_class) + 2)
		roster_grid.add_theme_constant_override("v_separation", StandardUiLayoutMetricsRef.dense_gap(layout_class) + 2)
	if action_row != null:
		action_row.custom_minimum_size.y = 44.0 if tight else 50.0
		action_row.add_theme_constant_override("separation", StandardUiLayoutMetricsRef.row_gap(layout_class) + 4)
	if starter_margin != null:
		var modal_padding := StandardUiLayoutMetricsRef.shell_padding(layout_class)
		starter_margin.add_theme_constant_override("margin_left", modal_padding)
		starter_margin.add_theme_constant_override("margin_top", modal_padding)
		starter_margin.add_theme_constant_override("margin_right", modal_padding)
		starter_margin.add_theme_constant_override("margin_bottom", modal_padding)
	if starter_modal_panel != null:
		starter_modal_panel.custom_minimum_size = Vector2(760 if tight else 820, 480 if tight else 500)
	if back_button != null:
		back_button.custom_minimum_size = Vector2(170 if tight else 190, StandardUiLayoutMetricsRef.secondary_button_height(layout_class))
	if confirm_button != null:
		confirm_button.custom_minimum_size = Vector2(220 if tight else 260, StandardUiLayoutMetricsRef.primary_button_height(layout_class))
	if starter_modal_back_button != null:
		starter_modal_back_button.custom_minimum_size = Vector2(180 if tight else 210, StandardUiLayoutMetricsRef.secondary_button_height(layout_class))
	if starter_modal_start_button != null:
		starter_modal_start_button.custom_minimum_size = Vector2(210 if tight else 240, StandardUiLayoutMetricsRef.primary_button_height(layout_class))

func _apply_roster_tile_style(button: Button, is_selected: bool) -> void:
	StandardInfernalUiStyleRef.apply_card_button(button, is_selected)

func _build_sealed_roster_tile() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = ROSTER_TILE_SIZE
	panel.focus_mode = Control.FOCUS_NONE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	StandardInfernalUiStyleRef.apply_panel(panel, StandardInfernalUiStyleRef.PANEL_CARD)
	panel.modulate = Color(0.62, 0.58, 0.54, 0.52)
	var center := CenterContainer.new()
	panel.add_child(center)
	var label := Label.new()
	label.text = "◈"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", StandardAccessibilitySettingsRuntimeRef.scale_font(14, accessibility_settings))
	StandardInfernalUiStyleRef.apply_text_role(label, StandardInfernalUiStyleRef.TEXT_MUTED)
	center.add_child(label)
	return panel

func _rebuild_tag_row(tags: Array[String]) -> void:
	for child in tag_row.get_children():
		child.queue_free()
	for tag in tags:
		var chip_variant: Variant = StandardTagChipScene.instantiate()
		if not (chip_variant is PanelContainer):
			continue
		var chip := chip_variant as PanelContainer
		chip.call("configure", tag)
		tag_row.add_child(chip)

func _rebuild_arsenal_preview(textures: Array[Texture2D]) -> void:
	for child in arsenal_preview_row.get_children():
		child.queue_free()
	for slot_index in range(5):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(30, 30)
		StandardInfernalUiStyleRef.apply_panel(panel, StandardInfernalUiStyleRef.PANEL_CARD)
		var center := CenterContainer.new()
		panel.add_child(center)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if slot_index < textures.size():
			icon.texture = textures[slot_index]
		center.add_child(icon)
		arsenal_preview_row.add_child(panel)

func _rebuild_starter_option_buttons() -> void:
	for child in starter_options_grid.get_children():
		child.queue_free()
	for option_index in starter_weapon_options.size():
		var option: Dictionary = starter_weapon_options[option_index]
		var card_variant: Variant = StandardChoiceCardScene.instantiate()
		if not (card_variant is Button):
			continue
		var card := card_variant as Button
		card.custom_minimum_size.x = 230.0
		var tags := _normalize_string_array(option.get("tags", []))
		var eyebrow := "DEFAULT STARTER" if option.get("default_selected", false) == true else "STARTER WEAPON"
		var icon_variant: Variant = option.get("icon", null)
		var icon: Texture2D = icon_variant if icon_variant is Texture2D else null
		card.call(
			"configure",
			str(option.get("display_name", option.get("id", "Weapon"))),
			_truncate_text(str(option.get("description", "")), 90),
			eyebrow,
			" / ".join(tags).to_upper(),
			"Select",
			icon
		)
		card.call("set_selected", option_index == selected_starter_index)
		card.pressed.connect(_select_starter_index.bind(option_index))
		starter_options_grid.add_child(card)
	_focus_selected_starter_button()

func _refresh_starter_option_styles() -> void:
	for option_index in range(starter_options_grid.get_child_count()):
		var button := starter_options_grid.get_child(option_index) as Button
		if button == null:
			continue
		if button.has_method("set_selected"):
			button.call("set_selected", option_index == selected_starter_index)
		else:
			StandardInfernalUiStyleRef.apply_card_button(button, option_index == selected_starter_index)
