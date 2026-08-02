extends Control

const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"

@onready var root_margin: MarginContainer = $RootMargin
@onready var main_panel: PanelContainer = $RootMargin/RootVBox/MainPanel
@onready var main_margin: MarginContainer = $RootMargin/RootVBox/MainPanel/MainMargin
@onready var main_vbox: VBoxContainer = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox
@onready var eyebrow_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/Eyebrow
@onready var title_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/Title
@onready var summary_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/Summary
@onready var credits_block: PanelContainer = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/CreditsBlock
@onready var credits_margin: MarginContainer = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/CreditsBlock/CreditsMargin
@onready var credits_vbox: VBoxContainer = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/CreditsBlock/CreditsMargin/CreditsVBox
@onready var section_titles: Array[Label] = [
	$RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/CreditsBlock/CreditsMargin/CreditsVBox/Section1,
	$RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/CreditsBlock/CreditsMargin/CreditsVBox/Section2,
	$RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/CreditsBlock/CreditsMargin/CreditsVBox/Section3,
]
@onready var section_bodies: Array[Label] = [
	$RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/CreditsBlock/CreditsMargin/CreditsVBox/Section1Body,
	$RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/CreditsBlock/CreditsMargin/CreditsVBox/Section2Body,
	$RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/CreditsBlock/CreditsMargin/CreditsVBox/Section3Body,
]
@onready var back_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/BackButton

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	_apply_shell_panel_style()
	_apply_responsive_layout()
	MenuAnimationRuntimeRef.play_screen_intro([main_panel])
	resized.connect(_apply_responsive_layout)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
		back_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _apply_shell_panel_style() -> void:
	if main_panel == null:
		return
	InfernalUiStyleRef.apply_panel(main_panel, InfernalUiStyleRef.PANEL_SHELL)
	InfernalUiStyleRef.apply_panel(credits_block, InfernalUiStyleRef.PANEL_SECTION)
	InfernalUiStyleRef.apply_text_role(eyebrow_label, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(title_label, InfernalUiStyleRef.TEXT_SCREEN_TITLE)
	InfernalUiStyleRef.apply_text_role(summary_label, InfernalUiStyleRef.TEXT_MUTED)
	for section_title in section_titles:
		InfernalUiStyleRef.apply_text_role(section_title, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	for section_body in section_bodies:
		InfernalUiStyleRef.apply_text_role(section_body, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_button(back_button, InfernalUiStyleRef.BUTTON_SECONDARY)

func _apply_responsive_layout() -> void:
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var tight := layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var compact := layout_class == UiLayoutMetricsRef.LayoutClass.COMPACT
	if root_margin != null:
		var horizontal_margin := UiLayoutMetricsRef.screen_margin_horizontal(layout_class)
		var vertical_margin := UiLayoutMetricsRef.screen_margin_vertical(layout_class)
		root_margin.offset_left = horizontal_margin
		root_margin.offset_top = vertical_margin
		root_margin.offset_right = -horizontal_margin
		root_margin.offset_bottom = -vertical_margin
	if main_margin != null:
		var padding := UiLayoutMetricsRef.shell_padding(layout_class)
		main_margin.add_theme_constant_override("margin_left", padding)
		main_margin.add_theme_constant_override("margin_top", padding)
		main_margin.add_theme_constant_override("margin_right", padding)
		main_margin.add_theme_constant_override("margin_bottom", padding)
	if credits_margin != null:
		var section_padding := UiLayoutMetricsRef.section_padding(layout_class)
		credits_margin.add_theme_constant_override("margin_left", section_padding)
		credits_margin.add_theme_constant_override("margin_top", section_padding)
		credits_margin.add_theme_constant_override("margin_right", section_padding)
		credits_margin.add_theme_constant_override("margin_bottom", section_padding)
	if main_vbox != null:
		main_vbox.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class) + 6)
	if credits_vbox != null:
		credits_vbox.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class))
	if main_panel != null:
		main_panel.custom_minimum_size = Vector2(0, 430 if tight else (470 if compact else 500))
	if eyebrow_label != null:
		eyebrow_label.add_theme_font_size_override("font_size", 16 if tight else (17 if compact else 18))
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 34 if tight else (38 if compact else 42))
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", 15 if tight else 17)
	for section_title in section_titles:
		section_title.add_theme_font_size_override("font_size", 18 if tight else (20 if compact else 22))
	if back_button != null:
		back_button.custom_minimum_size = Vector2(150 if tight else (180 if compact else 220), UiLayoutMetricsRef.secondary_button_height(layout_class))
		back_button.add_theme_font_size_override("font_size", 15 if tight else 16)
