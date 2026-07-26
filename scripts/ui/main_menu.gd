extends Control

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"
const ARMORY_SCENE_PATH := "res://scenes/ui/ArmoryMenu.tscn"
const CREDITS_SCENE_PATH := "res://scenes/ui/CreditsMenu.tscn"
const OPTIONS_SCENE_PATH := "res://scenes/ui/OptionsMenuStandardized.tscn"
const MAIN_MENU_BACKGROUND_ART_PATH := "res://assets/sprites/ui/menu/backgrounds/main_menu_background.png"
const MAIN_MENU_HERO_ART_PATH := "res://assets/sprites/ui/menu/backgrounds/main_menu_hero_art.png"

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var root_margin: MarginContainer = $RootMargin
@onready var main_hbox: Control = $RootMargin/MainHBox
@onready var hero_panel: PanelContainer = $RootMargin/MainHBox/HeroPanel
@onready var hero_art_slot: TextureRect = $RootMargin/MainHBox/HeroPanel/HeroStage/HeroArtSlot
@onready var eyebrow_label: Label = $RootMargin/MainHBox/HeroPanel/HeroStage/HeroContentMargin/HeroContent/Eyebrow
@onready var title_label: Label = $RootMargin/MainHBox/HeroPanel/HeroStage/HeroContentMargin/HeroContent/Title
@onready var subtitle_label: Label = $RootMargin/MainHBox/HeroPanel/HeroStage/HeroContentMargin/HeroContent/Subtitle
@onready var hero_callout: Label = $RootMargin/MainHBox/HeroPanel/HeroStage/HeroContentMargin/HeroContent/HeroCallout
@onready var menu_panel: PanelContainer = $RootMargin/MainHBox/MenuPanel
@onready var menu_margin: MarginContainer = $RootMargin/MainHBox/MenuPanel/MenuMargin
@onready var menu_vbox: VBoxContainer = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox
@onready var menu_eyebrow: Label = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox/MenuEyebrow
@onready var menu_title: Label = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox/MenuTitle
@onready var menu_body: Label = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox/MenuBody
@onready var start_button: Button = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox/StartButton
@onready var armory_button: Button = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox/ArmoryButton
@onready var options_button: Button = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox/OptionsButton
@onready var credits_button: Button = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox/CreditsButton
@onready var quit_button: Button = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox/QuitButton
@onready var footer_label: Label = $RootMargin/MainHBox/MenuPanel/MenuMargin/MenuVBox/FooterLabel

var accessibility_settings: Dictionary = {}

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	accessibility_settings = AccessibilitySettingsRuntimeRef.apply_saved_settings()
	_apply_optional_texture(arena_texture, MAIN_MENU_BACKGROUND_ART_PATH)
	_apply_optional_texture(hero_art_slot, MAIN_MENU_HERO_ART_PATH)
	_apply_presentation()
	resized.connect(_apply_responsive_layout)
	call_deferred("_finish_initial_layout")

func _finish_initial_layout() -> void:
	_apply_responsive_layout()
	MenuAnimationRuntimeRef.play_screen_intro([hero_panel, menu_panel])
	MenuAnimationRuntimeRef.play_ambient_pulse(
		hero_art_slot,
		Color(0.92, 0.84, 0.86, 0.96),
		Color(1.0, 0.96, 0.92, 1.0),
		3.2
	)
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)

func _on_armory_button_pressed() -> void:
	get_tree().change_scene_to_file(ARMORY_SCENE_PATH)

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE_PATH)

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE_PATH)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _apply_optional_texture(target: TextureRect, texture_path: String) -> void:
	if target == null:
		return
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		target.texture = null
		return
	var texture_variant: Variant = load(texture_path)
	target.texture = texture_variant if texture_variant is Texture2D else null

func _apply_presentation() -> void:
	InfernalUiStyleRef.apply_panel(hero_panel, InfernalUiStyleRef.PANEL_CARD)
	menu_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for label in [title_label, menu_title]:
		InfernalUiStyleRef.apply_title(label)
	for label in [eyebrow_label, menu_eyebrow]:
		InfernalUiStyleRef.apply_section_title(label)
	for label in [subtitle_label, menu_body, hero_callout, footer_label]:
		InfernalUiStyleRef.apply_body_text(label)
	InfernalUiStyleRef.apply_primary_button(start_button)
	for button in [armory_button, options_button, credits_button, quit_button]:
		InfernalUiStyleRef.apply_secondary_button(button)

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var layout_class: int = UiLayoutMetricsRef.layout_class_for_size(viewport_size)
	var tight: bool = layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	var horizontal_margin := UiLayoutMetricsRef.screen_margin_horizontal(layout_class)
	var vertical_margin := UiLayoutMetricsRef.screen_margin_vertical(layout_class)
	root_margin.offset_left = horizontal_margin
	root_margin.offset_top = vertical_margin
	root_margin.offset_right = -horizontal_margin
	root_margin.offset_bottom = -vertical_margin
	var menu_half_width: float = 190.0 if tight else 210.0
	var menu_half_height: float = 176.0 if tight else 190.0
	menu_panel.offset_left = -menu_half_width
	menu_panel.offset_top = -menu_half_height
	menu_panel.offset_right = menu_half_width
	menu_panel.offset_bottom = menu_half_height
	var menu_margin_size: int = UiLayoutMetricsRef.shell_padding(layout_class)
	menu_margin.add_theme_constant_override("margin_left", menu_margin_size)
	menu_margin.add_theme_constant_override("margin_top", menu_margin_size)
	menu_margin.add_theme_constant_override("margin_right", menu_margin_size)
	menu_margin.add_theme_constant_override("margin_bottom", menu_margin_size)
	menu_vbox.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class))
	start_button.custom_minimum_size.y = UiLayoutMetricsRef.primary_button_height(layout_class)
	for button in [armory_button, options_button, credits_button, quit_button]:
		button.custom_minimum_size.y = UiLayoutMetricsRef.secondary_button_height(layout_class)
	for hero_label in [eyebrow_label, title_label, subtitle_label, hero_callout]:
		hero_label.visible = not tight
	title_label.add_theme_font_size_override("font_size", int(round((40.0 if tight else 50.0) * font_scale)))
	menu_title.add_theme_font_size_override("font_size", int(round((24.0 if tight else 28.0) * font_scale)))
	subtitle_label.add_theme_font_size_override("font_size", int(round((15.0 if tight else 18.0) * font_scale)))
	for button in [start_button, armory_button, options_button, credits_button, quit_button]:
		button.add_theme_font_size_override("font_size", int(round((15.0 if tight else 16.0) * font_scale)))
