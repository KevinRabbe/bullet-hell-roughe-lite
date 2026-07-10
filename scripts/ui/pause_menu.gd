extends Control

signal resume_requested
signal options_requested
signal restart_requested
signal main_menu_requested

const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const OPTIONS_SCENE_PATH := "res://scenes/ui/OptionsMenu.tscn"
const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"

@onready var root_margin: MarginContainer = $RootMargin
@onready var panel: PanelContainer = $RootMargin/Panel
@onready var title_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/Title
@onready var body_label: Label = $RootMargin/Panel/PanelMargin/PanelVBox/Body
@onready var resume_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow1/ResumeButton
@onready var options_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow1/OptionsButton
@onready var restart_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow2/RestartButton
@onready var main_menu_button: Button = $RootMargin/Panel/PanelMargin/PanelVBox/ActionRow2/MainMenuButton

var standalone_mode := true

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	_apply_responsive_layout()
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

func configure_copy(title: String, body: String) -> void:
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = body

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
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
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 1440.0
	if root_margin != null:
		root_margin.offset_left = 18.0 if compact else 36.0
		root_margin.offset_top = 16.0 if compact else 34.0
		root_margin.offset_right = -18.0 if compact else -36.0
		root_margin.offset_bottom = -16.0 if compact else -34.0
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 34 if compact else 42)
	if panel != null:
		panel.custom_minimum_size = Vector2(0, 0)
	if resume_button != null:
		resume_button.custom_minimum_size = Vector2(180 if compact else 220, 50 if compact else 54)
	if options_button != null:
		options_button.custom_minimum_size = Vector2(180 if compact else 220, 50 if compact else 54)
	if restart_button != null:
		restart_button.custom_minimum_size = Vector2(180 if compact else 220, 50 if compact else 54)
	if main_menu_button != null:
		main_menu_button.custom_minimum_size = Vector2(180 if compact else 220, 50 if compact else 54)
