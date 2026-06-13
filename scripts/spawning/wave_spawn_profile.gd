extends RefCounted

const DEFAULT_FALLBACK_VARIANT := "imp_runner"

var wave_variant_pools: Array[Dictionary] = []
var elite_config: Dictionary = {}

func load_from_path(config_path: String) -> void:
	wave_variant_pools.clear()
	elite_config = {}
	if not FileAccess.file_exists(config_path):
		_set_default_wave_config()
		return
	var config_text := FileAccess.get_file_as_string(config_path)
	var parsed: Variant = JSON.parse_string(config_text)
	if not (parsed is Dictionary):
		_set_default_wave_config()
		return
	_apply_config(parsed as Dictionary)
	if wave_variant_pools.is_empty():
		_set_default_wave_config()

func get_variant_pool_for_wave(wave_index: int) -> Array:
	var result: Array = []
	for band in wave_variant_pools:
		if wave_index <= int(band.get("max_wave", 9999)):
			var configured: Variant = band.get("variants", [])
			if configured is Array:
				for item in configured:
					if item is Dictionary:
						var entry: Dictionary = (item as Dictionary).duplicate(true)
						if str(entry.get("id", "")) != "":
							result.append(entry)
					else:
						var variant_id := str(item)
						if variant_id != "":
							result.append(variant_id)
			return result
	return result

func get_fallback_variant() -> String:
	return DEFAULT_FALLBACK_VARIANT

func should_apply_elite(current_wave_index: int, variant: String, rng: RandomNumberGenerator) -> bool:
	if current_wave_index < int(elite_config.get("elite_unlock_wave", 9999)):
		return false
	if variant != str(elite_config.get("elite_variant", "husk_brute")):
		return false
	if rng == null:
		return false
	return rng.randf() <= float(elite_config.get("elite_spawn_chance", 0.0))

func get_elite_role() -> String:
	return str(elite_config.get("elite_role", "wave_tank"))

func get_elite_overrides() -> Dictionary:
	var overrides_variant: Variant = elite_config.get("elite_overrides", {})
	if overrides_variant is Dictionary:
		return overrides_variant
	return {}

func _apply_config(config: Dictionary) -> void:
	var pools_variant: Variant = config.get("wave_variant_pools", config.get("waves", []))
	if pools_variant is Array:
		for pool_variant in pools_variant:
			if pool_variant is Dictionary:
				wave_variant_pools.append((pool_variant as Dictionary).duplicate(true))
	wave_variant_pools.sort_custom(_sort_wave_band_order)
	var elite_variant: Variant = config.get("elite", null)
	if elite_variant is Dictionary:
		elite_config = (elite_variant as Dictionary).duplicate(true)
	else:
		elite_config = {
			"elite_unlock_wave": int(config.get("elite_unlock_wave", 5)),
			"elite_spawn_chance": float(config.get("elite_spawn_chance", 0.14)),
			"elite_variant": str(config.get("elite_variant", "husk_brute")),
			"elite_role": str(config.get("elite_role", "wave_tank")),
			"elite_overrides": (config.get("elite_overrides", {}) if config.get("elite_overrides", {}) is Dictionary else {})
		}

func _set_default_wave_config() -> void:
	wave_variant_pools = [
		{"max_wave": 1, "variants": ["imp_runner"]},
		{"max_wave": 2, "variants": ["imp_runner", "husk_brute"]},
		{"max_wave": 3, "variants": ["imp_runner", "husk_brute", "spit_fiend"]},
		{"max_wave": 9999, "variants": ["imp_runner", "husk_brute", "spit_fiend", "skeleton_rifleman"]},
	]
	elite_config = {
		"elite_unlock_wave": 5,
		"elite_spawn_chance": 0.14,
		"elite_variant": "husk_brute",
		"elite_role": "wave_tank",
		"elite_overrides": {"hp_multiplier": 2.0, "damage_multiplier": 1.35, "speed_multiplier": 0.88}
	}

func _sort_wave_band_order(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("max_wave", 9999)) < int(b.get("max_wave", 9999))
