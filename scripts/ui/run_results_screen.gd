extends Control

signal retry_requested
signal new_character_requested
signal main_menu_requested

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")
const StandardStatCardScene = preload("res://scenes/ui/components/StandardStatCard.tscn")
const RunPlaytestReportRuntimeRef = preload("res://scripts/game/run_playtest_report_runtime.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"
const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var root_margin: MarginContainer = $RootMargin
@onready var main_panel: PanelContainer = $RootMargin/RootVBox/MainPanel
@onready var main_margin: MarginContainer = $RootMargin/RootVBox/MainPanel/MainMargin
@onready var main_vbox: VBoxContainer = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox
@onready var result_eyebrow_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultEyebrow
@onready var result_title_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultTitle
@onready var result_summary_label: Label = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ResultSummary
@onready var result_stats_grid: FlowContainer = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/StatsGrid
@onready var action_row: FlowContainer = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow
@onready var retry_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/RetryButton
@onready var new_character_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/NewCharacterButton
@onready var copy_report_button: Button = $RootMargin/RootVBox/MainPanel/MainMargin/MainVBox/ActionRow/CopyReportButton
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
var _playtest_identity_applied: bool = false
var _playtest_report_text: String = ""

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
	if copy_report_button != null:
		copy_report_button.pressed.connect(_on_copy_report_pressed)
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
	_append_playtest_identity()
	_refresh()

func _append_playtest_identity() -> void:
	if _playtest_identity_applied:
		return
	var game_scene := get_parent()
	if game_scene == null:
		return
	var player := game_scene.get_node_or_null("Player")
	if player == null or not player.has_method("get_ui_snapshot"):
		return
	var snapshot_variant: Variant = player.call("get_ui_snapshot")
	if not (snapshot_variant is Dictionary):
		return
	var player_snapshot: Dictionary = snapshot_variant
	var existing_stats: Array[String] = []
	var stats_variant: Variant = result_state.get("stats", [])
	if stats_variant is Array:
		for line_variant in stats_variant:
			var line := str(line_variant).strip_edges()
			if line != "":
				existing_stats.append(line)
	var run_rng := get_node_or_null("/root/RunRng")
	var identity_lines := RunPlaytestReportRuntimeRef.build_identity_lines(run_rng, player, player_snapshot)
	identity_lines.append_array(existing_stats)
	result_state["stats"] = identity_lines
	var enemy_spawner := game_scene.get_node_or_null("EnemySpawner")
	var wave_index := int(enemy_spawner.get("current_wave_index")) if enemy_spawner != null else 0
	_playtest_report_text = RunPlaytestReportRuntimeRef.build_report(
		_result_id(),
		run_rng,
		player,
		player_snapshot,
		wave_index
	)
	print(_playtest_report_text)
	_playtest_identity_applied = true

func _result_id() -> String:
	var title := str(result_state.get("title", "")).to_lower()
	if "victory" in title:
		return "victory"
	if "defeat" in title or "game over" in title:
		return "game_over"
	return "complete"

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
	if copy_report_button != null:
		copy_report_button.disabled = _playtest_report_text == ""

func _on_retry_pressed() -> void:
	emit_signal("retry_requested")
	if standalone_mode:
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_new_character_pressed() -> void:
	emit_signal("new_character_requested")
	if standalone_mode:
		get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)

func _on_copy_report_pressed() -> void:
	if _playtest_report_text == "":
		return
	DisplayServer.clipboard_set(_playtest_report_text)
	if copy_report_button != null:
		copy_report_button.text = "Report Copied"
	if action_hint_label != null:
		action_hint_label.text = "Exact run report copied. Paste it into the bug report with your screenshot."

