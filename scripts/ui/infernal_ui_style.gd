class_name InfernalUiStyle
extends RefCounted

const COLOR_ALMOST_BLACK := Color("#120B10")
const COLOR_BURNT_BROWN := Color("#2A1711")
const COLOR_DEEP_BLOOD_RED := Color("#5A0F1B")
const COLOR_RITUAL_CRIMSON := Color("#9E1B2F")
const COLOR_OLD_PARCHMENT := Color("#B88A55")
const COLOR_BONE_HIGHLIGHT := Color("#E8D6B0")
const COLOR_HELL_ORANGE := Color("#F06A1A")

const PANEL_SHELL: StringName = &"shell"
const PANEL_SECTION: StringName = &"section"
const PANEL_CARD: StringName = &"card"
const PANEL_MODAL: StringName = &"modal"
const PANEL_TOOLTIP: StringName = &"tooltip"

const BUTTON_PRIMARY: StringName = &"primary"
const BUTTON_SECONDARY: StringName = &"secondary"
const BUTTON_DANGER: StringName = &"danger"
const BUTTON_CARD: StringName = &"card"
const BUTTON_TAB: StringName = &"tab"
const BUTTON_ICON: StringName = &"icon"

const TEXT_DISPLAY_TITLE: StringName = &"display_title"
const TEXT_SCREEN_TITLE: StringName = &"screen_title"
const TEXT_SECTION_TITLE: StringName = &"section_title"
const TEXT_CARD_TITLE: StringName = &"card_title"
const TEXT_BODY: StringName = &"body"
const TEXT_MUTED: StringName = &"muted"
const TEXT_VALUE: StringName = &"value"
const TEXT_HINT: StringName = &"hint"
const TEXT_WARNING: StringName = &"warning"

static func apply_panel(control: Control, panel_role: StringName = PANEL_SECTION) -> void:
	if control == null:
		return
	control.add_theme_stylebox_override("panel", build_panel_style(panel_role))

static func apply_button(button: Button, button_role: StringName = BUTTON_SECONDARY, selected: bool = false) -> void:
	if button == null:
		return
	match button_role:
		BUTTON_PRIMARY:
			_apply_button_styles(
				button,
				_build_style(COLOR_BURNT_BROWN, COLOR_HELL_ORANGE, 2, 10, 16),
				_build_style(COLOR_DEEP_BLOOD_RED, COLOR_HELL_ORANGE, 2, 10, 16),
				_build_style(COLOR_RITUAL_CRIMSON, COLOR_BONE_HIGHLIGHT, 2, 10, 16),
				_build_style(COLOR_BURNT_BROWN, COLOR_BONE_HIGHLIGHT, 3, 10, 16)
			)
		BUTTON_DANGER:
			_apply_button_styles(
				button,
				_build_style(COLOR_DEEP_BLOOD_RED.darkened(0.18), COLOR_RITUAL_CRIMSON, 2, 10, 16),
				_build_style(COLOR_DEEP_BLOOD_RED, COLOR_HELL_ORANGE, 2, 10, 16),
				_build_style(COLOR_RITUAL_CRIMSON, COLOR_BONE_HIGHLIGHT, 2, 10, 16),
				_build_style(COLOR_DEEP_BLOOD_RED, COLOR_BONE_HIGHLIGHT, 3, 10, 16)
			)
		BUTTON_CARD:
			var normal_border := COLOR_HELL_ORANGE if selected else COLOR_BURNT_BROWN
			var normal_width := 2 if selected else 1
			_apply_button_styles(
				button,
				_build_style(COLOR_ALMOST_BLACK, normal_border, normal_width, 8, 12),
				_build_style(COLOR_BURNT_BROWN, COLOR_OLD_PARCHMENT, 2, 8, 12),
				_build_style(COLOR_DEEP_BLOOD_RED, COLOR_HELL_ORANGE, 2, 8, 12),
				_build_style(COLOR_ALMOST_BLACK, COLOR_HELL_ORANGE, 2, 8, 12)
			)
		BUTTON_TAB:
			_apply_button_styles(
				button,
				_build_style(COLOR_ALMOST_BLACK, COLOR_BURNT_BROWN, 1, 8, 12),
				_build_style(COLOR_BURNT_BROWN, COLOR_OLD_PARCHMENT, 1, 8, 12),
				_build_style(COLOR_DEEP_BLOOD_RED, COLOR_HELL_ORANGE, 2, 8, 12),
				_build_style(COLOR_ALMOST_BLACK, COLOR_HELL_ORANGE, 2, 8, 12)
			)
		BUTTON_ICON:
			_apply_button_styles(
				button,
				_build_style(COLOR_ALMOST_BLACK, COLOR_BURNT_BROWN, 1, 8, 8),
				_build_style(COLOR_BURNT_BROWN, COLOR_OLD_PARCHMENT, 1, 8, 8),
				_build_style(COLOR_DEEP_BLOOD_RED, COLOR_HELL_ORANGE, 2, 8, 8),
				_build_style(COLOR_ALMOST_BLACK, COLOR_HELL_ORANGE, 2, 8, 8)
			)
		_:
			_apply_button_styles(
				button,
				_build_style(COLOR_ALMOST_BLACK, COLOR_BURNT_BROWN, 1, 10, 16),
				_build_style(COLOR_BURNT_BROWN, COLOR_OLD_PARCHMENT, 1, 10, 16),
				_build_style(COLOR_DEEP_BLOOD_RED, COLOR_OLD_PARCHMENT, 2, 10, 16),
				_build_style(COLOR_ALMOST_BLACK, COLOR_OLD_PARCHMENT, 2, 10, 16)
			)

