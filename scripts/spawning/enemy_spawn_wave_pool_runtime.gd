class_name EnemySpawnWavePoolRuntime
extends RefCounted

static func load_wave_config(config_path: String) -> Dictionary:
	if not FileAccess.file_exists(config_path):
		push_warning("Wave config missing, using defaults: %s" % config_path)
		return _build_default_config()
	var config_text := FileAccess.get_file_as_string(config_path)
	var parsed: Variant = JSON.parse_string(config_text)
	if not (parsed is Dictionary):
		push_warning("Wave config invalid, using defaults: %s" % config_path)
		return _build_default_config()
	return normalize_wave_config(parsed as Dictionary)

static func normalize_wave_config(config: Dictionary) -> Dictionary:
	var wave_variant_pools := _normalize_wave_variant_pools(config.get("wave_variant_pools", config.get("waves", [])))
	var elite_config := _normalize_elite_config(config)
	if wave_variant_pools.is_empty():
		push_warning("Wave config produced no valid wave pools, using defaults.")
		return _build_default_config()
	return {
		"wave_variant_pools": wave_variant_pools,
		"elite": elite_config
	}

static func build_variant_pool_for_wave(wave_variant_pools: Array[Dictionary], wave_index: int) -> Array:
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

static func pick_variant(rng: RandomNumberGenerator, pool: Array, fallback_variant: String = "imp_runner") -> String:
	if pool.is_empty():
		return fallback_variant
	var variant_ids: Array = []
	var weights: Array[float] = []
	for pool_entry in pool:
		if pool_entry is Dictionary:
			var entry: Dictionary = pool_entry
			var variant_id := str(entry.get("id", ""))
			if variant_id == "":
				continue
			variant_ids.append(variant_id)
			weights.append(maxf(float(entry.get("weight", 1.0)), 0.0))
		else:
			variant_ids.append(str(pool_entry))
			weights.append(1.0)
	if variant_ids.is_empty():
		return fallback_variant
	var selected: Variant = WeightedPicker.pick_value(rng, variant_ids, weights)
	return str(selected if selected != null else fallback_variant)

static func _normalize_wave_variant_pools(pools_variant: Variant) -> Array[Dictionary]:
	var wave_variant_pools: Array[Dictionary] = []
	if pools_variant is Array:
		for pool_variant in pools_variant:
			if pool_variant is Dictionary:
				wave_variant_pools.append((pool_variant as Dictionary).duplicate(true))
	wave_variant_pools.sort_custom(_sort_wave_band_order)
	return wave_variant_pools

static func _normalize_elite_config(config: Dictionary) -> Dictionary:
	var elite_variant: Variant = config.get("elite", null)
	if elite_variant is Dictionary:
		return (elite_variant as Dictionary).duplicate(true)
	var elite_overrides_variant: Variant = config.get("elite_overrides", {})
	var elite_overrides: Dictionary = elite_overrides_variant if elite_overrides_variant is Dictionary else {}
	return {
		"elite_unlock_wave": int(config.get("elite_unlock_wave", 5)),
		"elite_spawn_chance": float(config.get("elite_spawn_chance", 0.14)),
		"elite_variant": str(config.get("elite_variant", "husk_brute")),
		"elite_role": str(config.get("elite_role", "wave_tank")),
		"elite_overrides": elite_overrides
	}

static func _build_default_config() -> Dictionary:
	return {
		"wave_variant_pools": [
			{"max_wave": 1, "variants": ["imp_runner"]},
			{"max_wave": 2, "variants": ["imp_runner", "husk_brute"]},
			{"max_wave": 3, "variants": ["imp_runner", "husk_brute", "spit_fiend"]},
			{"max_wave": 9999, "variants": ["imp_runner", "husk_brute", "spit_fiend", "skeleton_rifleman"]}
		],
		"elite": {
			"elite_unlock_wave": 5,
			"elite_spawn_chance": 0.14,
			"elite_variant": "husk_brute",
			"elite_role": "wave_tank",
			"elite_overrides": {
				"hp_multiplier": 2.0,
				"damage_multiplier": 1.35,
				"speed_multiplier": 0.88
			}
		}
	}

static func _sort_wave_band_order(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("max_wave", 9999)) < int(b.get("max_wave", 9999))
