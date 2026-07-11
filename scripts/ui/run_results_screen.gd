extends Control

signal retry_requested
signal new_character_requested
signal main_menu_requested

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"
const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var root_margin: MarginContainer = $RootMargin
@onready var main_panel: PanelContainer = $RootMargin/RootVBox/MainPanel
@onready var result_eyebrow_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultEyebrow
@onready var result_title_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultTitle
@onready var result_summary_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultSummary
@onready var result_stats_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultStats
@onready var retry_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/RetryButton
@onready var new_character_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/NewCharacterButton
@onready var main_menu_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/MainMenuButton
@onready var action_hint_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionHint

var standalone_mode: bool = true
var accessibility_settings: Dictionary = {}
var result_state: Dictionary = {
	"title": "Run Complete",
	"summary": "Use this shell for victory and defeat handoff once the in-run results flow is wired.",
	"stats": [
		"Wave reached: -",
		"Gold earned: -",
		"Build focus: -"
	]
}

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	accessibility_settings = AccessibilitySettingsRuntimeRef.apply_saved_settings()
	_apply_responsive_layout()
	_apply_action_styles()
	_refresh()
	MenuAnimationRuntimeRef.play_screen_intro([main_panel])
	resized.connect(_apply_responsive_layout)
	if retry_button != null:
		retry_button.pressed.connect(_on_retry_pressed)
	if new_character_button != null:
		new_character_button.pressed.connect(_on_new_character_pressed)
	if main_menu_button != null:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func set_standalone_mode(enabled: bool) -> void:
	standalone_mode = enabled
	_refresh_action_hint()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_R:
			_on_retry_pressed()
		KEY_ENTER, KEY_SPACE:
			_on_new_character_pressed()
		KEY_ESCAPE:
			_on_main_menu_pressed()

func apply_result_state(next_state: Dictionary) -> void:
	result_state = {
		"title": str(next_state.get("title", result_state["title"])),
		"summary": str(next_state.get("summary", result_state["summary"])),
		"stats": next_state.get("stats", result_state["stats"])
	}
	_refresh()

func _refresh() -> void:
	if result_eyebrow_label != null:
		result_eyebrow_label.text = _build_result_eyebrow()
	if result_title_label != null:
		result_title_label.text = str(result_state.get("title", "Run Complete"))
	if result_summary_label != null:
		result_summary_label.text = str(result_state.get("summary", ""))
	var lines: Array[String] = []
	var stats_variant: Variant = result_state.get("stats", [])
	if stats_variant is Array:
		for line_variant in stats_variant:
			var line_text := str(line_variant)
			if line_text != "":
				lines.append(line_text)
	if result_stats_label != null:
		result_stats_label.text = "\n".join(lines)
	_refresh_action_hint()

func _on_retry_pressed() -> void:
	emit_signal("retry_requested")
	if standalone_mode:
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_new_character_pressed() -> void:
	emit_signal("new_character_requested")
	if standalone_mode:
		get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)

func _on_main_menu_pressed() -> void:
	emit_signal("main_menu_requested")
	if standalone_mode:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _apply_responsive_layout() -> void:
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x < 1440.0
	var tight: bool = viewport_size.x < 1280.0 or viewport_size.y < 720.0
	if root_margin != null:
		root_margin.offset_left = 10.0 if tight else (18.0 if compact else 36.0)
		root_margin.offset_top = 10.0 if tight else (16.0 if compact else 34.0)
		root_margin.offset_right = -10.0 if tight else (-18.0 if compact else -36.0)
		root_margin.offset_bottom = -10.0 if tight else (-16.0 if compact else -34.0)
	if main_panel != null:
		main_panel.custom_minimum_size = Vector2(560 if tight else 720, 0)
	if result_eyebrow_label != null:
		result_eyebrow_label.add_theme_font_size_override("font_size", int(round((15 if tight else (16 if compact else 18)) * font_scale)))
		result_eyebrow_label.modulate = Color(1.0, 0.76, 0.76, 0.98) if high_contrast else Color(0.992157, 0.560784, 0.560784, 0.95)
	if result_title_label != null:
		result_title_label.add_theme_font_size_override("font_size", int(round((34 if tight else (40 if compact else 48)) * font_scale)))
	if result_summary_label != null:
		result_summary_label.add_theme_font_size_override("font_size", int(round((14 if tight else (15 if compact else 17)) * font_scale)))
		result_summary_label.modulate = Color(0.94, 0.96, 1.0, 0.98) if high_contrast else Color(0.84, 0.86, 0.91, 0.94)
	if result_stats_label != null:
		result_stats_label.add_theme_font_size_override("font_size", int(round((14 if tight else (15 if compact else 17)) * font_scale)))
		result_stats_label.modulate = Color(0.90, 0.92, 0.98, 0.98) if high_contrast else Color(0.80, 0.84, 0.90, 0.95)
	var button_size := Vector2(150 if tight else (180 if compact else 220), 46 if tight else (50 if compact else 54))
	for action_button in [retry_button, new_character_button, main_menu_button]:
		if action_button != null:
			action_button.custom_minimum_size = button_size
			action_button.add_theme_font_size_override("font_size", int(round((15 if tight else 16) * font_scale)))
	if action_hint_label != null:
		action_hint_label.add_theme_font_size_override("font_size", int(round((13 if tight else (13 if compact else 15)) * font_scale)))
		action_hint_label.modulate = Color(0.86, 0.90, 0.98, 0.98) if high_contrast else Color(0.75, 0.79, 0.86, 0.88)

func _apply_action_styles() -> void:
	_apply_action_button_style(retry_button, Color(0.96, 0.72, 0.33, 1.0), true)
	_apply_action_button_style(new_character_button, Color(0.62, 0.73, 1.0, 1.0))
	_apply_action_button_style(main_menu_button, Color(0.99, 0.56, 0.56, 1.0))

func _apply_action_button_style(button: Button, accent: Color, is_primary: bool = false) -> void:
	if button == null:
		return
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	if is_primary:
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.26 if not high_contrast else 0.36)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.92 if high_contrast else 0.72)
	else:
		style.bg_color = Color(0.04, 0.045, 0.07, 0.98) if high_contrast else Color(0.0509804, 0.054902, 0.0862745, 0.92)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.44 if high_contrast else 0.24)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _refresh_action_hint() -> void:
	if action_hint_label == null:
		return
	action_hint_label.text = "Shortcuts: R retry, Enter new character, Esc main menu." if standalone_mode else "Shortcuts: R retry, Enter new character, Esc return to main menu."

func _build_result_eyebrow() -> String:
	var title_text: String = str(result_state.get("title", "Run Complete")).to_lower()
	if "victory" in title_text:
		return "FRONTIER CLEARED"
	if "defeat" in title_text or "game over" in title_text:
		return "RUN ENDED"
	return "RUN RESULTS"
