extends RefCounted

var rng: RandomNumberGenerator
var stat_ids: Array[String] = []
var stat_display_names: Dictionary = {}
var rarity_weights: Dictionary = {}
var rarity_values_by_stat: Dictionary = {}
var active_choices: Array[Dictionary] = []
var reroll_count: int = 0
var base_reroll_cost: int = 2

func configure(
	configured_rng: RandomNumberGenerator,
	configured_stat_ids: Array[String],
	configured_display_names: Dictionary,
	configured_rarity_weights: Dictionary,
	configured_rarity_values_by_stat: Dictionary,
	configured_base_reroll_cost: int
) -> void:
	rng = configured_rng
	stat_ids = configured_stat_ids.duplicate()
	stat_display_names = configured_display_names.duplicate(true)
	rarity_weights = configured_rarity_weights.duplicate(true)
	rarity_values_by_stat = configured_rarity_values_by_stat.duplicate(true)
	base_reroll_cost = configured_base_reroll_cost

func open_session() -> void:
	reroll_count = 0
	roll_choices()

func roll_choices() -> void:
	active_choices.clear()
	if rng == null or stat_ids.is_empty():
		return
	for _slot in 4:
		var stat_index := rng.randi_range(0, stat_ids.size() - 1)
		var stat_id := stat_ids[stat_index]
		active_choices.append(_build_choice(stat_id))

func current_reroll_cost() -> int:
	return base_reroll_cost + reroll_count

func mark_reroll_paid() -> void:
	reroll_count += 1
	roll_choices()

func get_choices() -> Array[Dictionary]:
	return active_choices

func get_choice(index: int) -> Dictionary:
	if index < 0 or index >= active_choices.size():
		return {}
	return active_choices[index]

func _build_choice(stat_id: String) -> Dictionary:
	var rarity := _roll_rarity_name()
	var value := _get_rarity_value(stat_id, rarity)
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

func _roll_rarity_name() -> String:
	var roll := rng.randf()
	var threshold := 0.0
	for rarity_name in ["Common", "Rare", "Epic", "Legendary"]:
		threshold += float(rarity_weights.get(rarity_name, 0.0))
		if roll <= threshold:
			return rarity_name
	return "Common"

func _get_rarity_value(stat_id: String, rarity_name: String) -> float:
	var stat_entry_variant: Variant = rarity_values_by_stat.get(stat_id, {})
	if stat_entry_variant is Dictionary:
		var stat_entry: Dictionary = stat_entry_variant
		return float(stat_entry.get(rarity_name, 0.0))
	return 0.0
