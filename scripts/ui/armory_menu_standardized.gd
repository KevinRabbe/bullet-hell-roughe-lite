extends "res://scripts/ui/armory_menu.gd"

const StandardCodexCardScene = preload("res://scenes/ui/components/StandardCodexCard.tscn")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")
const StandardMenuPortraitRuntimeRef = preload("res://scripts/ui/menu_portrait_runtime.gd")

const STANDARD_SECTION_ORDER: Array[String] = [
	"characters",
	"weapons",
	"items",
	"set_bonuses"
]

func _rebuild_nav_buttons() -> void:
	if nav_buttons == null:
		return
	for child in nav_buttons.get_children():
		child.queue_free()
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	for section_id in STANDARD_SECTION_ORDER:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, UiLayoutMetricsRef.secondary_button_height(layout_class))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _build_section_button_text(section_id)
		_apply_section_button_style(button, section_id == selected_section_id)
		button.pressed.connect(_on_section_button_pressed.bind(section_id))
		nav_buttons.add_child(button)
	if nav_buttons.get_child_count() > 0:
		var selected_index := STANDARD_SECTION_ORDER.find(selected_section_id)
		if selected_index >= 0 and selected_index < nav_buttons.get_child_count():
			var selected_button := nav_buttons.get_child(selected_index) as Button
			if selected_button != null:
				selected_button.grab_focus()

func _apply_section_button_style(button: Button, is_selected: bool) -> void:
	InfernalUiStyleRef.apply_button(
		button,
		InfernalUiStyleRef.BUTTON_PRIMARY if is_selected else InfernalUiStyleRef.BUTTON_TAB
	)

func _build_character_card(entry: Dictionary) -> PanelContainer:
	var character_id := str(entry.get("id", ""))
	var presentation_variant: Variant = entry.get("presentation", {})
	var presentation: Dictionary = presentation_variant if presentation_variant is Dictionary else {}
	var detail_variant: Variant = entry.get("detail", {})
	var detail: Dictionary = detail_variant if detail_variant is Dictionary else {}
	var portrait_path := "res://assets/sprites/ui/menu/portraits/character_portrait_%s.png" % character_id
	var fallback_visual_path := str(entry.get("visual_path", ""))
	var portrait_texture := StandardMenuPortraitRuntimeRef.resolve_portrait_texture(portrait_path, fallback_visual_path)
	return _create_codex_card(
		str(entry.get("display_name", character_id)),
		"%s / %s" % [
			str(presentation.get("passive_name", "Passive")),
			str(presentation.get("difficulty", "medium")).capitalize()
		],
		str(presentation.get("fantasy_hook", "")),
		str(detail.get("starter_weapon_summary", "")),
		portrait_texture,
		character_id == selected_character_id,
		220.0,
		Callable(self, "_on_character_card_pressed").bind(character_id)
	)

func _build_weapon_card(entry: Dictionary) -> PanelContainer:
	var weapon_id := str(entry.get("id", ""))
	var icon_variant: Variant = entry.get("icon", null)
	var icon_texture: Texture2D = icon_variant if icon_variant is Texture2D else null
	return _create_codex_card(
		str(entry.get("display_name", weapon_id)),
		"%s / %s" % [str(entry.get("family_label", "Unaligned")), str(entry.get("rarity", "common")).capitalize()],
		str(entry.get("description", "")),
		"Tags: %s" % ", ".join(_string_array_from_variant(entry.get("tags", []))),
		icon_texture,
		weapon_id == selected_weapon_id,
		200.0,
		Callable(self, "_on_weapon_card_pressed").bind(weapon_id)
	)

func _build_item_card(entry: Dictionary) -> PanelContainer:
	var item_id := str(entry.get("id", ""))
	var icon_variant: Variant = entry.get("icon", null)
	var icon_texture: Texture2D = icon_variant if icon_variant is Texture2D else null
	return _create_codex_card(
		str(entry.get("name", item_id)),
		"%s / %s" % [str(entry.get("category_label", "Utility")), str(entry.get("rarity", "common")).capitalize()],
		str(entry.get("description", "")),
		"Item tags: %s" % ", ".join(_string_array_from_variant(entry.get("tags", []))),
		icon_texture,
		item_id == selected_item_id,
		190.0,
		Callable(self, "_on_item_card_pressed").bind(item_id)
	)

func _build_set_bonus_card(entry: Dictionary) -> PanelContainer:
	var set_bonus_id := str(entry.get("id", ""))
	return _create_codex_card(
		str(entry.get("family_label", set_bonus_id)),
		str(entry.get("subtitle", "Set bonus thresholds")),
		str(entry.get("summary", "")),
		"Thresholds: %s" % ", ".join(_string_array_from_variant(entry.get("threshold_labels", []))),
		null,
		set_bonus_id == selected_set_bonus_id,
		210.0,
		Callable(self, "_on_set_bonus_card_pressed").bind(set_bonus_id)
	)

