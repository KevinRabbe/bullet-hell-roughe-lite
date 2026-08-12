class_name EnemySpawnWavePoolRuntime
extends RefCounted

static func read_wave_config(config_path: String) -> Dictionary:
	if not FileAccess.file_exists(config_path):
		push_warning("Wave config missing: %s" % config_path)
		return {}
	var config_text := FileAccess.get_file_as_string(config_path)
	var parsed: Variant = JSON.parse_string(config_text)
	if not (parsed is Dictionary):
		push_warning("Wave config invalid: %s" % config_path)
		return {}
	return (parsed as Dictionary).duplicate(true)

static func load_wave_config(config_path: String) -> Dictionary:
	var config := read_wave_config(config_path)
	if config.is_empty():
		push_warning("Using default wave config: %s" % config_path)
		return _build_default_config()
	return normalize_wave_config(config)

static func normalize_wave_config(config: Dictionary) -> Dictionary:
	var wave_variant_pools := _normalize_wave_variant_pools(config.get("wave_variant_pools", config.get("waves", [])))
	var pressure_bands := _normalize_pressure_bands(config.get("pressure_bands", []))
	var elite_config := _normalize_elite_config(config)
	if wave_variant_pools.is_empty():
		push_warning("Wave config produced no valid wave pools, using defaults.")
		return _build_default_config()
	if pressure_bands.is_empty():
		pressure_bands = _default_pressure_bands()
	return {
		"wave_variant_pools": wave_variant_pools,
		"pressure_bands": pressure_bands,
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

static func get_pressure_band_for_wave(pressure_bands: Array[Dictionary], wave_index: int) -> Dictionary:
	for band in pressure_bands:
		if wave_index < int(band.get("min_wave", 1)):
			continue
		if wave_index <= int(band.get("max_wave", 9999)):
			return band.duplicate(true)
	return {
		"id": "neutral",
		"min_wave": wave_index,
		"max_wave": wave_index,
		"spawn_interval_multiplier": 1.0,
		"enemy_hp_multiplier": 1.0,
		"enemy_damage_multiplier": 1.0,
		"elite_chance_multiplier": 1.0
	}

static func get_wave_runtime_overrides_for_wave(
	wave_variant_pools: Array[Dictionary],
	wave_index: int
) -> Dictionary:
	for pool in wave_variant_pools:
		if wave_index > int(pool.get("max_wave", 9999)):
			continue
		var overrides: Dictionary = {}
		for field_name in ["spawn_interval_multiplier", "max_alive_enemies", "elite_chance_multiplier"]:
			if pool.has(field_name):
				overrides[field_name] = pool[field_name]
		return overrides
	return {}

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

static func _normalize_pressure_bands(bands_variant: Variant) -> Array[Dictionary]:
	var pressure_bands: Array[Dictionary] = []
	if bands_variant is Array:
		for band_variant in bands_variant:
			if not (band_variant is Dictionary):
				continue
			var band: Dictionary = band_variant
			var min_wave := maxi(int(band.get("min_wave", 1)), 1)
			var max_wave := maxi(int(band.get("max_wave", min_wave)), min_wave)
			pressure_bands.append({
				"id": str(band.get("id", "")).strip_edges(),
				"min_wave": min_wave,
				"max_wave": max_wave,
				"spawn_interval_multiplier": maxf(float(band.get("spawn_interval_multiplier", 1.0)), 0.05),
				"max_alive_enemies": maxi(int(band.get("max_alive_enemies", 1)), 1),
				"enemy_hp_multiplier": maxf(float(band.get("enemy_hp_multiplier", 1.0)), 0.05),
				"enemy_damage_multiplier": maxf(float(band.get("enemy_damage_multiplier", 1.0)), 0.0),
				"elite_chance_multiplier": maxf(float(band.get("elite_chance_multiplier", 1.0)), 0.0)
			})
	pressure_bands.sort_custom(_sort_pressure_band_order)
	return pressure_bands

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

static func _default_pressure_bands() -> Array[Dictionary]:
	return [
		{"id": "opening", "min_wave": 1, "max_wave": 5, "spawn_interval_multiplier": 1.0, "max_alive_enemies": 25, "enemy_hp_multiplier": 1.0, "enemy_damage_multiplier": 1.0, "elite_chance_multiplier": 1.0},
		{"id": "escalation", "min_wave": 6, "max_wave": 10, "spawn_interval_multiplier": 0.92, "max_alive_enemies": 28, "enemy_hp_multiplier": 1.08, "enemy_damage_multiplier": 1.05, "elite_chance_multiplier": 1.15},
		{"id": "distortion", "min_wave": 11, "max_wave": 15, "spawn_interval_multiplier": 0.84, "max_alive_enemies": 31, "enemy_hp_multiplier": 1.16, "enemy_damage_multiplier": 1.10, "elite_chance_multiplier": 1.35},
		{"id": "collapse", "min_wave": 16, "max_wave": 20, "spawn_interval_multiplier": 0.76, "max_alive_enemies": 34, "enemy_hp_multiplier": 1.25, "enemy_damage_multiplier": 1.16, "elite_chance_multiplier": 1.55}
	]

static func _build_default_config() -> Dictionary:
	return {
		"wave_variant_pools": [
			{"max_wave": 1, "variants": ["imp_runner"]},
			{"max_wave": 2, "variants": ["imp_runner", "husk_brute"]},
			{"max_wave": 3, "variants": ["imp_runner", "husk_brute", "spit_fiend"]},
			{"max_wave": 9999, "variants": ["imp_runner", "husk_brute", "spit_fiend", "skeleton_rifleman"]}
		],
		"pressure_bands": _default_pressure_bands(),
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

static func _sort_pressure_band_order(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("min_wave", 1)) < int(b.get("min_wave", 1))
