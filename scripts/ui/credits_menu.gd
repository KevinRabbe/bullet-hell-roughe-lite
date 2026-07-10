extends Control

const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"

@onready var root_margin: MarginContainer = $RootMargin
@onready var main_panel: PanelContainer = $RootMargin/RootVBox/MainPanel
@onready var eyebrow_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/Eyebrow
@onready var title_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/Title
@onready var summary_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/Summary
@onready var back_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/BackButton

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	_apply_responsive_layout()
	MenuAnimationRuntimeRef.play_screen_intro([main_panel])
	resized.connect(_apply_responsive_layout)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
		back_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 1440.0
	var tight := viewport_size.x < 1280.0 or viewport_size.y < 720.0
	if root_margin != null:
		root_margin.offset_left = 10.0 if tight else (18.0 if compact else 36.0)
		root_margin.offset_top = 10.0 if tight else (16.0 if compact else 34.0)
		root_margin.offset_right = -10.0 if tight else (-18.0 if compact else -36.0)
		root_margin.offset_bottom = -10.0 if tight else (-16.0 if compact else -34.0)
	if main_panel != null:
		main_panel.custom_minimum_size = Vector2(0, 480 if tight else 540)
	if eyebrow_label != null:
		eyebrow_label.add_theme_font_size_override("font_size", 16 if compact else 18)
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 34 if tight else (38 if compact else 44))
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", 15 if tight else 17)
	if back_button != null:
		back_button.custom_minimum_size = Vector2(150 if tight else (180 if compact else 220), 46 if tight else (50 if compact else 54))
