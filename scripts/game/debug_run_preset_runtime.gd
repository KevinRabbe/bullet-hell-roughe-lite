class_name DebugRunPresetRuntime
extends RefCounted

const PRESET_ORDER: Array[String] = ["normal", "shop_test", "combat_test"]

static func next_preset(current_preset: String) -> String:
	var current_index := PRESET_ORDER.find(current_preset)
	if current_index == -1:
		current_index = 0
	return PRESET_ORDER[(current_index + 1) % PRESET_ORDER.size()]

static func effective_preset(debug_quick_shop_mode: bool, debug_run_preset: String) -> String:
	if not debug_quick_shop_mode:
		return "normal"
	if debug_run_preset == "normal":
		return "shop_test"
	return debug_run_preset

static func wave_duration_for_preset(
	preset: String,
	default_wave_duration_seconds: float,
	debug_wave_duration_seconds: float,
	debug_combat_wave_duration_seconds: float
) -> float:
	match preset:
		"shop_test":
			return maxf(debug_wave_duration_seconds, 1.0)
		"combat_test":
			return maxf(debug_combat_wave_duration_seconds, 1.0)
		_:
			return default_wave_duration_seconds

static func starting_gold_for_preset(
	preset: String,
	debug_starting_gold: int,
	debug_combat_starting_gold: int
) -> int:
	match preset:
		"shop_test":
			return debug_starting_gold
		"combat_test":
			return debug_combat_starting_gold
		_:
			return 0
