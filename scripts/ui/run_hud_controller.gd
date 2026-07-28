extends Control

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")
const ONBOARDING_HINT_MIN_SECONDS := 4.0
const ONBOARDING_HINT_MAX_SECONDS := 8.0

@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var boss_manager_path: NodePath = NodePath("../../BossManager")
@export var wave_intermission_panel_path: NodePath
@export var shop_panel_path: NodePath
@export var level_up_panel_path: NodePath
@export var character_select_layer_path: NodePath
@export var stats_label_path: NodePath
@export var state_label_path: NodePath
@export var wave_progress_bar_path: NodePath

var player: Node
var enemy_spawner: Node
var boss_manager: Node
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
@onready var onboarding_hint_panel: PanelContainer = $OnboardingHintPanel
@onready var onboarding_hint_label: Label = $OnboardingHintPanel/HintMargin/HintLabel

var onboarding_hint_elapsed := 0.0
var onboarding_movement_seen := false
var onboarding_hint_active := true

func _ready() -> void:
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if enemy_spawner_path != NodePath():
		enemy_spawner = get_node_or_null(enemy_spawner_path)
	if boss_manager_path != NodePath():
		boss_manager = get_node_or_null(boss_manager_path)
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

func _process(delta: float) -> void:
	_update_hud()
	_update_onboarding_hint(delta)

func _update_onboarding_hint(delta: float) -> void:
	if onboarding_hint_panel == null:
		return
	if not onboarding_hint_active:
		onboarding_hint_panel.visible = false
		return
	var current_wave := int(enemy_spawner.get("current_wave_index")) if enemy_spawner != null else 0
	onboarding_hint_panel.visible = visible and current_wave <= 1
	if not onboarding_hint_panel.visible:
		return
	onboarding_hint_elapsed += delta
	if player != null:
		var velocity_variant: Variant = player.get("velocity")
		if velocity_variant is Vector2:
			var player_velocity: Vector2 = velocity_variant
			onboarding_movement_seen = onboarding_movement_seen or player_velocity.length_squared() > 1.0
	if onboarding_hint_elapsed >= ONBOARDING_HINT_MAX_SECONDS or (
		onboarding_movement_seen and onboarding_hint_elapsed >= ONBOARDING_HINT_MIN_SECONDS
	):
		onboarding_hint_active = false
		onboarding_hint_panel.visible = false

func _update_hud() -> void:
	if player == null or enemy_spawner == null:
		return
	var hud_visible := not _is_character_select_open() and _get_run_state() == "Combat"
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
		stats_label.text = "W%02d   HP %.0f   G %d   LV %d   XP %d/%d" % [wave, hp, gold, level, xp, xp_to_next]
	_refresh_state_panel(player_snapshot)
	_refresh_progress_panel()

func _refresh_progress_panel() -> void:
	if wave_progress_bar == null or progress_caption == null:
		return
	var active_boss := _get_active_boss()
	if active_boss != null:
		progress_caption.text = _boss_display_name(active_boss).to_upper()
		var max_hp := maxf(float(active_boss.get("max_hp")), 1.0)
		var current_hp := clampf(float(active_boss.get("current_hp")), 0.0, max_hp)
		wave_progress_bar.value = (current_hp / max_hp) * 100.0
		wave_progress_bar.visible = true
		return
	var current_wave := int(enemy_spawner.get("current_wave_index"))
	progress_caption.text = "FINAL FRONTIER" if current_wave >= 10 else "FRONTIER PRESSURE"
	var elapsed := float(enemy_spawner.get("wave_elapsed_seconds"))
	var duration := maxf(float(enemy_spawner.get("wave_duration_seconds")), 0.01)
	var ratio := clampf(elapsed / duration, 0.0, 1.0)
	wave_progress_bar.value = ratio * 100.0
	wave_progress_bar.visible = true

func _get_active_boss() -> Node:
	if boss_manager == null or not is_instance_valid(boss_manager):
		return null
	var boss_variant: Variant = boss_manager.get("active_boss")
	if boss_variant is Node:
		var boss_node := boss_variant as Node
		if is_instance_valid(boss_node):
			return boss_node
	return null

func _boss_display_name(active_boss: Node) -> String:
	var variant_id := str(active_boss.get("enemy_variant")).strip_edges()
	if variant_id == "":
		return "Boss"
	return variant_id.replace("_", " ").capitalize()

func _refresh_state_panel(player_snapshot: Dictionary) -> void:
	if state_panel == null or state_label == null:
		return
	var focus_label := _build_focus_label(player_snapshot)
	state_panel.visible = focus_label != ""
	if focus_label == "":
		return
	state_label.text = focus_label

