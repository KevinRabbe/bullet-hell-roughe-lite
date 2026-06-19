class_name LevelUpRuntime
extends RefCounted

const RARITY_NAMES: Array[String] = ["Common", "Rare", "Epic", "Legendary"]
const DEFAULT_STAT_IDS: Array[String] = ["damage", "attack_speed", "max_hp", "movement_speed", "armor"]
const DEFAULT_RARITY_WEIGHTS: Dictionary = {
	"Common": 0.65,
	"Rare": 0.25,
	"Epic": 0.08,
	"Legendary": 0.02
}
const DEFAULT_RARITY_VALUES_BY_STAT: Dictionary = {
	"damage": {"Common": 0.05, "Rare": 0.12, "Epic": 0.22, "Legendary": 0.40},
	"attack_speed": {"Common": 0.05, "Rare": 0.10, "Epic": 0.18, "Legendary": 0.30},
	"max_hp": {"Common": 10.0, "Rare": 25.0, "Epic": 45.0, "Legendary": 75.0},
	"movement_speed": {"Common": 10.0, "Rare": 25.0, "Epic": 40.0, "Legendary": 65.0},
	"armor": {"Common": 1.0, "Rare": 3.0, "Epic": 5.0, "Legendary": 9.0}
}
const DEFAULT_STAT_DISPLAY_NAMES: Dictionary = {
	"damage": "Damage",
	"attack_speed": "Attack Speed",
	"max_hp": "Max HP",
	"movement_speed": "Move Speed",
	"armor": "Armor"
}

static func build_choices(
	rng: RandomNumberGenerator,
	stat_ids: Array[String] = DEFAULT_STAT_IDS,
	rarity_weights: Dictionary = DEFAULT_RARITY_WEIGHTS,
	rarity_values_by_stat: Dictionary = DEFAULT_RARITY_VALUES_BY_STAT,
	stat_display_names: Dictionary = DEFAULT_STAT_DISPLAY_NAMES,
	count: int = 4
) -> Array[Dictionary]:
	var active_choices: Array[Dictionary] = []
	if rng == null or stat_ids.is_empty():
		return active_choices
	for _slot in count:
		var stat_index := rng.randi_range(0, stat_ids.size() - 1)
		var stat_id := stat_ids[stat_index]
		active_choices.append(
			build_choice(
				rng,
				stat_id,
				rarity_weights,
				rarity_values_by_stat,
				stat_display_names
			)
		)
	return active_choices

static func build_choice(
	rng: RandomNumberGenerator,
	stat_id: String,
	rarity_weights: Dictionary = DEFAULT_RARITY_WEIGHTS,
	rarity_values_by_stat: Dictionary = DEFAULT_RARITY_VALUES_BY_STAT,
	stat_display_names: Dictionary = DEFAULT_STAT_DISPLAY_NAMES
) -> Dictionary:
	var rarity := roll_rarity_name(rng, rarity_weights)
	var value := get_rarity_value(stat_id, rarity, rarity_values_by_stat)
	var display_name := str(stat_display_names.get(stat_id, stat_id))
	var formatted_value := "%+.0f" % value
	if stat_id == "damage" or stat_id == "attack_speed":
		formatted_value = "%+.0f%%" % (value * 100.0)
	return {
		"id": stat_id,
		"value": value,
		"rarity": rarity,
		"label": "[%s] %s %s" % [rarity, display_name, formatted_value]
	}

static func roll_rarity_name(
	rng: RandomNumberGenerator,
	rarity_weights: Dictionary = DEFAULT_RARITY_WEIGHTS
) -> String:
	if rng == null:
		return "Common"
	var roll := rng.randf()
	var threshold := 0.0
	for rarity_name in RARITY_NAMES:
		threshold += float(rarity_weights.get(rarity_name, 0.0))
		if roll <= threshold:
			return rarity_name
	return "Common"

static func get_rarity_value(
	stat_id: String,
	rarity_name: String,
	rarity_values_by_stat: Dictionary = DEFAULT_RARITY_VALUES_BY_STAT
) -> float:
	var stat_entry_variant: Variant = rarity_values_by_stat.get(stat_id, {})
	if stat_entry_variant is Dictionary:
		var stat_entry: Dictionary = stat_entry_variant
		return float(stat_entry.get(rarity_name, 0.0))
	return 0.0