func _on_main_menu_pressed() -> void:
	emit_signal("main_menu_requested")
	if standalone_mode:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _apply_responsive_layout() -> void:
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
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
	if main_margin != null:
		var padding := UiLayoutMetricsRef.shell_padding(layout_class)
		main_margin.add_theme_constant_override("margin_left", padding)
		main_margin.add_theme_constant_override("margin_top", padding)
		main_margin.add_theme_constant_override("margin_right", padding)
		main_margin.add_theme_constant_override("margin_bottom", padding)
	if main_vbox != null:
		main_vbox.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class) + 6)
	if main_panel != null:
		main_panel.custom_minimum_size = Vector2(560 if tight else (640 if compact else 720), 0)
	if result_eyebrow_label != null:
		result_eyebrow_label.add_theme_font_size_override("font_size", int(round((15 if tight else (16 if compact else 18)) * font_scale)))
		result_eyebrow_label.modulate = Color(1.0, 0.76, 0.76, 0.98) if high_contrast else Color.WHITE
	if result_title_label != null:
		result_title_label.add_theme_font_size_override("font_size", int(round((34 if tight else (40 if compact else 48)) * font_scale)))
	if result_summary_label != null:
		result_summary_label.add_theme_font_size_override("font_size", int(round((14 if tight else (15 if compact else 17)) * font_scale)))
	if result_stats_grid != null:
		result_stats_grid.add_theme_constant_override("h_separation", UiLayoutMetricsRef.row_gap(layout_class) + 2)
		result_stats_grid.add_theme_constant_override("v_separation", UiLayoutMetricsRef.row_gap(layout_class))
	if action_row != null:
		action_row.add_theme_constant_override("h_separation", UiLayoutMetricsRef.row_gap(layout_class) + 2)
		action_row.add_theme_constant_override("v_separation", UiLayoutMetricsRef.row_gap(layout_class))
	var button_width := 138.0 if tight else (154.0 if compact else 170.0)
	var button_height := UiLayoutMetricsRef.secondary_button_height(layout_class)
	for action_button in [retry_button, new_character_button, copy_report_button, main_menu_button]:
		if action_button != null:
			action_button.custom_minimum_size = Vector2(button_width, button_height)
			action_button.add_theme_font_size_override("font_size", int(round((14 if tight else 15) * font_scale)))
	if action_hint_label != null:
		action_hint_label.add_theme_font_size_override("font_size", int(round((13 if tight else (13 if compact else 15)) * font_scale)))

func _apply_action_styles() -> void:
	InfernalUiStyleRef.apply_button(retry_button, InfernalUiStyleRef.BUTTON_PRIMARY)
	InfernalUiStyleRef.apply_button(new_character_button, InfernalUiStyleRef.BUTTON_SECONDARY)
	InfernalUiStyleRef.apply_button(copy_report_button, InfernalUiStyleRef.BUTTON_SECONDARY)
	InfernalUiStyleRef.apply_button(main_menu_button, InfernalUiStyleRef.BUTTON_SECONDARY)

func _apply_shell_styles() -> void:
	if main_panel == null:
		return
	InfernalUiStyleRef.apply_panel(main_panel, InfernalUiStyleRef.PANEL_MODAL)
	InfernalUiStyleRef.apply_text_role(result_eyebrow_label, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(result_title_label, InfernalUiStyleRef.TEXT_SCREEN_TITLE)
	InfernalUiStyleRef.apply_text_role(result_summary_label, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(action_hint_label, InfernalUiStyleRef.TEXT_HINT)

func _refresh_action_hint() -> void:
	if action_hint_label == null:
		return
	action_hint_label.text = "Use Copy Report when sending a playtest bug report."

func _refresh_stats_grid(lines: Array[String]) -> void:
	if result_stats_grid == null:
		return
	for child in result_stats_grid.get_children():
		child.queue_free()
	for line_text in lines:
		result_stats_grid.add_child(_build_stat_card(line_text))

func _build_stat_card(line_text: String) -> Control:
	var title_text := line_text
	var value_text := "-"
	if line_text.contains(":"):
		var parts := line_text.split(":", false, 1)
		title_text = str(parts[0]).strip_edges()
		value_text = str(parts[1]).strip_edges()
	var card_variant: Variant = StandardStatCardScene.instantiate()
	if not (card_variant is Control):
		var fallback := Label.new()
		fallback.text = "%s: %s" % [title_text, value_text]
		InfernalUiStyleRef.apply_text_role(fallback, InfernalUiStyleRef.TEXT_BODY)
		return fallback
	var card := card_variant as Control
	if card.has_method("configure"):
		card.call("configure", title_text, value_text)
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
