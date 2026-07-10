extends Control

signal retry_requested
signal new_character_requested
signal main_menu_requested

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

var standalone_mode := true
var result_state := {
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
	_apply_responsive_layout()
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

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
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
	result_title_label.text = str(result_state.get("title", "Run Complete"))
	result_summary_label.text = str(result_state.get("summary", ""))
	var lines: Array[String] = []
	var stats_variant: Variant = result_state.get("stats", [])
	if stats_variant is Array:
		for line_variant in stats_variant:
			var line_text := str(line_variant)
			if line_text != "":
				lines.append(line_text)
	result_stats_label.text = "\n".join(lines)

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
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 1440.0
	if root_margin != null:
		root_margin.offset_left = 18.0 if compact else 36.0
		root_margin.offset_top = 16.0 if compact else 34.0
		root_margin.offset_right = -18.0 if compact else -36.0
		root_margin.offset_bottom = -16.0 if compact else -34.0
	if main_panel != null:
		main_panel.custom_minimum_size = Vector2(0, 0)
	if result_title_label != null:
		result_title_label.add_theme_font_size_override("font_size", 40 if compact else 48)
	if retry_button != null:
		retry_button.custom_minimum_size = Vector2(180 if compact else 220, 50 if compact else 54)
	if new_character_button != null:
		new_character_button.custom_minimum_size = Vector2(220 if compact else 260, 50 if compact else 54)
	if main_menu_button != null:
		main_menu_button.custom_minimum_size = Vector2(180 if compact else 220, 50 if compact else 54)
	if result_eyebrow_label != null:
		result_eyebrow_label.add_theme_font_size_override("font_size", 16 if compact else 18)
	if result_summary_label != null:
		result_summary_label.add_theme_font_size_override("font_size", 15 if compact else 17)
	if result_stats_label != null:
		result_stats_label.add_theme_font_size_override("font_size", 15 if compact else 17)
	if action_hint_label != null:
		action_hint_label.add_theme_font_size_override("font_size", 13 if compact else 15)

func _build_result_eyebrow() -> String:
	var title_text := str(result_state.get("title", "Run Complete")).to_lower()
	if "victory" in title_text:
		return "FRONTIER CLEARED"
	if "defeat" in title_text or "game over" in title_text:
		return "RUN ENDED"
	return "RUN RESULTS"
