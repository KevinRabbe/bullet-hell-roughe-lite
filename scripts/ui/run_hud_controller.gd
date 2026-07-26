extends Control

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var wave_intermission_panel_path: NodePath
@export var shop_panel_path: NodePath
@export var level_up_panel_path: NodePath
@export var character_select_layer_path: NodePath
@export var stats_label_path: NodePath
@export var state_label_path: NodePath
@export var wave_progress_bar_path: NodePath

var player: Node
var enemy_spawner: Node
var wave_intermission_panel: Control
var shop_panel: Control
var level_up_panel: Control
var character_select_layer: CanvasLayer
var stats_label: Label
var state_label: Label
var wave_progress_bar: ProgressBar

@onready var top_margin: MarginContainer = $TopMargin
@onready var top_row: HBoxContainer = $TopMargin/TopRow
@onready var stats_panel: PanelContainer = $TopMargin/TopRow/StatsPanel
@onready var progress_panel: PanelContainer = $TopMargin/TopRow/ProgressPanel
@onready var state_panel: PanelContainer = $TopMargin/TopRow/StatePanel
@onready var stats_margin: MarginContainer = $TopMargin/TopRow/StatsPanel/StatsMargin
@onready var progress_margin: MarginContainer = $TopMargin/TopRow/ProgressPanel/ProgressMargin
@onready var state_margin: MarginContainer = $TopMargin/TopRow/StatePanel/StateMargin
@onready var stats_vbox: VBoxContainer = $TopMargin/TopRow/StatsPanel/StatsMargin/StatsVBox
@onready var progress_vbox: VBoxContainer = $TopMargin/TopRow/ProgressPanel/ProgressMargin/ProgressVBox
@onready var state_vbox: VBoxContainer = $TopMargin/TopRow/StatePanel/StateMargin/StateVBox
@onready var stats_caption: Label = $TopMargin/TopRow/StatsPanel/StatsMargin/StatsVBox/StatsCaption
@onready var progress_caption: Label = $TopMargin/TopRow/ProgressPanel/ProgressMargin/ProgressVBox/ProgressCaption
@onready var state_caption: Label = $TopMargin/TopRow/StatePanel/StateMargin/StateVBox/StateCaption

func _ready() -> void:
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if enemy_spawner_path != NodePath():
		enemy_spawner = get_node_or_null(enemy_spawner_path)
	if wave_intermission_panel_path != NodePath():
		wave_intermission_panel = get_node_or_null(wave_intermission_panel_path)
	if shop_panel_path != NodePath():
		shop_panel = get_node_or_null(shop_panel_path)
	if level_up_panel_path != NodePath():
		level_up_panel = get_node_or_null(level_up_panel_path)
	if character_select_layer_path != NodePath():
		character_select_layer = get_node_or_null(character_select_layer_path)
	if stats_label_path != NodePath():
		stats_label = get_node_or_null(stats_label_path)
	if state_label_path != NodePath():
		state_label = get_node_or_null(state_label_path)
	if wave_progress_bar_path != NodePath():
		wave_progress_bar = get_node_or_null(wave_progress_bar_path)
	_apply_presentation()
	_apply_responsive_layout()
	resized.connect(_apply_responsive_layout)
	_update_hud()

func _process(_delta: float) -> void:
	_update_hud()

func _update_hud() -> void:
	if player == null or enemy_spawner == null:
		return
	var hud_visible := not _is_character_select_open()
	visible = hud_visible
	if not hud_visible:
		return
	var player_snapshot := _get_player_snapshot()
	if stats_label != null:
		var hp := float(player_snapshot.get("hp", 0.0))
		var gold := int(player_snapshot.get("gold", 0))
		var level := int(player_snapshot.get("level", 1))
		var xp := int(player_snapshot.get("xp", 0))
		var xp_to_next := int(player_snapshot.get("xp_to_next", 1))
		var wave := int(enemy_spawner.get("current_wave_index"))
		stats_label.text = "WAVE %02d  HP %.0f  GOLD %d  LV %d  XP %d/%d" % [wave, hp, gold, level, xp, xp_to_next]
	if state_label != null:
		var debug_label := _get_debug_preset_label()
		if debug_label == "" or debug_label == "DebugPreset: normal":
			state_label.text = _get_run_state().to_upper()
		else:
			state_label.text = "%s  |  %s" % [_get_run_state().to_upper(), debug_label]
	if wave_progress_bar != null:
		var elapsed := float(enemy_spawner.get("wave_elapsed_seconds"))
		var duration := maxf(float(enemy_spawner.get("wave_duration_seconds")), 0.01)
		var ratio := clampf(elapsed / duration, 0.0, 1.0)
		wave_progress_bar.value = ratio * 100.0
		wave_progress_bar.visible = not _is_shop_open()

