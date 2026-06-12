extends Node

var player_facade: Node
var _stats: StatBlock = StatBlock.new()

func configure(next_player_facade: Node) -> void:
	player_facade = next_player_facade

func get_stats() -> StatBlock:
	return _stats

func set_stats(next_stats: StatBlock) -> void:
	_stats = next_stats if next_stats != null else StatBlock.new()

func reset_to_debug_defaults(starting_hp: float, move_speed: float) -> void:
	_stats = StatBlock.new()
	_stats.max_hp = starting_hp
	_stats.movement_speed = move_speed
	_stats.burn_damage = 1.0
	_stats.poison_damage = 1.0
	_stats.bleed_damage = 1.0
	_stats.frost_power = 1.0
	_stats.portal_frequency = 1.0
	_stats.portal_luck = 0.0
	_stats.portal_instability = 0.0

func has_stat_property(stat_name: String) -> bool:
	for property_info in _stats.get_property_list():
		if str(property_info.get("name", "")) == stat_name:
			return true
	return false

func get_stat_value(stat_name: String, fallback: float) -> float:
	if has_stat_property(stat_name):
		return float(_stats.get(stat_name))
	return fallback

func apply_item_effects(item: ItemData) -> void:
	for stat_name in item.stat_modifiers.keys():
		if not has_stat_property(stat_name):
			continue
		var current_value: Variant = _stats.get(stat_name)
		var modifier: Variant = item.stat_modifiers[stat_name]
		if current_value is float and modifier is float:
			_stats.set(stat_name, current_value + modifier)
		elif current_value is int and modifier is int:
			_stats.set(stat_name, current_value + modifier)

func apply_runtime_stat_bonus(stat_id: String, value: float) -> void:
	if stat_id == "max_hp":
		_stats.max_hp += value
		return
	if not has_stat_property(stat_id):
		return
	var current_value: Variant = _stats.get(stat_id)
	if current_value is float:
		_stats.set(stat_id, float(current_value) + value)
	elif current_value is int:
		_stats.set(stat_id, int(current_value) + int(round(value)))

func apply_level_up_bonus(stat_id: String, value: float) -> void:
	if stat_id == "max_hp":
		_stats.max_hp += value
		return
	if not has_stat_property(stat_id):
		return
	var current_value: Variant = _stats.get(stat_id)
	if current_value is float:
		_stats.set(stat_id, float(current_value) + value)
	elif current_value is int:
		_stats.set(stat_id, int(current_value) + int(value))

func apply_stat_multipliers(stat_multipliers_variant: Variant) -> void:
	if not (stat_multipliers_variant is Dictionary):
		return
	var stat_multipliers: Dictionary = stat_multipliers_variant
	for stat_name in stat_multipliers.keys():
		var stat_name_string: String = str(stat_name)
		if not has_stat_property(stat_name_string):
			continue
		var current_value: Variant = _stats.get(stat_name_string)
		var multiplier: float = float(stat_multipliers[stat_name])
		if current_value is float:
			_stats.set(stat_name_string, float(current_value) * multiplier)
		elif current_value is int:
			_stats.set(stat_name_string, int(round(float(current_value) * multiplier)))

func apply_stat_bonuses(stat_bonuses_variant: Variant) -> void:
	if not (stat_bonuses_variant is Dictionary):
		return
	var stat_bonuses: Dictionary = stat_bonuses_variant
	for stat_name in stat_bonuses.keys():
		var stat_name_string: String = str(stat_name)
		if not has_stat_property(stat_name_string):
			continue
		var current_value: Variant = _stats.get(stat_name_string)
		var bonus: float = float(stat_bonuses[stat_name])
		if current_value is float:
			_stats.set(stat_name_string, float(current_value) + bonus)
		elif current_value is int:
			_stats.set(stat_name_string, int(current_value) + int(round(bonus)))

func debug_add_stat_bonus(stat_id: String, value: float) -> bool:
	if not has_stat_property(stat_id):
		return false
	var current_value: Variant = _stats.get(stat_id)
	if current_value is float:
		_stats.set(stat_id, float(current_value) + value)
	elif current_value is int:
		_stats.set(stat_id, int(current_value) + int(value))
	return true