func _create_codex_card(
	title: String,
	subtitle: String,
	summary: String,
	footer: String,
	icon: Texture2D,
	selected: bool,
	minimum_height: float,
	pressed_callable: Callable
) -> PanelContainer:
	var card_variant: Variant = StandardCodexCardScene.instantiate()
	if not (card_variant is PanelContainer):
		return PanelContainer.new()
	var card := card_variant as PanelContainer
	card.custom_minimum_size.y = minimum_height
	card.call("configure", title, subtitle, summary, footer, icon)
	card.call("set_selected", selected)
	if card.has_signal("pressed"):
		card.connect("pressed", pressed_callable)
	return card

func _apply_shared_shell_styles() -> void:
	InfernalUiStyleRef.apply_panel(step_chip, InfernalUiStyleRef.PANEL_CARD)
	InfernalUiStyleRef.apply_panel(nav_panel, InfernalUiStyleRef.PANEL_SHELL)
	InfernalUiStyleRef.apply_panel(collection_panel, InfernalUiStyleRef.PANEL_SHELL)
	InfernalUiStyleRef.apply_panel(detail_panel, InfernalUiStyleRef.PANEL_SECTION)
	InfernalUiStyleRef.apply_text_role(header_copy_label, InfernalUiStyleRef.TEXT_MUTED)
	InfernalUiStyleRef.apply_text_role(collection_title, InfernalUiStyleRef.TEXT_SCREEN_TITLE)
	InfernalUiStyleRef.apply_text_role(detail_title, InfernalUiStyleRef.TEXT_SCREEN_TITLE)
	InfernalUiStyleRef.apply_text_role(detail_subtitle, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(collection_body, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(detail_summary, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(detail_bullets, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(detail_status, InfernalUiStyleRef.TEXT_HINT)
	InfernalUiStyleRef.apply_button(back_button, InfernalUiStyleRef.BUTTON_SECONDARY)

func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(viewport_size)
	var tight := layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var compact := layout_class == UiLayoutMetricsRef.LayoutClass.COMPACT
	if root_margin != null:
		var horizontal_margin := UiLayoutMetricsRef.screen_margin_horizontal(layout_class)
		var vertical_margin := UiLayoutMetricsRef.screen_margin_vertical(layout_class)
		root_margin.offset_left = horizontal_margin
		root_margin.offset_top = vertical_margin
		root_margin.offset_right = -horizontal_margin
		root_margin.offset_bottom = -vertical_margin
	var root_vbox := get_node_or_null("RootMargin/RootVBox") as VBoxContainer
	if root_vbox != null:
		root_vbox.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class) + 8)
	if main_hbox != null:
		main_hbox.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class) + 6)
	for margin_path in [
		"RootMargin/RootVBox/MainHBox/NavPanel/NavMargin",
		"RootMargin/RootVBox/MainHBox/CollectionPanel/CollectionMargin",
		"RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin"
	]:
		var section_margin := get_node_or_null(margin_path) as MarginContainer
		if section_margin != null:
			var padding := UiLayoutMetricsRef.section_padding(layout_class)
			section_margin.add_theme_constant_override("margin_left", padding)
			section_margin.add_theme_constant_override("margin_top", padding)
			section_margin.add_theme_constant_override("margin_right", padding)
			section_margin.add_theme_constant_override("margin_bottom", padding)
	if header_copy_label != null:
		header_copy_label.add_theme_font_size_override("font_size", 13 if tight else (15 if compact else 16))
		header_copy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if nav_panel != null:
		nav_panel.custom_minimum_size = Vector2(220 if tight else (250 if compact else 320), 0)
	if collection_panel != null:
		collection_panel.custom_minimum_size = Vector2(320 if tight else (360 if compact else 420), 0)
	if detail_panel != null:
		detail_panel.custom_minimum_size = Vector2(300 if tight else (340 if compact else 360), 0)
	if collection_title != null:
		collection_title.add_theme_font_size_override("font_size", 28 if tight else (30 if compact else 34))
	if collection_body != null:
		collection_body.add_theme_font_size_override("font_size", 14 if tight else 15)
	if detail_title != null:
		detail_title.add_theme_font_size_override("font_size", 28 if tight else (30 if compact else 34))
	if detail_subtitle != null:
		detail_subtitle.add_theme_font_size_override("font_size", 16 if tight else 18)
	if detail_summary != null:
		detail_summary.add_theme_font_size_override("font_size", 14 if tight else 15)
		detail_summary.custom_minimum_size = Vector2(0, 72 if tight else 92)
	if detail_bullets != null:
		detail_bullets.add_theme_font_size_override("font_size", 13 if tight else 14)
		detail_bullets.custom_minimum_size = Vector2(0, 126 if tight else 160)
	if detail_status != null:
		detail_status.add_theme_font_size_override("font_size", 13 if tight else 14)
	if back_button != null:
		back_button.custom_minimum_size = Vector2(160 if tight else 200, UiLayoutMetricsRef.secondary_button_height(layout_class))
		back_button.add_theme_font_size_override("font_size", 15 if tight else 16)
	if collection_grid != null:
		if selected_section_id == "characters":
			collection_grid.columns = 1
		else:
			collection_grid.columns = 1 if viewport_size.x < 1500.0 or tight else 2
