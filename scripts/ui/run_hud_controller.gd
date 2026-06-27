extends Control

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
		stats_label.text = "Wave %d  HP %.0f  Gold %d  Lv %d  XP %d/%d" % [wave, hp, gold, level, xp, xp_to_next]
	if state_label != null:
		var debug_label := _get_debug_preset_label()
		if debug_label == "" or debug_label == "DebugPreset: normal":
			state_label.text = "State: %s" % _get_run_state()
		else:
			state_label.text = "State: %s  |  %s" % [_get_run_state(), debug_label]
	if wave_progress_bar != null:
		var elapsed := float(enemy_spawner.get("wave_elapsed_seconds"))
		var duration := maxf(float(enemy_spawner.get("wave_duration_seconds")), 0.01)
		var ratio := clampf(elapsed / duration, 0.0, 1.0)
		wave_progress_bar.value = ratio * 100.0
		wave_progress_bar.visible = not _is_shop_open()

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
