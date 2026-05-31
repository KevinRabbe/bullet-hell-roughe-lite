extends Control

@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var wave_intermission_panel_path: NodePath
@export var shop_panel_path: NodePath
@export var level_up_panel_path: NodePath
@export var stats_label_path: NodePath
@export var state_label_path: NodePath

var player: Node
var enemy_spawner: Node
var wave_intermission_panel: Control
var shop_panel: Control
var level_up_panel: Control
var stats_label: Label
var state_label: Label

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
	if stats_label_path != NodePath():
		stats_label = get_node_or_null(stats_label_path)
	if state_label_path != NodePath():
		state_label = get_node_or_null(state_label_path)
	_update_hud()

func _process(_delta: float) -> void:
	_update_hud()

func _update_hud() -> void:
	if player == null or enemy_spawner == null:
		return
	if stats_label != null:
		var hp := float(player.get("current_hp"))
		var gold := int(player.get("current_gold"))
		var level := int(player.get("current_level"))
		var xp := int(player.get("current_xp"))
		var xp_to_next := int(player.get("xp_to_next_level"))
		var wave := int(enemy_spawner.get("current_wave_index"))
		stats_label.text = "Wave %d  HP %.0f  Gold %d  Lv %d  XP %d/%d" % [wave, hp, gold, level, xp, xp_to_next]
	if state_label != null:
		state_label.text = "State: %s" % _get_run_state()

func _get_run_state() -> String:
	if level_up_panel != null and level_up_panel.visible:
		return "Level Up"
	if shop_panel != null and shop_panel.visible:
		return "Shop"
	if wave_intermission_panel != null and wave_intermission_panel.visible:
		return "Intermission"
	return "Combat"
