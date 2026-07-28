extends Control

signal resume_requested
signal options_requested
signal restart_requested
signal main_menu_requested

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const InfernalRitualBackdropRef = preload("res://scripts/ui/components/infernal_ritual_backdrop.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")
const OptionsMenuScene = preload("res://scenes/ui/OptionsMenuStandardized.tscn")
const PauseOptionsMenuScript = preload("res://scripts/ui/pause_options_menu.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const OPTIONS_SCENE_PATH := "res://scenes/ui/OptionsMenuStandardized.tscn"
const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"

@onready var root_margin: MarginContainer = $RootMargin
@onready var panel: PanelContainer = $RootMargin/Panel
@onready var panel_margin: MarginContainer = $RootMargin/Panel/PanelMargin
@onready var panel_vbox: VBoxContainer = $RootMargin/Panel/PanelMargin/PanelVBox
@onready var eyebrow_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/Eyebrow
@onready var title_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/Title
@onready var body_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/Body
@onready var action_row_1: HBoxContainer = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow1
@onready var action_row_2: HBoxContainer = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow2
@onready var resume_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow1/ResumeButton
@onready var options_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow1/OptionsButton
@onready var restart_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow2/RestartButton
@onready var main_menu_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow2/MainMenuButton
@onready var hint_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/HintLabel

var standalone_mode: bool = true
var accessibility_settings: Dictionary = {}
var active_options_menu: Control = null

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	accessibility_settings = AccessibilitySettingsRuntimeRef.apply_saved_settings()
	_apply_shell_panel_style()
	_build_ritual_backdrop()
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

func _build_ritual_backdrop() -> void:
	if panel == null or panel.get_node_or_null("RitualBackdrop") != null:
		return
	var backdrop := InfernalRitualBackdropRef.new() as Control
	backdrop.name = "RitualBackdrop"
	panel.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.move_child(backdrop, 0)

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
	if active_options_menu != null and is_instance_valid(active_options_menu):
		return
	if event.is_action_pressed("pause_game"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_R:
			_on_restart_pressed()

func _on_resume_pressed() -> void:
	emit_signal("resume_requested")
	if standalone_mode:
		queue_free()

func _on_options_pressed() -> void:
	if standalone_mode:
		emit_signal("options_requested")
		get_tree().change_scene_to_file(OPTIONS_SCENE_PATH)
		return
	_show_embedded_options()

func _show_embedded_options() -> void:
	if active_options_menu != null and is_instance_valid(active_options_menu):
		return
	var options_variant: Variant = OptionsMenuScene.instantiate()
	if not (options_variant is Control):
		push_error("Pause options must instantiate as a Control.")
		return
	active_options_menu = options_variant as Control
	active_options_menu.set_script(PauseOptionsMenuScript)
	active_options_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(active_options_menu)
	panel.visible = false
	if active_options_menu.has_signal("close_requested"):
		active_options_menu.connect("close_requested", _close_embedded_options)

func _close_embedded_options() -> void:
	if active_options_menu != null and is_instance_valid(active_options_menu):
		active_options_menu.queue_free()
	active_options_menu = null
	if panel != null:
		panel.visible = true
	if resume_button != null:
		resume_button.grab_focus()

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
	var layout_class: int = UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var tight: bool = layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var compact: bool = layout_class == UiLayoutMetricsRef.LayoutClass.COMPACT
	if root_margin != null:
		var horizontal_margin := UiLayoutMetricsRef.screen_margin_horizontal(layout_class)
		var vertical_margin := UiLayoutMetricsRef.screen_margin_vertical(layout_class)
		root_margin.offset_left = horizontal_margin
		root_margin.offset_top = vertical_margin
		root_margin.offset_right = -horizontal_margin
		root_margin.offset_bottom = -vertical_margin
	if panel_margin != null:
		var shell_padding := UiLayoutMetricsRef.shell_padding(layout_class)
		panel_margin.add_theme_constant_override("margin_left", shell_padding)
		panel_margin.add_theme_constant_override("margin_top", shell_padding)
		panel_margin.add_theme_constant_override("margin_right", shell_padding)
		panel_margin.add_theme_constant_override("margin_bottom", shell_padding)
	if panel_vbox != null:
		panel_vbox.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class) + 6)
	for row in [action_row_1, action_row_2]:
		if row != null:
			row.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class) + 2)
	if eyebrow_label != null:
		eyebrow_label.add_theme_font_size_override("font_size", int(round((16 if tight else (17 if compact else 18)) * font_scale)))
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", int(round((30 if tight else (34 if compact else 42)) * font_scale)))
	if body_label != null:
		body_label.add_theme_font_size_override("font_size", int(round((15 if tight else 17) * font_scale)))
		body_label.custom_minimum_size = Vector2(0, 64 if tight else 80)
	if panel != null:
		panel.custom_minimum_size = Vector2(560 if tight else (640 if compact else 720), 0)
	var button_width: float = 150.0 if tight else (180.0 if compact else 220.0)
	var button_height: float = UiLayoutMetricsRef.secondary_button_height(layout_class)
	for action_button in [resume_button, options_button, restart_button, main_menu_button]:
		if action_button != null:
			action_button.custom_minimum_size = Vector2(button_width, button_height)
			action_button.add_theme_font_size_override("font_size", int(round((15 if tight else 16) * font_scale)))
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", int(round((13 if tight else 15) * font_scale)))

func _apply_action_styles() -> void:
	InfernalUiStyleRef.apply_button(resume_button, InfernalUiStyleRef.BUTTON_PRIMARY)
	InfernalUiStyleRef.apply_button(options_button, InfernalUiStyleRef.BUTTON_SECONDARY)
	InfernalUiStyleRef.apply_button(restart_button, InfernalUiStyleRef.BUTTON_DANGER)
	InfernalUiStyleRef.apply_button(main_menu_button, InfernalUiStyleRef.BUTTON_SECONDARY)
	InfernalUiStyleRef.apply_text_role(eyebrow_label, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(title_label, InfernalUiStyleRef.TEXT_SCREEN_TITLE)
	InfernalUiStyleRef.apply_text_role(body_label, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(hint_label, InfernalUiStyleRef.TEXT_HINT)

func _apply_shell_panel_style() -> void:
	InfernalUiStyleRef.apply_panel(panel, InfernalUiStyleRef.PANEL_MODAL)
