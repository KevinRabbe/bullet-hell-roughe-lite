class_name MainGameEventBridgeRuntime
extends RefCounted

const IntermissionRuntime = preload("res://scripts/game/intermission_runtime.gd")
const RunFlowRuntime = preload("res://scripts/game/run_flow_runtime.gd")

static func on_player_died(main_game: Node) -> void:
	main_game.call("_enter_run_end_state", "game_over")

static func on_boss_defeated(main_game: Node) -> void:
	main_game.call("_enter_run_end_state", "victory")

static func begin_intermission(
	main_game: Node,
	wave_panel: Control,
	level_up_panel: Control,
	shop_enabled: bool,
	wave_index: int
) -> String:
	main_game.set("waiting_for_wave_continue", true)
	IntermissionRuntime.begin_intermission(main_game, wave_panel, level_up_panel, shop_enabled)
	return "Wave %d complete. Press Continue to start next wave." % wave_index

static func can_continue_wave(waiting_for_wave_continue: bool) -> bool:
	return waiting_for_wave_continue

static func finish_intermission_action(player: Node) -> String:
	if RunFlowRuntime.has_pending_level_up(player):
		return "open_level_up"
	return "start_next_wave"
