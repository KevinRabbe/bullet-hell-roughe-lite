class_name MainGameDebugStateRuntime
extends RefCounted

const DebugRunPresetRuntime = preload("res://scripts/game/debug_run_preset_runtime.gd")
const MainGameStartRuntime = preload("res://scripts/game/main_game_start_runtime.gd")

static func apply_debug_quick_shop_preset(
	player: Node,
	enemy_spawner: Node,
	debug_quick_shop_mode: bool,
	debug_run_preset: String,
	default_wave_duration_seconds: float,
	debug_wave_duration_seconds: float,
	debug_combat_wave_duration_seconds: float,
	debug_starting_gold: int,
	debug_combat_starting_gold: int
) -> Dictionary:
	var effective_preset := get_effective_debug_preset(debug_quick_shop_mode, debug_run_preset)
	var starting_gold := get_starting_gold_for_preset(
		effective_preset,
		debug_starting_gold,
		debug_combat_starting_gold
	)
	MainGameStartRuntime.apply_debug_quick_shop_preset(player, effective_preset, starting_gold)
	apply_debug_wave_duration(
		enemy_spawner,
		debug_quick_shop_mode,
		debug_run_preset,
		default_wave_duration_seconds,
		debug_wave_duration_seconds,
		debug_combat_wave_duration_seconds
	)
	return {
		"preset": effective_preset,
		"starting_gold": starting_gold,
		"wave_duration": get_wave_duration_for_preset(
			effective_preset,
			default_wave_duration_seconds,
			debug_wave_duration_seconds,
			debug_combat_wave_duration_seconds
		)
	}

static func apply_debug_wave_duration(
	enemy_spawner: Node,
	debug_quick_shop_mode: bool,
	debug_run_preset: String,
	default_wave_duration_seconds: float,
	debug_wave_duration_seconds: float,
	debug_combat_wave_duration_seconds: float
) -> void:
	var effective_preset := get_effective_debug_preset(debug_quick_shop_mode, debug_run_preset)
	MainGameStartRuntime.set_wave_duration_for_preset(
		enemy_spawner,
		effective_preset,
		default_wave_duration_seconds,
		get_wave_duration_for_preset(
			effective_preset,
			default_wave_duration_seconds,
			debug_wave_duration_seconds,
			debug_combat_wave_duration_seconds
		)
	)

static func cycle_debug_run_preset(current_preset: String) -> Dictionary:
	var next_preset := DebugRunPresetRuntime.next_preset(current_preset)
	return {
		"debug_run_preset": next_preset,
		"debug_quick_shop_mode": next_preset != "normal"
	}

static func get_debug_preset_label(debug_quick_shop_mode: bool, debug_run_preset: String) -> String:
	return "DebugPreset: %s" % get_effective_debug_preset(debug_quick_shop_mode, debug_run_preset)

static func get_effective_debug_preset(debug_quick_shop_mode: bool, debug_run_preset: String) -> String:
	return DebugRunPresetRuntime.effective_preset(debug_quick_shop_mode, debug_run_preset)

static func get_wave_duration_for_preset(
	preset: String,
	default_wave_duration_seconds: float,
	debug_wave_duration_seconds: float,
	debug_combat_wave_duration_seconds: float
) -> float:
	return DebugRunPresetRuntime.wave_duration_for_preset(
		preset,
		default_wave_duration_seconds,
		debug_wave_duration_seconds,
		debug_combat_wave_duration_seconds
	)

static func get_starting_gold_for_preset(
	preset: String,
	debug_starting_gold: int,
	debug_combat_starting_gold: int
) -> int:
	return DebugRunPresetRuntime.starting_gold_for_preset(
		preset,
		debug_starting_gold,
		debug_combat_starting_gold
	)

static func get_current_wave_duration(enemy_spawner: Node, default_wave_duration_seconds: float) -> float:
	if enemy_spawner != null:
		return float(enemy_spawner.get("wave_duration_seconds"))
	return default_wave_duration_seconds