func _build_focus_label(player_snapshot: Dictionary) -> String:
	var passive_label := _build_passive_state_label(player_snapshot)
	if passive_label != "":
		return passive_label
	var counts_variant: Variant = player_snapshot.get("weapon_tag_counts", {})
	if not (counts_variant is Dictionary):
		return ""
	var counts: Dictionary = counts_variant
	var tags: Array = counts.keys()
	tags.sort()
	var best_tag := ""
	var best_count := 0
	for tag_variant in tags:
		var tag := str(tag_variant).strip_edges()
		var count := int(counts.get(tag_variant, 0))
		if tag == "" or count <= best_count:
			continue
		best_tag = tag
		best_count = count
	if best_tag == "" or best_count <= 0:
		return ""
	return "%s ×%d" % [best_tag.replace("_", " ").to_upper(), best_count]

func _build_passive_state_label(player_snapshot: Dictionary) -> String:
	var states_variant: Variant = player_snapshot.get("passive_runtime_states", [])
	if not (states_variant is Array):
		return ""
	for state_variant in states_variant:
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant
		var label := str(state.get("label", "")).strip_edges().to_upper()
		if label == "":
			continue
		if str(state.get("phase", "")) == "active":
			return "%s %.1fs" % [label, maxf(float(state.get("remaining", 0.0)), 0.0)]
		return "%s %d/%d" % [
			label,
			maxi(int(state.get("value", 0)), 0),
			maxi(int(state.get("max_value", 1)), 1)
		]
	return ""

func _apply_presentation() -> void:
	for panel in [stats_panel, progress_panel, state_panel]:
		InfernalUiStyleRef.apply_panel(panel, InfernalUiStyleRef.PANEL_CARD)
	stats_caption.visible = false
	state_caption.visible = false
	InfernalUiStyleRef.apply_text_role(progress_caption, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(stats_label, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(state_label, InfernalUiStyleRef.TEXT_VALUE)
	InfernalUiStyleRef.apply_panel(onboarding_hint_panel, InfernalUiStyleRef.PANEL_CARD)
	InfernalUiStyleRef.apply_text_role(onboarding_hint_label, InfernalUiStyleRef.TEXT_HINT)
	InfernalUiStyleRef.apply_progress_bar(wave_progress_bar)

func _apply_responsive_layout() -> void:
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var tight := layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var compact := layout_class == UiLayoutMetricsRef.LayoutClass.COMPACT
	var horizontal_margin := 8 if tight else 10
	if top_margin != null:
		top_margin.offset_left = horizontal_margin
		top_margin.offset_top = 6.0
		top_margin.offset_right = -horizontal_margin
		top_margin.offset_bottom = 54.0 if tight else 58.0
	if top_row != null:
		top_row.add_theme_constant_override("separation", 6 if tight else 8)
	var inner_horizontal := 10 if tight else 12
	var inner_vertical := 4 if tight else 5
	for panel_margin in [stats_margin, progress_margin, state_margin]:
		if panel_margin == null:
			continue
		panel_margin.add_theme_constant_override("margin_left", inner_horizontal)
		panel_margin.add_theme_constant_override("margin_top", inner_vertical)
		panel_margin.add_theme_constant_override("margin_right", inner_horizontal)
		panel_margin.add_theme_constant_override("margin_bottom", inner_vertical)
	if stats_vbox != null:
		stats_vbox.add_theme_constant_override("separation", 0)
	if progress_vbox != null:
		progress_vbox.add_theme_constant_override("separation", 2)
	if state_vbox != null:
		state_vbox.add_theme_constant_override("separation", 0)
	if stats_panel != null:
		stats_panel.custom_minimum_size = Vector2(278 if tight else (292 if compact else 310), 44 if tight else 48)
	if progress_panel != null:
		progress_panel.custom_minimum_size = Vector2(300 if tight else (330 if compact else 360), 44 if tight else 48)
	if state_panel != null:
		state_panel.custom_minimum_size = Vector2(128 if tight else (142 if compact else 154), 44 if tight else 48)
	if progress_caption != null:
		progress_caption.add_theme_font_size_override("font_size", 10 if tight else 11)
	if stats_label != null:
		stats_label.add_theme_font_size_override("font_size", 13 if tight else 14)
	if state_label != null:
		state_label.add_theme_font_size_override("font_size", 13 if tight else 14)
	if wave_progress_bar != null:
		wave_progress_bar.custom_minimum_size.y = 14 if tight else 16
	if onboarding_hint_panel != null:
		var hint_width := minf(get_viewport_rect().size.x - 32.0, 900.0)
		onboarding_hint_panel.offset_left = -hint_width * 0.5
		onboarding_hint_panel.offset_right = hint_width * 0.5
	if onboarding_hint_label != null:
		onboarding_hint_label.add_theme_font_size_override("font_size", 12 if tight else 13)

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

func _is_character_select_open() -> bool:
	return character_select_layer != null and character_select_layer.visible
