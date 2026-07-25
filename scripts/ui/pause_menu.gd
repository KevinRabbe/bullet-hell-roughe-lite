extends Control

signal resume_requested
signal options_requested
signal restart_requested
signal main_menu_requested

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const OPTIONS_SCENE_PATH := "res://scenes/ui/OptionsMenu.tscn"
const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"

@onready var root_margin: MarginContainer = $RootMargin
@onready var panel: PanelContainer = $RootMargin/Panel
@onready var eyebrow_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/Eyebrow
@onready var title_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/Title
@onready var body_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/Body
@onready var resume_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow1/ResumeButton
@onready var options_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow1/OptionsButton
@onready var restart_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow2/RestartButton
@onready var main_menu_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow2/MainMenuButton
@onready var hint_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/HintLabel

var standalone_mode: bool = true
var accessibility_settings: Dictionary = {}

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	accessibility_settings = AccessibilitySettingsRuntimeRef.apply_saved_settings()
	_apply_shell_panel_style()
	_apply_responsive_layout()
	_apply_action_styles()
	_refresh_hint_copy()
	MenuAnimationRuntimeRef.play_screen_intro([panel])
	resized.connect(_apply_responsive_layout)
	if resume_button != null:
		resume_button.pressed.connect(_on_resume_pressed)
	if options_button != null:
		options_button.pressed.connect(_on_options_pressed)
	if restart_button != null:
		restart_button.pressed.connect(_on_restart_pressed)
	if main_menu_button != null:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if resume_button != null:
		resume_button.grab_focus()

func set_standalone_mode(enabled: bool) -> void:
	standalone_mode = enabled
	_refresh_hint_copy()

func configure_copy(title: String, body: String) -> void:
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = body

func _refresh_hint_copy() -> void:
	if hint_label == null:
		return
	hint_label.text = "Hotkeys: Esc Resume, R Restart" if not standalone_mode else "Hotkeys: Esc Resume, R Restart, Enter activates focus"

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_ESCAPE:
			_on_resume_pressed()
		KEY_R:
			_on_restart_pressed()

func _on_resume_pressed() -> void:
	emit_signal("resume_requested")
	if standalone_mode:
		queue_free()

func _on_options_pressed() -> void:
	emit_signal("options_requested")
	if standalone_mode:
		get_tree().change_scene_to_file(OPTIONS_SCENE_PATH)

func _on_restart_pressed() -> void:
	emit_signal("restart_requested")
	if standalone_mode:
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_main_menu_pressed() -> void:
	emit_signal("main_menu_requested")
	if standalone_mode:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _apply_responsive_layout() -> void:
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x < 1440.0
	var tight: bool = viewport_size.x < 1280.0 or viewport_size.y < 720.0
	if root_margin != null:
		root_margin.offset_left = 10.0 if tight else (18.0 if compact else 36.0)
		root_margin.offset_top = 10.0 if tight else (16.0 if compact else 34.0)
		root_margin.offset_right = -10.0 if tight else (-18.0 if compact else -36.0)
		root_margin.offset_bottom = -10.0 if tight else (-16.0 if compact else -34.0)
	if eyebrow_label != null:
		eyebrow_label.add_theme_font_size_override("font_size", int(round((16 if compact else 18) * font_scale)))
		eyebrow_label.modulate = Color.WHITE
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", int(round((30 if tight else (34 if compact else 42)) * font_scale)))
	if body_label != null:
		body_label.add_theme_font_size_override("font_size", int(round((15 if tight else 17) * font_scale)))
		body_label.modulate = Color.WHITE
		body_label.custom_minimum_size = Vector2(0, 64 if tight else 80)
	if panel != null:
		panel.custom_minimum_size = Vector2(560 if tight else 720, 0)
	if resume_button != null:
		resume_button.custom_minimum_size = Vector2(150 if tight else (180 if compact else 220), 46 if tight else (50 if compact else 54))
		resume_button.add_theme_font_size_override("font_size", int(round((15 if tight else 16) * font_scale)))
	if options_button != null:
		options_button.custom_minimum_size = Vector2(150 if tight else (180 if compact else 220), 46 if tight else (50 if compact else 54))
		options_button.add_theme_font_size_override("font_size", int(round((15 if tight else 16) * font_scale)))
	if restart_button != null:
		restart_button.custom_minimum_size = Vector2(150 if tight else (180 if compact else 220), 46 if tight else (50 if compact else 54))
		restart_button.add_theme_font_size_override("font_size", int(round((15 if tight else 16) * font_scale)))
	if main_menu_button != null:
		main_menu_button.custom_minimum_size = Vector2(150 if tight else (180 if compact else 220), 46 if tight else (50 if compact else 54))
		main_menu_button.add_theme_font_size_override("font_size", int(round((15 if tight else 16) * font_scale)))
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", int(round((13 if tight else 15) * font_scale)))
		hint_label.modulate = Color.WHITE

func _apply_action_styles() -> void:
	InfernalUiStyleRef.apply_primary_button(resume_button)
	for button in [options_button, restart_button, main_menu_button]:
		InfernalUiStyleRef.apply_secondary_button(button)
	InfernalUiStyleRef.apply_section_title(eyebrow_label)
	InfernalUiStyleRef.apply_title(title_label)
	InfernalUiStyleRef.apply_body_text(body_label)
	InfernalUiStyleRef.apply_body_text(hint_label)

func _apply_shell_panel_style() -> void:
	InfernalUiStyleRef.apply_panel(panel, InfernalUiStyleRef.PANEL_SHELL)
