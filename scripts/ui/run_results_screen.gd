extends Control

signal retry_requested
signal new_character_requested
signal main_menu_requested

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MenuFrameRuntimeRef = preload("res://scripts/ui/menu_frame_runtime.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"
const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var root_margin: MarginContainer = $RootMargin
@onready var main_panel: PanelContainer = $RootMargin/RootVBox/MainPanel
@onready var result_eyebrow_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultEyebrow
@onready var result_title_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultTitle
@onready var result_summary_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultSummary
@onready var result_stats_grid: FlowContainer = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/StatsGrid
@onready var action_row: FlowContainer = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow
@onready var retry_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/RetryButton
@onready var new_character_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/NewCharacterButton
@onready var main_menu_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/MainMenuButton
@onready var action_hint_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionHint

var standalone_mode: bool = true
var accessibility_settings: Dictionary = {}
var result_state: Dictionary = {
	"title": "Run Complete",
	"summary": "This screen closes the run cleanly and points you back toward the next frontier decision.",
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
	_apply_shell_styles()
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
			var line_text := _sanitize_stat_line(str(line_variant))
			if line_text != "":
				lines.append(line_text)
	_refresh_stats_grid(lines)
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
	if result_stats_grid != null:
		result_stats_grid.add_theme_constant_override("h_separation", 10 if tight else 14)
		result_stats_grid.add_theme_constant_override("v_separation", 10 if tight else 12)
	if action_row != null:
		action_row.add_theme_constant_override("h_separation", 10 if tight else 14)
		action_row.add_theme_constant_override("v_separation", 10 if tight else 12)
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

func _apply_shell_styles() -> void:
	if main_panel == null:
		return
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.035, 0.055, 0.92)
	panel_style.border_color = Color(0.99, 0.56, 0.56, 0.16)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.corner_radius_bottom_left = 18
	main_panel.add_theme_stylebox_override("panel", panel_style)

func _apply_action_button_style(button: Button, accent: Color, is_primary: bool = false) -> void:
	if button == null:
		return
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	var framed: bool = false
	if is_primary:
		framed = MenuFrameRuntimeRef.apply_button_frame(
			button,
			MenuFrameRuntimeRef.MENU_BUTTON_PRIMARY_PATH,
			Color(1.0, 0.97, 0.97, 1.0),
			Color(1.0, 1.0, 1.0, 1.0)
		)
	else:
		framed = MenuFrameRuntimeRef.apply_button_frame(
			button,
			MenuFrameRuntimeRef.MENU_BUTTON_SECONDARY_PATH,
			Color(0.90, 0.93, 1.0, 0.98),
			Color(1.0, 1.0, 1.0, 1.0)
		)
	if framed:
		return
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
	action_hint_label.text = "Shortcuts: R retry / Enter choose character / Esc main menu." if standalone_mode else "Shortcuts: R retry / Enter choose character / Esc return to main menu."

func _refresh_stats_grid(lines: Array[String]) -> void:
	if result_stats_grid == null:
		return
	for child in result_stats_grid.get_children():
		child.queue_free()
	for line_text in lines:
		result_stats_grid.add_child(_build_stat_card(line_text))

func _build_stat_card(line_text: String) -> PanelContainer:
	var title_text := line_text
	var value_text := "-"
	if line_text.contains(":"):
		var parts := line_text.split(":", false, 1)
		title_text = str(parts[0]).strip_edges()
		value_text = str(parts[1]).strip_edges()
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 96)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.11, 0.86)
	style.border_color = Color(0.99, 0.56, 0.56, 0.18)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	card.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = title_text
	title.modulate = Color(0.76, 0.80, 0.88, 0.92)
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	var value := Label.new()
	value.text = value_text
	value.modulate = Color(0.97, 0.97, 1.0, 1.0)
	value.add_theme_font_size_override("font_size", 24)
	vbox.add_child(value)
	return card

func _sanitize_stat_line(line_text: String) -> String:
	var text := line_text.strip_edges()
	if text == "":
		return ""
	if not text.contains(":"):
		return "" if _is_missing_stat_value(text) else text
	var parts := text.split(":", false, 1)
	var left := str(parts[0]).strip_edges()
	var right := str(parts[1]).strip_edges()
	if left == "":
		return ""
	if _is_missing_stat_value(right):
		right = "-"
	return "%s: %s" % [left, right]

func _is_missing_stat_value(value_text: String) -> bool:
	var normalized: String = value_text.strip_edges().to_lower()
	return normalized == "" or normalized == "null" or normalized == "<null>" or normalized == "nil" or normalized == "<nil>" or normalized == "none" or normalized == "undefined"

func _build_result_eyebrow() -> String:
	var title_text: String = str(result_state.get("title", "Run Complete")).to_lower()
	if "victory" in title_text:
		return "FRONTIER CLEARED"
	if "defeat" in title_text or "game over" in title_text:
		return "RUN ENDED"
	return "RUN RESULTS"