func _apply_presentation() -> void:
	for panel in [stats_panel, progress_panel, state_panel]:
		InfernalUiStyleRef.apply_panel(panel, InfernalUiStyleRef.PANEL_CARD)
	for caption in [stats_caption, progress_caption, state_caption]:
		InfernalUiStyleRef.apply_text_role(caption, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(stats_label, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(state_label, InfernalUiStyleRef.TEXT_VALUE)
	InfernalUiStyleRef.apply_progress_bar(wave_progress_bar)

func _apply_responsive_layout() -> void:
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var tight := layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var compact := layout_class == UiLayoutMetricsRef.LayoutClass.COMPACT
	var horizontal_margin := UiLayoutMetricsRef.section_padding(layout_class)
	var vertical_margin := UiLayoutMetricsRef.dense_gap(layout_class) + 8
	if top_margin != null:
		top_margin.offset_left = horizontal_margin
		top_margin.offset_top = vertical_margin
		top_margin.offset_right = -horizontal_margin
		top_margin.offset_bottom = 82.0 if tight else 88.0
	if top_row != null:
		top_row.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class))
	var inner_horizontal := UiLayoutMetricsRef.section_padding(layout_class)
	var inner_vertical := UiLayoutMetricsRef.dense_gap(layout_class) + 4
	for panel_margin in [stats_margin, progress_margin, state_margin]:
		if panel_margin == null:
			continue
		panel_margin.add_theme_constant_override("margin_left", inner_horizontal)
		panel_margin.add_theme_constant_override("margin_top", inner_vertical)
		panel_margin.add_theme_constant_override("margin_right", inner_horizontal)
		panel_margin.add_theme_constant_override("margin_bottom", inner_vertical)
	if stats_vbox != null:
		stats_vbox.add_theme_constant_override("separation", 1)
	if progress_vbox != null:
		progress_vbox.add_theme_constant_override("separation", UiLayoutMetricsRef.dense_gap(layout_class))
	if state_vbox != null:
		state_vbox.add_theme_constant_override("separation", 1)
	if stats_panel != null:
		stats_panel.custom_minimum_size = Vector2(330 if tight else (350 if compact else 380), 64 if tight else 68)
	if progress_panel != null:
		progress_panel.custom_minimum_size = Vector2(340 if tight else (360 if compact else 400), 64 if tight else 68)
	if state_panel != null:
		state_panel.custom_minimum_size = Vector2(170 if tight else (185 if compact else 200), 64 if tight else 68)
	for caption in [stats_caption, progress_caption, state_caption]:
		if caption != null:
			caption.add_theme_font_size_override("font_size", 11 if tight else 12)
	if stats_label != null:
		stats_label.add_theme_font_size_override("font_size", 15 if tight else 16)
	if state_label != null:
		state_label.add_theme_font_size_override("font_size", 15 if tight else 16)
	if wave_progress_bar != null:
		wave_progress_bar.custom_minimum_size.y = 22 if tight else 24

func _get_player_snapshot() -> Dictionary:
	if player != null and player.has_method("get_ui_snapshot"):
		var snapshot_variant: Variant = player.call("get_ui_snapshot")
		if snapshot_variant is Dictionary:
			return snapshot_variant
	return {}

func _get_run_state() -> String:
	if level_up_panel != null and level_up_panel.visible:
		return "Level Up"
	if shop_panel != null and shop_panel.visible:
		return "Shop"
	if wave_intermission_panel != null and wave_intermission_panel.visible:
		return "Intermission"
	return "Combat"

func _is_shop_open() -> bool:
	return shop_panel != null and shop_panel.visible

func _is_character_select_open() -> bool:
	return character_select_layer != null and character_select_layer.visible

func _get_debug_preset_label() -> String:
	var main_game := get_tree().current_scene
	if main_game != null and main_game.has_method("get_debug_preset_label"):
		return str(main_game.call("get_debug_preset_label"))
	return "DebugPreset: normal"
