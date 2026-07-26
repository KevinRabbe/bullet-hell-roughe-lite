class_name DebugRunPresetRuntime
extends RefCounted

const PRESET_ORDER: Array[String] = [
	"normal",
	"shop_test",
	"combat_test",
	"compact_arena",
	"large_arena",
	"wave_5_gate_beast",
	"wave_10_victory"
]

const SCENARIO_DEFINITIONS: Dictionary = {
	"normal": {
		"label": "Wave 1 Baseline",
		"wave_index": 1,
		"arena_size_class": "standard",
		"boss_id": ""
	},
	"shop_test": {
		"label": "Full Shop",
		"wave_index": 1,
		"arena_size_class": "standard",
		"boss_id": ""
	},
	"combat_test": {
		"label": "Combat Test",
		"wave_index": 1,
		"arena_size_class": "standard",
		"boss_id": ""
	},
	"compact_arena": {
		"label": "Compact Arena",
		"wave_index": 1,
		"arena_size_class": "compact",
		"boss_id": ""
	},
	"large_arena": {
		"label": "Large Arena",
		"wave_index": 1,
		"arena_size_class": "large",
		"boss_id": ""
	},
	"wave_5_gate_beast": {
		"label": "Wave 5 Gate Beast",
		"wave_index": 5,
		"arena_size_class": "standard",
		"boss_id": "gate_beast"
	},
	"wave_10_victory": {
		"label": "Wave 10 Victory",
		"wave_index": 10,
		"arena_size_class": "standard",
		"boss_id": ""
	}
}

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

static func scenario_definition(preset: String) -> Dictionary:
	var definition_variant: Variant = SCENARIO_DEFINITIONS.get(preset, SCENARIO_DEFINITIONS["normal"])
	return (definition_variant as Dictionary).duplicate(true) if definition_variant is Dictionary else {}

static func scenario_label(preset: String) -> String:
	return str(scenario_definition(preset).get("label", preset))

static func wave_index_for_preset(preset: String) -> int:
	return maxi(int(scenario_definition(preset).get("wave_index", 1)), 1)

static func boss_id_for_preset(preset: String) -> String:
	return str(scenario_definition(preset).get("boss_id", ""))

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

static func arena_size_class_for_preset(preset: String) -> String:
	return str(scenario_definition(preset).get("arena_size_class", "standard"))