static func apply_primary_button(button: Button) -> void:
	apply_button(button, BUTTON_PRIMARY)

static func apply_secondary_button(button: Button) -> void:
	apply_button(button, BUTTON_SECONDARY)

static func apply_danger_button(button: Button) -> void:
	apply_button(button, BUTTON_DANGER)

static func apply_card_button(button: Button, selected: bool = false) -> void:
	apply_button(button, BUTTON_CARD, selected)

static func apply_tab_button(button: Button) -> void:
	apply_button(button, BUTTON_TAB)

static func apply_icon_button(button: Button) -> void:
	apply_button(button, BUTTON_ICON)

static func apply_text_role(label: Label, text_role: StringName = TEXT_BODY) -> void:
	if label == null:
		return
	match text_role:
		TEXT_DISPLAY_TITLE, TEXT_SCREEN_TITLE, TEXT_CARD_TITLE, TEXT_VALUE:
			label.add_theme_color_override("font_color", COLOR_BONE_HIGHLIGHT)
		TEXT_SECTION_TITLE:
			label.add_theme_color_override("font_color", COLOR_OLD_PARCHMENT)
		TEXT_WARNING:
			label.add_theme_color_override("font_color", COLOR_HELL_ORANGE)
		TEXT_MUTED, TEXT_HINT:
			label.add_theme_color_override("font_color", COLOR_OLD_PARCHMENT.darkened(0.22))
		_:
			label.add_theme_color_override("font_color", COLOR_BONE_HIGHLIGHT.darkened(0.18))

static func apply_title(label: Label) -> void:
	apply_text_role(label, TEXT_SCREEN_TITLE)

static func apply_section_title(label: Label) -> void:
	apply_text_role(label, TEXT_SECTION_TITLE)

static func apply_body_text(label: Label) -> void:
	apply_text_role(label, TEXT_BODY)

static func apply_muted_text(label: Label) -> void:
	apply_text_role(label, TEXT_MUTED)

static func apply_value_text(label: Label) -> void:
	apply_text_role(label, TEXT_VALUE)

static func apply_hint_text(label: Label) -> void:
	apply_text_role(label, TEXT_HINT)

static func apply_accent_text(label: Label) -> void:
	apply_text_role(label, TEXT_WARNING)

static func apply_progress_bar(progress_bar: ProgressBar) -> void:
	if progress_bar == null:
		return
	progress_bar.add_theme_stylebox_override(
		"background",
		_build_progress_style(COLOR_ALMOST_BLACK, COLOR_BURNT_BROWN)
	)
	progress_bar.add_theme_stylebox_override(
		"fill",
		_build_progress_style(COLOR_DEEP_BLOOD_RED, COLOR_HELL_ORANGE)
	)
	progress_bar.add_theme_color_override("font_color", COLOR_BONE_HIGHLIGHT)

static func build_panel_style(panel_role: StringName = PANEL_SECTION) -> StyleBoxFlat:
	match panel_role:
		PANEL_SHELL:
			return _build_style(COLOR_ALMOST_BLACK, COLOR_BURNT_BROWN, 1, 12, 18)
		PANEL_CARD:
			return _build_style(COLOR_ALMOST_BLACK.lightened(0.025), COLOR_BURNT_BROWN, 1, 8, 12)
		PANEL_MODAL:
			return _build_style(COLOR_ALMOST_BLACK.lightened(0.01), COLOR_RITUAL_CRIMSON, 2, 12, 18)
		PANEL_TOOLTIP:
			return _build_style(COLOR_ALMOST_BLACK.lightened(0.02), COLOR_OLD_PARCHMENT.darkened(0.2), 1, 8, 12)
		_:
			return _build_style(COLOR_ALMOST_BLACK.lightened(0.015), COLOR_DEEP_BLOOD_RED, 1, 10, 16)

static func _apply_button_styles(
	button: Button,
	normal_style: StyleBoxFlat,
	hover_style: StyleBoxFlat,
	pressed_style: StyleBoxFlat,
	focus_style: StyleBoxFlat
) -> void:
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus_style)
	button.add_theme_stylebox_override(
		"disabled",
		_build_style(COLOR_ALMOST_BLACK.lightened(0.04), COLOR_BURNT_BROWN.darkened(0.28), 1, 10, 16)
	)
	button.add_theme_color_override("font_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_hover_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_pressed_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_focus_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_disabled_color", COLOR_OLD_PARCHMENT.darkened(0.42))

static func _build_progress_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

static func _build_style(
	background_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int,
	content_margin: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style
