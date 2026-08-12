class_name ContentValidator
extends RefCounted

const WeaponTagRuntimeRef = preload("res://scripts/weapons/weapon_tag_runtime.gd")
const WeaponAttackPatternRuntimeRef = preload("res://scripts/weapons/weapon_attack_pattern_runtime.gd")
const PortalMutationRuntimeRef = preload("res://scripts/portal/portal_mutation_runtime.gd")
const PortalRiskRewardRuntimeRef = preload("res://scripts/portal/portal_risk_reward_runtime.gd")
const RunProgressionRuntimeRef = preload("res://scripts/game/run_progression_runtime.gd")
const BossManagerRuntimeRef = preload("res://scripts/game/boss_manager_runtime.gd")
const EnemySpawnWavePoolRuntimeRef = preload("res://scripts/spawning/enemy_spawn_wave_pool_runtime.gd")
const EnemyCombatProfileRuntimeRef = preload("res://scripts/enemies/enemy_combat_profile_runtime.gd")
const ShopOfferRuntimeRef = preload("res://scripts/game/shop_offer_runtime.gd")
const StatBlockRef = preload("res://scripts/core/stat_block.gd")
const PlayerPassiveRuntimeRef = preload("res://scripts/player/player_passive_runtime.gd")
const CombatScaleSpecRef = preload("res://scripts/visual/combat_scale_spec.gd")

const EXPECTED_SELECTABLE_HUNTERS := 10
const SUPPORTED_RARITIES: Array[String] = ["common", "rare", "epic", "legendary"]
const REQUIRED_SET_THRESHOLDS: Array[int] = [2, 4, 6]
const SUPPORTED_MUTATION_TIERS: Array[String] = ["minor", "major"]
const SUPPORTED_DURATIONS: Array[String] = ["event", "wave", "run"]
const SUPPORTED_VICTORY_CONDITIONS: Array[String] = ["arena_clear", "boss_defeat"]
const SUPPORTED_ENEMY_MOVEMENT_PROFILES: Array[String] = ["chaser", "ranged_slow", "ranged_hold"]
const REQUIRED_BOSS_MILESTONES: Dictionary = {
	5: "gate_beast",
	10: "cinder_marshal",
	15: "pyre_archon",
	20: "last_shade"
}
const REQUIRED_PRESSURE_BAND_RANGES: Dictionary = {
	"opening": Vector2i(1, 5),
	"escalation": Vector2i(6, 10),
	"distortion": Vector2i(11, 15),
	"collapse": Vector2i(16, 20)
}
const REQUIRED_SHOP_RARITY_MAX_WAVES: Array[int] = [2, 5, 9, 14, 20]
const REQUIRED_EXPLICIT_WAVE_POOL_MAX_WAVES: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]

static func validate_registry(
	registry: Node,
	run_progression: Dictionary = {},
	wave_spawn_config: Dictionary = {},
	shop_config: Dictionary = {}
) -> Dictionary:
	var issues: Array[Dictionary] = []
	if registry == null:
		_add_error(issues, "registry_missing", "registry", "", "DataRegistry is unavailable.")
		return _build_report(issues, {})

	_validate_registry_load_failures(issues, registry)
	var characters := _dictionary_property(registry, "characters")
	var weapons := _dictionary_property(registry, "weapons")
	var items := _dictionary_property(registry, "items")
	var enemies := _dictionary_property(registry, "enemies")
	var portal_events := _dictionary_property(registry, "portal_events")
	var portal_mutations := _dictionary_property(registry, "portal_mutations")
	var ascensions := _dictionary_property(registry, "ascensions")
	var set_bonuses := _dictionary_property(registry, "set_bonuses")

	_validate_characters(issues, characters, weapons, set_bonuses)
	_validate_weapons(issues, weapons)
	_validate_items(issues, items, weapons)
	_validate_enemies(issues, enemies)
	_validate_portal_events(issues, portal_events)
	_validate_effect_definitions(issues, "portal_mutation", portal_mutations, true)
	_validate_effect_definitions(issues, "ascension", ascensions, false)
	_validate_set_bonuses(issues, set_bonuses)
	_validate_run_progression(issues, run_progression, enemies)
	_validate_wave_spawn_config(issues, wave_spawn_config, enemies, run_progression)
	_validate_shop_config(issues, shop_config, run_progression)

	return _build_report(issues, {
		"characters": characters.size(),
		"weapons": weapons.size(),
		"items": items.size(),
		"enemies": enemies.size(),
		"portal_events": portal_events.size(),
		"portal_mutations": portal_mutations.size(),
		"ascensions": ascensions.size(),
		"set_bonuses": set_bonuses.size(),
		"run_progressions": 0 if run_progression.is_empty() else 1,
		"wave_spawn_configs": 0 if wave_spawn_config.is_empty() else 1,
		"shop_configs": 0 if shop_config.is_empty() else 1
	})

static func _validate_registry_load_failures(issues: Array[Dictionary], registry: Node) -> void:
	var failures_variant: Variant = registry.get("load_failures")
	if not (failures_variant is Array):
		return
	for failure_variant in failures_variant:
		if not (failure_variant is Dictionary):
			_add_error(issues, "registry_load_failure_type", "registry", "", "DataRegistry reported an invalid load-failure payload.")
			continue
		var failure: Dictionary = failure_variant
		var failure_path := str(failure.get("path", "")).strip_edges()
		var failure_code := str(failure.get("code", "registry_load_failure")).strip_edges()
		var failure_message := str(failure.get("message", "Content source failed to load.")).strip_edges()
		_add_error(
			issues,
			failure_code if failure_code != "" else "registry_load_failure",
			"registry",
			failure_path,
			failure_message
		)

static func _validate_run_progression(
	issues: Array[Dictionary],
	progression: Dictionary,
	enemies: Dictionary
) -> void:
	const CATEGORY := "run_progression"
	var progression_id := str(progression.get("id", "")).strip_edges()
	if progression.is_empty():
		_add_error(issues, "run_progression_missing", CATEGORY, "", "Run progression is missing or invalid.")
		return
	if progression_id == "":
		_add_error(issues, "run_progression_id", CATEGORY, "", "Run progression is missing id.")

	var total_waves := int(progression.get("total_waves", 0))
	if total_waves <= 0:
		_add_error(issues, "run_progression_total_waves", CATEGORY, progression_id, "total_waves must be positive.")

	var milestone_waves: Array[int] = []
	var milestone_ids: Dictionary = {}
	var milestone_bosses_by_wave: Dictionary = {}
	var milestones_variant: Variant = progression.get("milestones", [])
	if not (milestones_variant is Array):
		_add_error(issues, "run_progression_milestones_type", CATEGORY, progression_id, "milestones must be an array.")
	else:
		for milestone_variant in milestones_variant:
			if not (milestone_variant is Dictionary):
				_add_error(issues, "run_progression_milestone_type", CATEGORY, progression_id, "milestones contains a non-dictionary entry.")
				continue
			var milestone: Dictionary = milestone_variant
			var milestone_id := str(milestone.get("id", "")).strip_edges()
			var milestone_wave := int(milestone.get("wave", 0))
			if milestone_id == "":
				_add_error(issues, "run_progression_milestone_id", CATEGORY, progression_id, "Milestone is missing id.")
			elif milestone_ids.has(milestone_id):
				_add_error(issues, "run_progression_duplicate_milestone_id", CATEGORY, milestone_id, "Milestone id is duplicated.")
			milestone_ids[milestone_id] = true
			if milestone_wave <= 0 or (total_waves > 0 and milestone_wave > total_waves):
				_add_error(issues, "run_progression_milestone_wave", CATEGORY, milestone_id, "Milestone wave must be inside the configured run.")
			elif milestone_waves.has(milestone_wave):
				_add_error(issues, "run_progression_duplicate_milestone_wave", CATEGORY, milestone_id, "Only one milestone may own a wave.")
			else:
				milestone_waves.append(milestone_wave)
			var milestone_type := str(milestone.get("type", "")).strip_edges()
			if milestone_type == "boss":
				var boss_id := str(milestone.get("boss_id", "")).strip_edges()
				if boss_id == "":
					_add_error(issues, "run_progression_boss_id", CATEGORY, milestone_id, "Boss milestone is missing boss_id.")
				else:
					milestone_bosses_by_wave[milestone_wave] = boss_id
					if not enemies.has(boss_id):
						_add_error(issues, "run_progression_boss_missing", CATEGORY, milestone_id, "Boss milestone references unknown enemy '%s'." % boss_id)
					elif _value(enemies[boss_id], "is_boss", false) != true:
						_add_error(issues, "run_progression_enemy_not_boss", CATEGORY, milestone_id, "Enemy '%s' is not configured as a boss." % boss_id)
					if BossManagerRuntimeRef.get_boss_definition(boss_id).is_empty():
						_add_error(issues, "run_progression_boss_runtime_missing", CATEGORY, milestone_id, "Boss '%s' has no BossManager runtime definition." % boss_id)
				var completion := str(milestone.get("completion", "")).strip_edges()
				if completion not in RunProgressionRuntimeRef.SUPPORTED_MILESTONE_COMPLETIONS:
					_add_error(issues, "run_progression_boss_completion", CATEGORY, milestone_id, "Unsupported boss completion '%s'." % completion)
				elif RunProgressionRuntimeRef.get_milestone_completion(progression, milestone_wave) != completion:
					_add_error(issues, "run_progression_boss_completion_runtime", CATEGORY, milestone_id, "Runtime completion does not match milestone data.")
				elif completion == RunProgressionRuntimeRef.MILESTONE_COMPLETION_VICTORY and milestone_wave != total_waves:
					_add_error(issues, "run_progression_early_boss_victory", CATEGORY, milestone_id, "Only the final wave boss may complete the run.")
				var reward := str(milestone.get("reward", "")).strip_edges()
				if reward not in RunProgressionRuntimeRef.SUPPORTED_MILESTONE_REWARDS:
					_add_error(issues, "run_progression_boss_reward", CATEGORY, milestone_id, "Unsupported boss reward '%s'." % reward)
				elif reward == "ascension" and int(milestone.get("choice_count", 0)) <= 0:
					_add_error(issues, "run_progression_choice_count", CATEGORY, milestone_id, "Ascension milestone choice_count must be positive.")

	for required_wave_variant in REQUIRED_BOSS_MILESTONES.keys():
		var required_wave := int(required_wave_variant)
		var required_boss_id := str(REQUIRED_BOSS_MILESTONES[required_wave_variant])
		if str(milestone_bosses_by_wave.get(required_wave, "")) != required_boss_id:
			_add_error(
				issues,
				"run_progression_required_boss_milestone",
				CATEGORY,
				progression_id,
				"Wave %d must use the approved boss '%s'." % [required_wave, required_boss_id]
			)

	var fallback_wave := 1
	while fallback_wave < total_waves and milestone_waves.has(fallback_wave):
		fallback_wave += 1
	if fallback_wave < total_waves and RunProgressionRuntimeRef.get_milestone_completion(progression, fallback_wave) != RunProgressionRuntimeRef.MILESTONE_COMPLETION_INTERMISSION:
		_add_error(issues, "run_progression_nonfinal_boss_default", CATEGORY, progression_id, "A non-final boss without milestone completion must default to intermission.")

	var victory_wave := 0
	var victory_variant: Variant = progression.get("victory", {})
	if not (victory_variant is Dictionary):
		_add_error(issues, "run_progression_victory_type", CATEGORY, progression_id, "victory must be a dictionary.")
	else:
		var victory: Dictionary = victory_variant
		victory_wave = int(victory.get("wave", 0))
		if victory_wave <= 0 or (total_waves > 0 and victory_wave != total_waves):
			_add_error(issues, "run_progression_victory_wave", CATEGORY, progression_id, "Victory wave must match total_waves.")
		var victory_condition := str(victory.get("condition", "")).strip_edges()
		if victory_condition not in SUPPORTED_VICTORY_CONDITIONS:
			_add_error(issues, "run_progression_victory_condition", CATEGORY, progression_id, "Unsupported victory condition '%s'." % victory_condition)
		elif victory_condition == "boss_defeat":
			var final_milestone := RunProgressionRuntimeRef.get_milestone_for_wave(progression, victory_wave)
			if str(final_milestone.get("type", "")) != "boss":
				_add_error(issues, "run_progression_final_boss_missing", CATEGORY, progression_id, "boss_defeat victory requires a boss milestone on the final wave.")
			elif str(final_milestone.get("completion", "")) != RunProgressionRuntimeRef.MILESTONE_COMPLETION_VICTORY:
				_add_error(issues, "run_progression_final_boss_completion", CATEGORY, progression_id, "Final boss milestone must use victory completion.")

	var cadence_variant: Variant = progression.get("portal_cadence", {})
	if not (cadence_variant is Dictionary):
		_add_error(issues, "portal_cadence_type", CATEGORY, progression_id, "portal_cadence must be a dictionary.")
		return
	var cadence: Dictionary = cadence_variant
	var first_eligible_wave := int(cadence.get("first_eligible_wave", 0))
	var guaranteed_wave := int(cadence.get("guaranteed_first_spawn_wave", 0))
	if first_eligible_wave <= 0 or (total_waves > 0 and first_eligible_wave > total_waves):
		_add_error(issues, "portal_first_eligible_wave", CATEGORY, progression_id, "first_eligible_wave must be inside the configured run.")
	if guaranteed_wave < first_eligible_wave or (total_waves > 0 and guaranteed_wave > total_waves):
		_add_error(issues, "portal_guaranteed_wave", CATEGORY, progression_id, "guaranteed_first_spawn_wave must be on or after first_eligible_wave and inside the run.")

	var suppressed_waves: Array[int] = []
	var suppressed_variant: Variant = cadence.get("suppressed_waves", [])
	if not (suppressed_variant is Array):
		_add_error(issues, "portal_suppressed_waves_type", CATEGORY, progression_id, "suppressed_waves must be an array.")
		return
	for wave_variant in suppressed_variant:
		var suppressed_wave := int(wave_variant)
		if suppressed_wave <= 0 or (total_waves > 0 and suppressed_wave > total_waves):
			_add_error(issues, "portal_suppressed_wave", CATEGORY, progression_id, "Suppressed portal wave must be inside the configured run.")
		elif suppressed_waves.has(suppressed_wave):
			_add_error(issues, "portal_duplicate_suppressed_wave", CATEGORY, progression_id, "Suppressed portal wave %d is duplicated." % suppressed_wave)
		else:
			suppressed_waves.append(suppressed_wave)
	if suppressed_waves.has(first_eligible_wave):
		_add_error(issues, "portal_first_wave_suppressed", CATEGORY, progression_id, "first_eligible_wave cannot also be suppressed.")
	if suppressed_waves.has(guaranteed_wave):
		_add_error(issues, "portal_guaranteed_wave_suppressed", CATEGORY, progression_id, "guaranteed_first_spawn_wave cannot also be suppressed.")
	for milestone_wave in milestone_waves:
		if not suppressed_waves.has(milestone_wave):
			_add_error(issues, "portal_milestone_not_suppressed", CATEGORY, progression_id, "Milestone wave %d must suppress new portal spawns." % milestone_wave)
	if victory_wave > 0 and not suppressed_waves.has(victory_wave):
		_add_error(issues, "portal_victory_not_suppressed", CATEGORY, progression_id, "Victory wave must suppress new portal spawns.")

static func _validate_wave_spawn_config(
	issues: Array[Dictionary],
	config: Dictionary,
	enemies: Dictionary,
	run_progression: Dictionary
) -> void:
	const CATEGORY := "wave_spawn_config"
	const CONFIG_ID := "commercial_run"
	if config.is_empty():
		_add_error(issues, "wave_spawn_config_missing", CATEGORY, CONFIG_ID, "Wave spawn config is missing or invalid.")
		return
	var total_waves := RunProgressionRuntimeRef.get_final_wave(run_progression)
	if total_waves <= 0:
		total_waves = 20

	var pressure_bands_variant: Variant = config.get("pressure_bands", [])
	if not (pressure_bands_variant is Array):
		_add_error(issues, "pressure_bands_type", CATEGORY, CONFIG_ID, "pressure_bands must be an array.")
	else:
		var seen_band_ids: Dictionary = {}
		var wave_coverage: Dictionary = {}
		for band_variant in pressure_bands_variant:
			if not (band_variant is Dictionary):
				_add_error(issues, "pressure_band_type", CATEGORY, CONFIG_ID, "pressure_bands contains a non-dictionary entry.")
				continue
			var band: Dictionary = band_variant
			var band_id := str(band.get("id", "")).strip_edges()
			var min_wave := int(band.get("min_wave", 0))
			var max_wave := int(band.get("max_wave", 0))
			if band_id == "":
				_add_error(issues, "pressure_band_id", CATEGORY, CONFIG_ID, "Pressure band is missing id.")
			elif seen_band_ids.has(band_id):
				_add_error(issues, "pressure_band_duplicate_id", CATEGORY, band_id, "Pressure band id is duplicated.")
			seen_band_ids[band_id] = true
			if min_wave <= 0 or max_wave < min_wave or max_wave > total_waves:
				_add_error(issues, "pressure_band_range", CATEGORY, band_id, "Pressure band range must be ordered and inside the configured run.")
			else:
				for wave_index in range(min_wave, max_wave + 1):
					wave_coverage[wave_index] = int(wave_coverage.get(wave_index, 0)) + 1
			var expected_range_variant: Variant = REQUIRED_PRESSURE_BAND_RANGES.get(band_id, null)
			if not (expected_range_variant is Vector2i):
				_add_error(issues, "pressure_band_unknown_id", CATEGORY, band_id, "Unsupported pressure band id.")
			else:
				var expected_range := expected_range_variant as Vector2i
				if min_wave != expected_range.x or max_wave != expected_range.y:
					_add_error(issues, "pressure_band_expected_range", CATEGORY, band_id, "Expected waves %d-%d." % [expected_range.x, expected_range.y])
			var interval_multiplier := float(band.get("spawn_interval_multiplier", 0.0))
			var max_alive := int(band.get("max_alive_enemies", 0))
			var hp_multiplier := float(band.get("enemy_hp_multiplier", 0.0))
			var damage_multiplier := float(band.get("enemy_damage_multiplier", 0.0))
			var elite_multiplier := float(band.get("elite_chance_multiplier", -1.0))
			if interval_multiplier < 0.25 or interval_multiplier > 1.5:
				_add_error(issues, "pressure_band_spawn_interval", CATEGORY, band_id, "spawn_interval_multiplier must stay between 0.25 and 1.5.")
			if max_alive <= 0 or max_alive > 80:
				_add_error(issues, "pressure_band_max_alive", CATEGORY, band_id, "max_alive_enemies must stay between 1 and 80.")
			if hp_multiplier < 0.5 or hp_multiplier > 2.0:
				_add_error(issues, "pressure_band_hp", CATEGORY, band_id, "enemy_hp_multiplier must stay between 0.5 and 2.0.")
			if damage_multiplier < 0.5 or damage_multiplier > 2.0:
				_add_error(issues, "pressure_band_damage", CATEGORY, band_id, "enemy_damage_multiplier must stay between 0.5 and 2.0.")
			if elite_multiplier < 0.0 or elite_multiplier > 3.0:
				_add_error(issues, "pressure_band_elite", CATEGORY, band_id, "elite_chance_multiplier must stay between 0.0 and 3.0.")
		for required_band_id in REQUIRED_PRESSURE_BAND_RANGES.keys():
			if not seen_band_ids.has(required_band_id):
				_add_error(issues, "pressure_band_required", CATEGORY, str(required_band_id), "Required pressure band is missing.")
		for wave_index in range(1, total_waves + 1):
			if int(wave_coverage.get(wave_index, 0)) != 1:
				_add_error(issues, "pressure_band_wave_coverage", CATEGORY, str(wave_index), "Wave must belong to exactly one pressure band.")

	var pools_variant: Variant = config.get("wave_variant_pools", config.get("waves", []))
	if not (pools_variant is Array) or (pools_variant as Array).is_empty():
		_add_error(issues, "wave_pool_missing", CATEGORY, CONFIG_ID, "At least one wave enemy pool is required.")
	else:
		var previous_max_wave := 0
		var pool_max_waves: Array[int] = []
		var pool_variant_ids_by_max_wave: Dictionary = {}
		for pool_variant in pools_variant:
			if not (pool_variant is Dictionary):
				_add_error(issues, "wave_pool_type", CATEGORY, CONFIG_ID, "Wave pools contains a non-dictionary entry.")
				continue
			var pool: Dictionary = pool_variant
			var max_wave := int(pool.get("max_wave", 0))
			if max_wave <= previous_max_wave or max_wave > total_waves:
				_add_error(issues, "wave_pool_order", CATEGORY, str(max_wave), "Wave pool max_wave must increase and stay inside the run.")
			previous_max_wave = maxi(previous_max_wave, max_wave)
			pool_max_waves.append(max_wave)
			if pool.has("spawn_interval_multiplier"):
				var wave_interval_multiplier := float(pool.get("spawn_interval_multiplier", 0.0))
				if wave_interval_multiplier < 0.5 or wave_interval_multiplier > 2.0:
					_add_error(issues, "wave_pool_spawn_interval_override", CATEGORY, str(max_wave), "Wave spawn interval override must stay between 0.5 and 2.0.")
			if pool.has("max_alive_enemies"):
				var wave_max_alive := int(pool.get("max_alive_enemies", 0))
				if wave_max_alive < 1 or wave_max_alive > 80:
					_add_error(issues, "wave_pool_max_alive_override", CATEGORY, str(max_wave), "Wave maximum-alive override must stay between 1 and 80.")
			if pool.has("elite_chance_multiplier"):
				var wave_elite_multiplier := float(pool.get("elite_chance_multiplier", -1.0))
				if wave_elite_multiplier < 0.0 or wave_elite_multiplier > 3.0:
					_add_error(issues, "wave_pool_elite_override", CATEGORY, str(max_wave), "Wave elite multiplier override must stay between 0 and 3.")
			var variants_variant: Variant = pool.get("variants", [])
			if not (variants_variant is Array) or (variants_variant as Array).is_empty():
				_add_error(issues, "wave_pool_variants", CATEGORY, str(max_wave), "Wave pool must contain enemy variants.")
				continue
			var pool_variant_ids: Dictionary = {}
			var total_weight := 0.0
			for enemy_variant in variants_variant:
				if not (enemy_variant is Dictionary):
					_add_error(issues, "wave_pool_variant_type", CATEGORY, str(max_wave), "Weighted wave entries must be dictionaries.")
					continue
				var enemy_entry: Dictionary = enemy_variant
				var enemy_id := str(enemy_entry.get("id", "")).strip_edges()
				if not enemies.has(enemy_id):
					_add_error(issues, "wave_pool_enemy_reference", CATEGORY, enemy_id, "Wave pool references an unknown enemy.")
				elif pool_variant_ids.has(enemy_id):
					_add_error(issues, "wave_pool_enemy_duplicate", CATEGORY, enemy_id, "Wave pool contains the same enemy more than once.")
				else:
					pool_variant_ids[enemy_id] = true
				var weight := float(enemy_entry.get("weight", 0.0))
				if weight <= 0.0:
					_add_error(issues, "wave_pool_enemy_weight", CATEGORY, enemy_id, "Wave pool enemy weight must be positive.")
				total_weight += weight
			if not is_equal_approx(total_weight, 1.0):
				_add_error(issues, "wave_pool_weight_total", CATEGORY, str(max_wave), "Wave pool weights must total 1.0; found %.3f." % total_weight)
			pool_variant_ids_by_max_wave[max_wave] = pool_variant_ids
		if previous_max_wave != total_waves:
			_add_error(issues, "wave_pool_final_boundary", CATEGORY, CONFIG_ID, "Final wave pool max_wave must match the configured run.")
		for required_max_wave in REQUIRED_EXPLICIT_WAVE_POOL_MAX_WAVES:
			if not pool_max_waves.has(required_max_wave):
				_add_error(issues, "wave_pool_explicit_boundary", CATEGORY, str(required_max_wave), "Implemented waves require one explicit pool per wave.")
		var wave_6_ids: Dictionary = pool_variant_ids_by_max_wave.get(6, {})
		var wave_7_ids: Dictionary = pool_variant_ids_by_max_wave.get(7, {})
		var wave_8_ids: Dictionary = pool_variant_ids_by_max_wave.get(8, {})
		var wave_9_ids: Dictionary = pool_variant_ids_by_max_wave.get(9, {})
		var wave_10_ids: Dictionary = pool_variant_ids_by_max_wave.get(10, {})
		var wave_11_ids: Dictionary = pool_variant_ids_by_max_wave.get(11, {})
		var wave_12_ids: Dictionary = pool_variant_ids_by_max_wave.get(12, {})
		var wave_13_ids: Dictionary = pool_variant_ids_by_max_wave.get(13, {})
		var wave_14_ids: Dictionary = pool_variant_ids_by_max_wave.get(14, {})
		var wave_15_ids: Dictionary = pool_variant_ids_by_max_wave.get(15, {})
		var wave_16_ids: Dictionary = pool_variant_ids_by_max_wave.get(16, {})
		var wave_17_ids: Dictionary = pool_variant_ids_by_max_wave.get(17, {})
		var wave_18_ids: Dictionary = pool_variant_ids_by_max_wave.get(18, {})
		var wave_19_ids: Dictionary = pool_variant_ids_by_max_wave.get(19, {})
		var wave_20_ids: Dictionary = pool_variant_ids_by_max_wave.get(20, {})
		if not wave_6_ids.has("horned_bruiser"):
			_add_error(issues, "wave_6_horned_bruiser", CATEGORY, "6", "Wave 6 must introduce Horned Bruiser.")
		if wave_7_ids.has("rift_caller"):
			_add_error(issues, "wave_7_rift_caller_leak", CATEGORY, "7", "Rift Caller must remain absent until Wave 8.")
		if not wave_8_ids.has("rift_caller"):
			_add_error(issues, "wave_8_rift_caller", CATEGORY, "8", "Wave 8 must introduce Rift Caller.")
		for required_enemy_id in ["imp_runner", "husk_brute", "spit_fiend", "skeleton_rifleman", "horned_bruiser", "rift_caller"]:
			if not wave_9_ids.has(required_enemy_id):
				_add_error(issues, "wave_9_full_roster", CATEGORY, "9", "Wave 9 must include the complete current regular and elite roster.")
		if wave_10_ids.has("cinder_ram"):
			_add_error(issues, "wave_10_cinder_ram_leak", CATEGORY, "10", "Cinder Ram must remain absent until Wave 11.")
		if not wave_11_ids.has("cinder_ram"):
			_add_error(issues, "wave_11_cinder_ram", CATEGORY, "11", "Wave 11 must introduce Cinder Ram.")
		if not wave_12_ids.has("cinder_ram") or not wave_12_ids.has("skeleton_rifleman"):
			_add_error(issues, "wave_12_charger_marksman", CATEGORY, "12", "Wave 12 must combine Cinder Ram with Skeleton Rifleman.")
		if wave_12_ids.has("ash_lantern"):
			_add_error(issues, "wave_12_ash_lantern_leak", CATEGORY, "12", "Ash Lantern must remain absent until Wave 13.")
		if not wave_13_ids.has("ash_lantern"):
			_add_error(issues, "wave_13_ash_lantern", CATEGORY, "13", "Wave 13 must introduce Ash Lantern.")
		if not wave_14_ids.has("ash_lantern") or not wave_14_ids.has("cinder_ram") or not wave_14_ids.has("imp_runner"):
			_add_error(issues, "wave_14_hazard_chasers", CATEGORY, "14", "Wave 14 must combine Ash Lantern with committed and fast chasers.")
		if wave_15_ids.has("ash_lantern"):
			_add_error(issues, "wave_15_hazard_add_overlap", CATEGORY, "15", "Wave 15 adds must leave area denial to the milestone boss.")
		if wave_15_ids.has("bone_captain"):
			_add_error(issues, "wave_15_bone_captain_leak", CATEGORY, "15", "Bone Captain must remain absent until Wave 16.")
		if not wave_16_ids.has("bone_captain"):
			_add_error(issues, "wave_16_bone_captain", CATEGORY, "16", "Wave 16 must introduce Bone Captain.")
		if not wave_17_ids.has("bone_captain") or not wave_17_ids.has("husk_brute") or not wave_17_ids.has("horned_bruiser"):
			_add_error(issues, "wave_17_support_brutes", CATEGORY, "17", "Wave 17 must combine Bone Captain with durable frontline threats.")
		for mastery_wave in [18, 19]:
			var mastery_ids: Dictionary = pool_variant_ids_by_max_wave.get(mastery_wave, {})
			for mastery_enemy_id in ["imp_runner", "husk_brute", "spit_fiend", "skeleton_rifleman", "horned_bruiser", "rift_caller", "cinder_ram", "ash_lantern", "bone_captain"]:
				if not mastery_ids.has(mastery_enemy_id):
					_add_error(issues, "late_wave_full_roster", CATEGORY, str(mastery_wave), "Wave %d must include every learned regular role." % mastery_wave)
		if wave_20_ids.has("ash_lantern"):
			_add_error(issues, "wave_20_hazard_add_overlap", CATEGORY, "20", "Wave 20 adds must leave area denial to the final boss.")
		for final_add_id in ["imp_runner", "husk_brute", "spit_fiend", "skeleton_rifleman", "cinder_ram", "bone_captain"]:
			if not wave_20_ids.has(final_add_id):
				_add_error(issues, "wave_20_controlled_roster", CATEGORY, "20", "Wave 20 must retain the approved controlled add roster.")
		var milestone_config := EnemySpawnWavePoolRuntimeRef.normalize_wave_config(config)
		var milestone_pools_variant: Variant = milestone_config.get("wave_variant_pools", [])
		var milestone_pools: Array[Dictionary] = []
		if milestone_pools_variant is Array:
			for milestone_pool_variant in milestone_pools_variant:
				if milestone_pool_variant is Dictionary:
					milestone_pools.append(milestone_pool_variant as Dictionary)
		for milestone_wave in [5, 10, 15, 20]:
			var milestone_overrides := EnemySpawnWavePoolRuntimeRef.get_wave_runtime_overrides_for_wave(
				milestone_pools,
				milestone_wave
			)
			if int(milestone_overrides.get("max_alive_enemies", 999)) > 18:
				_add_error(issues, "milestone_add_budget", CATEGORY, str(milestone_wave), "Milestone waves must cap regular adds at 18 or fewer.")

	var elite_variant := str(config.get("elite_variant", "")).strip_edges()
	if not enemies.has(elite_variant):
		_add_error(issues, "wave_elite_reference", CATEGORY, elite_variant, "Elite variant references an unknown enemy.")
	var elite_chance := float(config.get("elite_spawn_chance", -1.0))
	if elite_chance < 0.0 or elite_chance > 1.0:
		_add_error(issues, "wave_elite_chance", CATEGORY, elite_variant, "elite_spawn_chance must stay between 0.0 and 1.0.")

	var normalized_config := EnemySpawnWavePoolRuntimeRef.normalize_wave_config(config)
	var normalized_bands_variant: Variant = normalized_config.get("pressure_bands", [])
	if normalized_bands_variant is Array:
		var normalized_bands: Array[Dictionary] = []
		for band_variant in normalized_bands_variant:
			if band_variant is Dictionary:
				normalized_bands.append(band_variant as Dictionary)
		for required_band_id in REQUIRED_PRESSURE_BAND_RANGES.keys():
			var expected_range: Vector2i = REQUIRED_PRESSURE_BAND_RANGES[required_band_id]
			var resolved_band := EnemySpawnWavePoolRuntimeRef.get_pressure_band_for_wave(normalized_bands, expected_range.x)
			if str(resolved_band.get("id", "")) != str(required_band_id):
				_add_error(issues, "pressure_band_runtime_resolution", CATEGORY, str(required_band_id), "Runtime does not resolve the configured pressure band.")

static func _validate_shop_config(
	issues: Array[Dictionary],
	config: Dictionary,
	run_progression: Dictionary
) -> void:
	const CATEGORY := "shop_config"
	const CONFIG_ID := "commercial_run"
	if config.is_empty():
		_add_error(issues, "shop_config_missing", CATEGORY, CONFIG_ID, "Shop config is missing or invalid.")
		return
	var total_waves := RunProgressionRuntimeRef.get_final_wave(run_progression)
	if total_waves <= 0:
		total_waves = 20

	var bands_variant: Variant = config.get("weapon_rarity_weights_by_wave", [])
	if not (bands_variant is Array):
		_add_error(issues, "shop_rarity_bands_type", CATEGORY, CONFIG_ID, "weapon_rarity_weights_by_wave must be an array.")
		return
	var bands: Array = bands_variant
	if bands.size() != REQUIRED_SHOP_RARITY_MAX_WAVES.size():
		_add_error(issues, "shop_rarity_band_count", CATEGORY, CONFIG_ID, "Expected %d Shop rarity bands; found %d." % [REQUIRED_SHOP_RARITY_MAX_WAVES.size(), bands.size()])

	var previous_max_wave := 0
	for band_index in bands.size():
		var band_variant: Variant = bands[band_index]
		var band_id := str(band_index + 1)
		if not (band_variant is Dictionary):
			_add_error(issues, "shop_rarity_band_type", CATEGORY, band_id, "Shop rarity band must be a dictionary.")
			continue
		var band: Dictionary = band_variant
		var max_wave := int(band.get("max_wave", 0))
		band_id = "%d-%d" % [previous_max_wave + 1, max_wave]
		if max_wave <= previous_max_wave or max_wave > total_waves:
			_add_error(issues, "shop_rarity_band_order", CATEGORY, band_id, "Shop rarity band max_wave must increase and stay inside the run.")
		if band_index < REQUIRED_SHOP_RARITY_MAX_WAVES.size():
			var expected_max_wave := REQUIRED_SHOP_RARITY_MAX_WAVES[band_index]
			if max_wave != expected_max_wave:
				_add_error(issues, "shop_rarity_band_boundary", CATEGORY, band_id, "Expected max_wave %d." % expected_max_wave)

		var weights_variant: Variant = band.get("weights", {})
		if not (weights_variant is Dictionary):
			_add_error(issues, "shop_rarity_weights_type", CATEGORY, band_id, "Shop rarity weights must be a dictionary.")
		else:
			var weights: Dictionary = weights_variant
			for rarity_variant in weights.keys():
				var rarity_name := str(rarity_variant)
				if rarity_name not in SUPPORTED_RARITIES:
					_add_error(issues, "shop_rarity_unknown", CATEGORY, band_id, "Unsupported Shop rarity '%s'." % rarity_name)
			var total_weight := 0.0
			for rarity_name in SUPPORTED_RARITIES:
				var weight := float(weights.get(rarity_name, 0.0))
				if weight < 0.0 or weight > 100.0:
					_add_error(issues, "shop_rarity_weight_range", CATEGORY, band_id, "%s weight must stay between 0 and 100." % rarity_name)
				total_weight += weight
			if not is_equal_approx(total_weight, 100.0):
				_add_error(issues, "shop_rarity_weight_total", CATEGORY, band_id, "Shop rarity weights must total 100; found %.2f." % total_weight)
		previous_max_wave = maxi(previous_max_wave, max_wave)
	if previous_max_wave != total_waves:
		_add_error(issues, "shop_rarity_final_boundary", CATEGORY, CONFIG_ID, "Final Shop rarity band max_wave must match the configured run.")

	var multipliers_variant: Variant = config.get("weapon_rarity_price_multiplier", {})
	if not (multipliers_variant is Dictionary):
		_add_error(issues, "shop_rarity_price_type", CATEGORY, CONFIG_ID, "weapon_rarity_price_multiplier must be a dictionary.")
	else:
		var multipliers: Dictionary = multipliers_variant
		var previous_multiplier := 0
		for rarity_name in SUPPORTED_RARITIES:
			if not multipliers.has(rarity_name):
				_add_error(issues, "shop_rarity_price_missing", CATEGORY, rarity_name, "Every supported rarity requires a price multiplier.")
				continue
			var multiplier := int(multipliers.get(rarity_name, 0))
			if multiplier <= 0:
				_add_error(issues, "shop_rarity_price_range", CATEGORY, rarity_name, "Rarity price multiplier must be positive.")
			if previous_multiplier > 0 and multiplier < previous_multiplier:
				_add_error(issues, "shop_rarity_price_order", CATEGORY, rarity_name, "Rarity price multipliers cannot decrease at higher rarities.")
			previous_multiplier = maxi(previous_multiplier, multiplier)

	var normalized_config := ShopOfferRuntimeRef.normalize_shop_config(config)
	var start_wave := 1
	for band_variant in bands:
		if not (band_variant is Dictionary):
			continue
		var band: Dictionary = band_variant
		var expected_variant: Variant = band.get("weights", {})
		if not (expected_variant is Dictionary):
			continue
		var expected_weights: Dictionary = expected_variant
		var resolved_weights := ShopOfferRuntimeRef.rarity_weights_for_wave_in_config(normalized_config, start_wave)
		for rarity_name in SUPPORTED_RARITIES:
			if not is_equal_approx(float(resolved_weights.get(rarity_name, 0.0)), float(expected_weights.get(rarity_name, 0.0))):
				_add_error(issues, "shop_rarity_runtime_resolution", CATEGORY, str(start_wave), "Runtime rarity weights do not match the configured band.")
				break
		start_wave = int(band.get("max_wave", start_wave)) + 1

	var final_weights := ShopOfferRuntimeRef.rarity_weights_for_wave_in_config(normalized_config, total_waves)
	var overflow_weights := ShopOfferRuntimeRef.rarity_weights_for_wave_in_config(normalized_config, total_waves + 1)
	for rarity_name in SUPPORTED_RARITIES:
		if not is_equal_approx(float(final_weights.get(rarity_name, 0.0)), float(overflow_weights.get(rarity_name, 0.0))):
			_add_error(issues, "shop_rarity_overflow_fallback", CATEGORY, CONFIG_ID, "Waves beyond the current run must retain the final configured rarity weights.")
			break

static func _validate_characters(
	issues: Array[Dictionary],
	characters: Dictionary,
	weapons: Dictionary,
	set_bonuses: Dictionary
) -> void:
	var selectable_count := 0
	var roster_orders: Dictionary = {}
	for character_id in _sorted_keys(characters):
		var entry: Variant = characters[character_id]
		if not (entry is Dictionary):
			_add_error(issues, "character_type", "character", character_id, "Character entry must be a dictionary.")
			continue
		var character: Dictionary = entry
		_validate_embedded_id(issues, "character", character_id, character)
		var visual_path := str(character.get("visual_path", "")).strip_edges()
		if visual_path != "":
			if not _resource_or_source_exists(visual_path):
				_add_error(issues, "character_visual_missing", "character", character_id, "Hunter visual resource does not exist: %s" % visual_path)
			else:
				_validate_character_presentation_scale(issues, character_id, character, visual_path)
		var selectable: bool = character.get("selectable", true) != false
		if not selectable:
			continue
		selectable_count += 1
		_validate_character_stat_map(issues, character_id, character, "stat_multipliers")
		_validate_character_stat_map(issues, character_id, character, "stat_bonuses")
		_validate_character_passive_rules(issues, character_id, character)

		if str(character.get("display_name", "")).strip_edges() == "":
			_add_error(issues, "character_display_name", "character", character_id, "Selectable hunter is missing display_name.")
		if visual_path == "":
			_add_error(issues, "character_visual_path", "character", character_id, "Selectable hunter is missing visual_path.")

		var roster_order := int(character.get("roster_order", -1))
		if roster_order < 0:
			_add_error(issues, "character_roster_order", "character", character_id, "Selectable hunter requires a non-negative roster_order.")
		elif roster_orders.has(roster_order):
			_add_error(issues, "character_roster_order_duplicate", "character", character_id, "roster_order %d is already used by '%s'." % [roster_order, str(roster_orders[roster_order])])
		else:
			roster_orders[roster_order] = character_id

		var starting_weapon_ids := _string_array(character.get("starting_weapon_ids", []))
		var family_weapon_ids := _string_array(character.get("family_weapon_ids", []))
		if starting_weapon_ids.is_empty():
			_add_error(issues, "character_starters_empty", "character", character_id, "Selectable hunter has no starting weapons.")
		if family_weapon_ids.size() != 6:
			_add_error(issues, "character_family_weapon_count", "character", character_id, "Selectable hunter must expose exactly 6 family weapons; found %d." % family_weapon_ids.size())
		_validate_weapon_references(issues, character_id, "starting_weapon_ids", starting_weapon_ids, weapons)
		_validate_weapon_references(issues, character_id, "family_weapon_ids", family_weapon_ids, weapons)
		for starter_id in starting_weapon_ids:
			if not family_weapon_ids.has(starter_id):
				_add_error(issues, "character_starter_outside_family", "character", character_id, "Starting weapon '%s' is not in family_weapon_ids." % starter_id)

		var family_id := str(character.get("preferred_weapon_family", "")).strip_edges()
		if family_id == "":
			_add_error(issues, "character_family_missing", "character", character_id, "Selectable hunter is missing preferred_weapon_family.")
		elif not set_bonuses.has(family_id):
			_add_error(issues, "character_set_bonus_missing", "character", character_id, "Preferred family '%s' has no set-bonus definition." % family_id)

	if selectable_count != EXPECTED_SELECTABLE_HUNTERS:
		_add_error(issues, "selectable_hunter_count", "character", "", "Expected %d selectable hunters; found %d." % [EXPECTED_SELECTABLE_HUNTERS, selectable_count])

static func _validate_character_presentation_scale(
	issues: Array[Dictionary],
	character_id: String,
	character: Dictionary,
	visual_path: String
) -> void:
	var visual_scale := float(character.get("visual_scale", 0.0))
	if visual_scale <= 0.0:
		_add_error(issues, "character_visual_scale", "character", character_id, "Hunter visual_scale must be positive.")
		return
	var texture := _load_texture_resource(visual_path)
	if texture == null:
		_add_error(issues, "character_visual_load", "character", character_id, "Hunter visual could not be loaded for presentation-scale validation: %s" % visual_path)
		return
	var visible_size := CombatScaleSpecRef.texture_visible_size(texture)
	var screen_height := CombatScaleSpecRef.reference_screen_size(visible_size, visual_scale).y
	var allowed_range: Vector2 = CombatScaleSpecRef.HUNTER_SCREEN_HEIGHT_RANGE
	if not CombatScaleSpecRef.is_value_in_range(screen_height, allowed_range):
		_add_error(
			issues,
			"character_presentation_scale",
			"character",
			character_id,
			"Hunter renders %.1f px tall at the reference view; expected %s px from visible texture bounds."
				% [screen_height, CombatScaleSpecRef.describe_range(allowed_range)]
		)

static func _validate_character_stat_map(issues: Array[Dictionary], character_id: String, character: Dictionary, field_name: String) -> void:
	var values_variant: Variant = character.get(field_name, {})
	if not (values_variant is Dictionary):
		_add_error(issues, "character_stat_map", "character", character_id, "%s must be a dictionary." % field_name)
		return
	for stat_id_variant in (values_variant as Dictionary).keys():
		var stat_id := str(stat_id_variant)
		if not StatBlockRef.is_supported_stat(stat_id):
			_add_error(issues, "character_stat_id", "character", character_id, "%s uses unsupported stat '%s'." % [field_name, stat_id])

static func _validate_character_passive_rules(issues: Array[Dictionary], character_id: String, character: Dictionary) -> void:
	var rules_variant: Variant = character.get("passive_runtime_rules", [])
	if not (rules_variant is Array):
		_add_error(issues, "character_passive_rules_type", "character", character_id, "passive_runtime_rules must be an array.")
		return
	for rule_variant in rules_variant:
		if not (rule_variant is Dictionary):
			_add_error(issues, "character_passive_rule_type", "character", character_id, "passive_runtime_rules contains a non-dictionary rule.")
			continue
		var rule: Dictionary = rule_variant
		var effect_id := str(rule.get("effect", PlayerPassiveRuntimeRef.DEFAULT_EFFECT))
		var trigger_id := str(rule.get("trigger", ""))
		var required_source_tags := WeaponTagRuntimeRef.resolve_effect_tags(rule.get("required_source_weapon_tags", []))
		if effect_id not in PlayerPassiveRuntimeRef.SUPPORTED_EFFECTS:
			_add_error(issues, "character_passive_effect", "character", character_id, "Unsupported passive effect '%s'." % effect_id)
		if trigger_id not in PlayerPassiveRuntimeRef.SUPPORTED_TRIGGERS:
			_add_error(issues, "character_passive_trigger", "character", character_id, "Unsupported passive trigger '%s'." % trigger_id)
		for required_source_tag in required_source_tags:
			if not WeaponTagRuntimeRef.is_canonical_gameplay_tag(required_source_tag):
				_add_error(issues, "character_passive_source_tag", "character", character_id, "Passive rule '%s' requires non-canonical source tag '%s'." % [str(rule.get("id", "")), required_source_tag])
		var modifiers_variant: Variant = rule.get("modifiers", [])
		if not (modifiers_variant is Array) or (modifiers_variant as Array).is_empty():
			_add_error(issues, "character_passive_modifiers", "character", character_id, "Passive rule '%s' requires at least one modifier." % str(rule.get("id", "")))
			continue
		for modifier_variant in modifiers_variant:
			if not (modifier_variant is Dictionary):
				_add_error(issues, "character_passive_modifier_type", "character", character_id, "Passive rule '%s' contains a non-dictionary modifier." % str(rule.get("id", "")))
				continue
			var modifier: Dictionary = modifier_variant
			var stat_id := str(modifier.get("stat_id", ""))
			if not StatBlockRef.is_supported_stat(stat_id):
				_add_error(issues, "character_passive_stat", "character", character_id, "Passive rule '%s' uses unsupported stat '%s'." % [str(rule.get("id", "")), stat_id])
			var effect_tags := WeaponTagRuntimeRef.resolve_effect_tags(modifier.get("effect_tags", []))
			if not effect_tags.is_empty() and not WeaponTagRuntimeRef.is_supported_weapon_bonus_stat(stat_id):
				_add_error(issues, "character_passive_weapon_stat", "character", character_id, "Passive rule '%s' uses unsupported tagged-weapon stat '%s'." % [str(rule.get("id", "")), stat_id])
			for effect_tag in effect_tags:
				if not WeaponTagRuntimeRef.is_canonical_gameplay_tag(effect_tag):
					_add_error(issues, "character_passive_tag", "character", character_id, "Passive rule '%s' uses non-canonical tag '%s'." % [str(rule.get("id", "")), effect_tag])

static func _validate_weapon_references(
	issues: Array[Dictionary],
	character_id: String,
	field_name: String,
	weapon_ids: Array[String],
	weapons: Dictionary
) -> void:
	var seen: Dictionary = {}
	for weapon_id in weapon_ids:
		if weapon_id == "":
			_add_error(issues, "character_weapon_id_empty", "character", character_id, "%s contains an empty weapon id." % field_name)
			continue
		if seen.has(weapon_id):
			_add_error(issues, "character_weapon_duplicate", "character", character_id, "%s repeats weapon '%s'." % [field_name, weapon_id])
			continue
		seen[weapon_id] = true
		if not weapons.has(weapon_id):
			_add_error(issues, "character_weapon_missing", "character", character_id, "%s references unknown weapon '%s'." % [field_name, weapon_id])

static func _validate_weapons(issues: Array[Dictionary], weapons: Dictionary) -> void:
	var signature_owner_by_summary: Dictionary = {}
	for weapon_id in _sorted_keys(weapons):
		var weapon: Variant = weapons[weapon_id]
		if weapon == null or not (weapon is Object):
			_add_error(issues, "weapon_type", "weapon", weapon_id, "Weapon entry must be a Resource/Object.")
			continue
		_validate_embedded_id(issues, "weapon", weapon_id, weapon)
		if str(_value(weapon, "display_name", "")).strip_edges() == "":
			_add_error(issues, "weapon_display_name", "weapon", weapon_id, "Weapon is missing display_name.")
		if _value(weapon, "shop_enabled", true) == true:
			var signature_summary := str(_value(weapon, "signature_attack_summary", "")).strip_edges()
			if signature_summary == "":
				_add_error(issues, "weapon_signature_summary", "weapon", weapon_id, "Playable weapon is missing signature_attack_summary.")
			elif signature_owner_by_summary.has(signature_summary):
				_add_error(issues, "weapon_signature_duplicate", "weapon", weapon_id, "Attack signature duplicates weapon '%s'." % str(signature_owner_by_summary[signature_summary]))
			else:
				signature_owner_by_summary[signature_summary] = weapon_id
		if _weapon_family(weapon) == "":
			_add_error(issues, "weapon_family", "weapon", weapon_id, "Weapon is missing family.")
		var attack_motion_profile := str(_value(weapon, "attack_motion_profile", "auto"))
		if attack_motion_profile not in WeaponData.ATTACK_MOTION_PROFILES:
			_add_error(issues, "weapon_attack_motion_profile", "weapon", weapon_id, "Unsupported attack_motion_profile '%s'." % attack_motion_profile)
		if _weapon_damage(weapon) <= 0.0:
			_add_error(issues, "weapon_damage", "weapon", weapon_id, "Weapon damage must be positive.")
		if _weapon_cooldown(weapon) <= 0.0:
			_add_error(issues, "weapon_cooldown", "weapon", weapon_id, "Weapon cooldown must be positive.")
		if _weapon_range(weapon) <= 0.0:
			_add_error(issues, "weapon_range", "weapon", weapon_id, "Weapon range must be positive.")
		var tags_variant: Variant = _value(weapon, "tags", [])
		var normalized_tags: Array[String] = []
		if tags_variant is Array:
			var invalid_tags := WeaponTagRuntimeRef.list_noncanonical_gameplay_tags(tags_variant)
			if not invalid_tags.is_empty():
				_add_error(issues, "weapon_tags", "weapon", weapon_id, "Non-canonical gameplay tags: %s" % ", ".join(invalid_tags))
			for tag_variant in tags_variant:
				normalized_tags.append(WeaponTagRuntimeRef.normalize_tag(str(tag_variant)))
		_validate_weapon_attack_pattern(issues, weapon_id, weapon, normalized_tags)
		_validate_weapon_presentation_scale(issues, weapon_id, weapon)
		if bool(_value(weapon, "shop_enabled", true)) and not _is_placeholder_weapon(weapon) and int(_value(weapon, "price", 0)) <= 0:
			_add_error(issues, "weapon_price", "weapon", weapon_id, "Shop-enabled weapon must have a positive price.")

static func _validate_weapon_presentation_scale(
	issues: Array[Dictionary],
	weapon_id: String,
	weapon: Variant
) -> void:
	var icon_variant: Variant = _value(weapon, "icon", null)
	if not (icon_variant is Texture2D):
		return
	var scale_multiplier := float(_value(weapon, "orbit_scale_multiplier", 1.0))
	if scale_multiplier <= 0.0:
		_add_error(issues, "weapon_orbit_scale_multiplier", "weapon", weapon_id, "orbit_scale_multiplier must be positive.")
		return
	var icon := icon_variant as Texture2D
	var visible_size := CombatScaleSpecRef.texture_visible_size(icon)
	var screen_size := CombatScaleSpecRef.reference_screen_size(
		visible_size,
		CombatScaleSpecRef.EQUIPPED_WEAPON_ICON_SCALE * scale_multiplier
	)
	var screen_max_dimension := maxf(screen_size.x, screen_size.y)
	var allowed_icon_range: Vector2 = CombatScaleSpecRef.EQUIPPED_WEAPON_SCREEN_MAX_RANGE
	if not CombatScaleSpecRef.is_value_in_range(screen_max_dimension, allowed_icon_range):
		_add_error(
			issues,
			"weapon_presentation_scale",
			"weapon",
			weapon_id,
			"Equipped icon renders %.1f px on its longest side at the reference view; expected %s px."
				% [screen_max_dimension, CombatScaleSpecRef.describe_range(allowed_icon_range)]
		)
	var radius_multiplier := float(_value(weapon, "orbit_radius_multiplier", 1.0))
	var resolved_radius := CombatScaleSpecRef.EQUIPPED_WEAPON_ORBIT_RADIUS * radius_multiplier
	var allowed_radius_range: Vector2 = CombatScaleSpecRef.EQUIPPED_WEAPON_ORBIT_RADIUS_RANGE
	if not CombatScaleSpecRef.is_value_in_range(resolved_radius, allowed_radius_range):
		_add_error(
			issues,
			"weapon_orbit_radius",
			"weapon",
			weapon_id,
			"Equipped orbit radius resolves to %.1f world units; expected %s."
				% [resolved_radius, CombatScaleSpecRef.describe_range(allowed_radius_range)]
		)

static func _validate_weapon_attack_pattern(
	issues: Array[Dictionary],
	weapon_id: String,
	weapon: Variant,
	tags: Array[String]
) -> void:
	var pattern_id := str(_value(weapon, "attack_pattern", "projectile"))
	if not WeaponAttackPatternRuntimeRef.is_supported(pattern_id):
		_add_error(issues, "weapon_attack_pattern", "weapon", weapon_id, "Unsupported attack pattern '%s'." % pattern_id)
		return
	var projectile_count := int(_value(weapon, "projectiles_per_attack", 1))
	var spread_degrees := float(_value(weapon, "spread_degrees", 0.0))
	var damage_multiplier := float(_value(weapon, "per_projectile_damage_multiplier", 1.0))
	var hit_radius := float(_value(weapon, "projectile_hit_radius", 5.0))
	var pierce := int(_value(weapon, "pierce", 0))
	var knockback := float(_value(weapon, "knockback", 0.0))
	var max_targets := int(_value(weapon, "max_targets", 8))
	if projectile_count < 1 or projectile_count > 7:
		_add_error(issues, "weapon_projectile_count", "weapon", weapon_id, "projectiles_per_attack must stay between 1 and 7.")
	if spread_degrees < 0.0 or spread_degrees > 90.0:
		_add_error(issues, "weapon_spread", "weapon", weapon_id, "spread_degrees must stay between 0 and 90.")
	if damage_multiplier < 0.05 or damage_multiplier > 2.0:
		_add_error(issues, "weapon_projectile_damage_multiplier", "weapon", weapon_id, "per_projectile_damage_multiplier must stay between 0.05 and 2.0.")
	if hit_radius < 2.0 or hit_radius > 64.0:
		_add_error(issues, "weapon_hit_radius", "weapon", weapon_id, "projectile_hit_radius must stay between 2 and 64.")
	if pierce < 0 or pierce > 8:
		_add_error(issues, "weapon_pierce", "weapon", weapon_id, "pierce must stay between 0 and 8.")
	if knockback < 0.0 or knockback > 500.0:
		_add_error(issues, "weapon_knockback", "weapon", weapon_id, "knockback must stay between 0 and 500.")
	if max_targets < 1 or max_targets > 64:
		_add_error(issues, "weapon_max_targets", "weapon", weapon_id, "max_targets must stay between 1 and 64.")

	var required_tag_by_pattern: Dictionary = {
		WeaponAttackPatternRuntimeRef.SPREAD: "spread",
		WeaponAttackPatternRuntimeRef.MELEE_ARC: "melee",
		WeaponAttackPatternRuntimeRef.MINE: "mine",
		WeaponAttackPatternRuntimeRef.WAVE: "wave",
		WeaponAttackPatternRuntimeRef.ORBIT: "orbit",
		WeaponAttackPatternRuntimeRef.RETURNING: "thrown"
	}
	if required_tag_by_pattern.has(pattern_id) and str(required_tag_by_pattern[pattern_id]) not in tags:
		_add_error(issues, "weapon_pattern_tag", "weapon", weapon_id, "Attack pattern '%s' requires its canonical '%s' tag." % [pattern_id, required_tag_by_pattern[pattern_id]])
	for expected_pattern_variant in required_tag_by_pattern.keys():
		var expected_pattern := str(expected_pattern_variant)
		var pattern_tag := str(required_tag_by_pattern[expected_pattern])
		if pattern_tag in tags and pattern_id != expected_pattern:
			_add_error(issues, "weapon_tag_pattern", "weapon", weapon_id, "Tag '%s' requires attack pattern '%s'." % [pattern_tag, expected_pattern])

	match pattern_id:
		WeaponAttackPatternRuntimeRef.SPREAD:
			if projectile_count < 2 or spread_degrees <= 0.0:
				_add_error(issues, "weapon_spread_profile", "weapon", weapon_id, "Spread weapons require at least two projectiles and positive spread.")
		WeaponAttackPatternRuntimeRef.MELEE_ARC:
			if float(_value(weapon, "melee_reach", 0.0)) < 32.0 or float(_value(weapon, "melee_arc_degrees", 0.0)) < 20.0 or float(_value(weapon, "melee_duration", 0.0)) < 0.08:
				_add_error(issues, "weapon_melee_profile", "weapon", weapon_id, "Melee weapons require bounded reach, arc, and duration values.")
		WeaponAttackPatternRuntimeRef.MINE:
			var arm_seconds := float(_value(weapon, "mine_arm_seconds", -1.0))
			var trigger_radius := float(_value(weapon, "mine_trigger_radius", 0.0))
			var effect_radius := float(_value(weapon, "effect_radius", 0.0))
			if arm_seconds < 0.0 or trigger_radius < 16.0 or effect_radius < trigger_radius or float(_value(weapon, "mine_placement_distance", 0.0)) < 24.0:
				_add_error(issues, "weapon_mine_profile", "weapon", weapon_id, "Mines require valid arm time, placement, trigger, and blast radii; blast radius cannot be smaller than trigger radius.")
			if _weapon_projectile_lifetime(weapon) <= arm_seconds:
				_add_error(issues, "weapon_mine_lifetime", "weapon", weapon_id, "Mine lifetime must exceed its arm time.")
		WeaponAttackPatternRuntimeRef.ORBIT:
			if float(_value(weapon, "orbit_radius", 0.0)) < 24.0 or float(_value(weapon, "orbit_angular_speed", 0.0)) < 0.5 or float(_value(weapon, "repeat_hit_interval", 0.0)) < 0.05:
				_add_error(issues, "weapon_orbit_profile", "weapon", weapon_id, "Orbit weapons require valid radius, angular speed, and repeat-hit interval values.")
		WeaponAttackPatternRuntimeRef.RETURNING:
			var return_after_seconds := float(_value(weapon, "return_after_seconds", 0.0))
			var return_speed_multiplier := float(_value(weapon, "return_speed_multiplier", 0.0))
			var return_damage_multiplier := float(_value(weapon, "return_damage_multiplier", 0.0))
			if return_after_seconds < 0.1 or return_after_seconds >= _weapon_projectile_lifetime(weapon):
				_add_error(issues, "weapon_return_timing", "weapon", weapon_id, "Returning weapons require return_after_seconds within their projectile lifetime.")
			if return_speed_multiplier < 0.5 or return_speed_multiplier > 3.0:
				_add_error(issues, "weapon_return_speed", "weapon", weapon_id, "Returning weapons require return_speed_multiplier between 0.5 and 3.0.")
			if return_damage_multiplier < 0.1 or return_damage_multiplier > 2.0:
				_add_error(issues, "weapon_return_damage", "weapon", weapon_id, "Returning weapons require return_damage_multiplier between 0.1 and 2.0.")
		_:
			pass

static func _validate_items(issues: Array[Dictionary], items: Dictionary, weapons: Dictionary) -> void:
	var authored_status_ids := _build_authored_weapon_status_ids(weapons)
	for item_id in _sorted_keys(items):
		var item: Variant = items[item_id]
		if item == null or not (item is Object):
			_add_error(issues, "item_type", "item", item_id, "Item entry must be a Resource/Object.")
			continue
		_validate_embedded_id(issues, "item", item_id, item)
		if str(_value(item, "name", "")).strip_edges() == "":
			_add_error(issues, "item_name", "item", item_id, "Item is missing name.")
		if int(_value(item, "price", 0)) <= 0:
			_add_error(issues, "item_price", "item", item_id, "Item price must be positive.")
		if int(_value(item, "stack_limit", 0)) <= 0:
			_add_error(issues, "item_stack_limit", "item", item_id, "Item stack_limit must be positive.")
		if not (_value(item, "icon", null) is Texture2D):
			_add_error(issues, "item_icon", "item", item_id, "Item icon is missing or failed to load.")
		var reward_tier := int(_value(item, "reward_tier", 0))
		if reward_tier < 1 or reward_tier > 3:
			_add_error(issues, "item_reward_tier", "item", item_id, "Item reward_tier must stay between 1 and 3.")
		var rarity := str(_value(item, "rarity", "")).to_lower()
		if rarity not in SUPPORTED_RARITIES:
			_add_error(issues, "item_rarity", "item", item_id, "Unsupported rarity '%s'." % rarity)
		var stat_modifiers_variant: Variant = _value(item, "stat_modifiers", {})
		if stat_modifiers_variant is Dictionary:
			for stat_id_variant in (stat_modifiers_variant as Dictionary).keys():
				var item_stat_id := str(stat_id_variant)
				if not StatBlockRef.is_supported_stat(item_stat_id):
					_add_error(issues, "item_stat_modifier", "item", item_id, "stat_modifiers uses unsupported stat '%s'." % item_stat_id)
		var rules_variant: Variant = _value(item, "weapon_tag_stat_bonuses", [])
		if rules_variant is Array:
			for rule_variant in rules_variant:
				if not (rule_variant is Dictionary):
					_add_error(issues, "item_tag_bonus_type", "item", item_id, "weapon_tag_stat_bonuses contains a non-dictionary rule.")
					continue
				var rule: Dictionary = rule_variant
				var tag := WeaponTagRuntimeRef.normalize_tag(str(rule.get("tag", "")))
				if tag == "" or not WeaponTagRuntimeRef.is_canonical_gameplay_tag(tag):
					_add_error(issues, "item_tag_bonus_tag", "item", item_id, "weapon_tag_stat_bonuses targets invalid tag '%s'." % tag)
				var stat_id := str(rule.get("stat_id", "")).strip_edges()
				if stat_id == "":
					_add_error(issues, "item_tag_bonus_stat", "item", item_id, "weapon_tag_stat_bonuses contains an empty stat_id.")
				elif not WeaponTagRuntimeRef.is_supported_weapon_bonus_stat(stat_id):
					_add_error(issues, "item_tag_bonus_unsupported_stat", "item", item_id, "weapon_tag_stat_bonuses uses unsupported weapon stat '%s'." % stat_id)
		_validate_item_stat_conversion_rules(issues, item_id, _value(item, "stat_conversion_rules", []))
		_validate_item_runtime_rules(issues, item_id, _value(item, "runtime_rules", []), authored_status_ids)

static func _validate_item_stat_conversion_rules(
	issues: Array[Dictionary],
	item_id: String,
	rules_variant: Variant
) -> void:
	if not (rules_variant is Array):
		_add_error(issues, "item_conversion_rules_type", "item", item_id, "stat_conversion_rules must be an array.")
		return
	for rule_variant in rules_variant:
		if not (rule_variant is Dictionary):
			_add_error(issues, "item_conversion_rule_type", "item", item_id, "stat_conversion_rules contains a non-dictionary rule.")
			continue
		var rule: Dictionary = rule_variant
		var rule_id := str(rule.get("id", "")).strip_edges()
		var source_stat_id := str(rule.get("source_stat_id", "")).strip_edges()
		var target_stat_id := str(rule.get("target_stat_id", "")).strip_edges()
		if rule_id == "":
			_add_error(issues, "item_conversion_rule_id", "item", item_id, "Item stat-conversion rule is missing id.")
		if str(rule.get("display_text", "")).strip_edges() == "":
			_add_error(issues, "item_conversion_rule_display", "item", item_id, "Item stat-conversion rule '%s' is missing exact display_text." % rule_id)
		if not StatBlockRef.is_supported_stat(source_stat_id):
			_add_error(issues, "item_conversion_source_stat", "item", item_id, "Item stat-conversion rule '%s' uses unsupported source stat '%s'." % [rule_id, source_stat_id])
		if not StatBlockRef.is_supported_stat(target_stat_id):
			_add_error(issues, "item_conversion_target_stat", "item", item_id, "Item stat-conversion rule '%s' uses unsupported target stat '%s'." % [rule_id, target_stat_id])
		if float(rule.get("source_step", 0.0)) <= 0.0:
			_add_error(issues, "item_conversion_source_step", "item", item_id, "Item stat-conversion rule '%s' requires a positive source_step." % rule_id)
		if is_zero_approx(float(rule.get("amount_per_step", 0.0))):
			_add_error(issues, "item_conversion_amount", "item", item_id, "Item stat-conversion rule '%s' requires a non-zero amount_per_step." % rule_id)
		if int(rule.get("max_steps", 0)) <= 0:
			_add_error(issues, "item_conversion_max_steps", "item", item_id, "Item stat-conversion rule '%s' requires positive max_steps." % rule_id)
		var effect_tags := WeaponTagRuntimeRef.resolve_effect_tags(rule.get("effect_tags", []))
		if not effect_tags.is_empty() and not WeaponTagRuntimeRef.is_supported_weapon_bonus_stat(target_stat_id):
			_add_error(issues, "item_conversion_weapon_stat", "item", item_id, "Item stat-conversion rule '%s' uses unsupported tagged-weapon stat '%s'." % [rule_id, target_stat_id])
		for effect_tag in effect_tags:
			if not WeaponTagRuntimeRef.is_canonical_gameplay_tag(effect_tag):
				_add_error(issues, "item_conversion_effect_tag", "item", item_id, "Item stat-conversion rule '%s' uses non-canonical effect tag '%s'." % [rule_id, effect_tag])

static func _validate_item_runtime_rules(
	issues: Array[Dictionary],
	item_id: String,
	rules_variant: Variant,
	authored_status_ids: Array[String]
) -> void:
	if not (rules_variant is Array):
		_add_error(issues, "item_runtime_rules_type", "item", item_id, "runtime_rules must be an array.")
		return
	for rule_variant in rules_variant:
		if not (rule_variant is Dictionary):
			_add_error(issues, "item_runtime_rule_type", "item", item_id, "runtime_rules contains a non-dictionary rule.")
			continue
		var rule: Dictionary = rule_variant
		var rule_id := str(rule.get("id", "")).strip_edges()
		var effect_id := str(rule.get("effect", PlayerPassiveRuntimeRef.DEFAULT_EFFECT))
		var trigger_id := str(rule.get("trigger", ""))
		if rule_id == "":
			_add_error(issues, "item_runtime_rule_id", "item", item_id, "Item runtime rule is missing id.")
		if str(rule.get("display_text", "")).strip_edges() == "":
			_add_error(issues, "item_runtime_rule_display", "item", item_id, "Item runtime rule '%s' is missing exact display_text." % rule_id)
		if effect_id not in PlayerPassiveRuntimeRef.SUPPORTED_EFFECTS:
			_add_error(issues, "item_runtime_effect", "item", item_id, "Item runtime rule '%s' uses unsupported effect '%s'." % [rule_id, effect_id])
		if trigger_id not in PlayerPassiveRuntimeRef.SUPPORTED_TRIGGERS:
			_add_error(issues, "item_runtime_trigger", "item", item_id, "Item runtime rule '%s' uses unsupported trigger '%s'." % [rule_id, trigger_id])
		if effect_id != PlayerPassiveRuntimeRef.REWARD_PROC_EFFECT and float(rule.get("duration", 0.0)) <= 0.0:
			_add_error(issues, "item_runtime_duration", "item", item_id, "Item runtime rule '%s' requires a positive duration." % rule_id)
		if effect_id == PlayerPassiveRuntimeRef.THRESHOLD_EFFECT and int(rule.get("threshold", 0)) <= 0:
			_add_error(issues, "item_runtime_threshold", "item", item_id, "Threshold item rule '%s' requires a positive threshold." % rule_id)
		if effect_id == PlayerPassiveRuntimeRef.REWARD_PROC_EFFECT:
			if int(rule.get("reward_gold", 0)) <= 0:
				_add_error(issues, "item_runtime_reward_gold", "item", item_id, "Reward-proc item rule '%s' requires positive reward_gold." % rule_id)
			if float(rule.get("trigger_progress_threshold", 0.0)) <= 0.0:
				_add_error(issues, "item_runtime_reward_threshold", "item", item_id, "Reward-proc item rule '%s' requires a positive trigger_progress_threshold." % rule_id)
		if rule.has("max_health_fraction"):
			var max_health_fraction := float(rule.get("max_health_fraction", 0.0))
			if max_health_fraction <= 0.0 or max_health_fraction > 1.0:
				_add_error(issues, "item_runtime_health_fraction", "item", item_id, "Item runtime rule '%s' max_health_fraction must be above 0 and at most 1." % rule_id)
		for required_tag in WeaponTagRuntimeRef.resolve_effect_tags(rule.get("required_source_weapon_tags", [])):
			if not WeaponTagRuntimeRef.is_canonical_gameplay_tag(required_tag):
				_add_error(issues, "item_runtime_source_tag", "item", item_id, "Item runtime rule '%s' requires non-canonical source tag '%s'." % [rule_id, required_tag])
		var required_status_ids_variant: Variant = rule.get("required_status_ids", [])
		if not (required_status_ids_variant is Array):
			_add_error(issues, "item_runtime_status_ids_type", "item", item_id, "Item runtime rule '%s' required_status_ids must be an array." % rule_id)
		else:
			for required_status_id_variant in required_status_ids_variant:
				var required_status_id := str(required_status_id_variant).strip_edges()
				if required_status_id == "":
					_add_error(issues, "item_runtime_status_id", "item", item_id, "Item runtime rule '%s' contains an empty required status id." % rule_id)
				elif required_status_id not in authored_status_ids:
					_add_error(issues, "item_runtime_status_unknown", "item", item_id, "Item runtime rule '%s' requires status '%s', but no weapon authors it." % [rule_id, required_status_id])
		if effect_id == PlayerPassiveRuntimeRef.REWARD_PROC_EFFECT:
			continue
		var modifiers_variant: Variant = rule.get("modifiers", [])
		if not (modifiers_variant is Array) or (modifiers_variant as Array).is_empty():
			_add_error(issues, "item_runtime_modifiers", "item", item_id, "Item runtime rule '%s' requires at least one modifier." % rule_id)
			continue
		for modifier_variant in modifiers_variant:
			if not (modifier_variant is Dictionary):
				_add_error(issues, "item_runtime_modifier_type", "item", item_id, "Item runtime rule '%s' contains a non-dictionary modifier." % rule_id)
				continue
			var modifier: Dictionary = modifier_variant
			var stat_id := str(modifier.get("stat_id", ""))
			if not StatBlockRef.is_supported_stat(stat_id):
				_add_error(issues, "item_runtime_stat", "item", item_id, "Item runtime rule '%s' uses unsupported stat '%s'." % [rule_id, stat_id])
			if is_zero_approx(float(modifier.get("amount", 0.0))):
				_add_error(issues, "item_runtime_amount", "item", item_id, "Item runtime rule '%s' contains a zero modifier." % rule_id)
			var effect_tags := WeaponTagRuntimeRef.resolve_effect_tags(modifier.get("effect_tags", []))
			if not effect_tags.is_empty() and not WeaponTagRuntimeRef.is_supported_weapon_bonus_stat(stat_id):
				_add_error(issues, "item_runtime_weapon_stat", "item", item_id, "Item runtime rule '%s' uses unsupported tagged-weapon stat '%s'." % [rule_id, stat_id])
			for effect_tag in effect_tags:
				if not WeaponTagRuntimeRef.is_canonical_gameplay_tag(effect_tag):
					_add_error(issues, "item_runtime_effect_tag", "item", item_id, "Item runtime rule '%s' uses non-canonical effect tag '%s'." % [rule_id, effect_tag])

static func _build_authored_weapon_status_ids(weapons: Dictionary) -> Array[String]:
	var status_ids: Array[String] = []
	for weapon_variant in weapons.values():
		var status_id := str(_value(weapon_variant, "on_hit_status_id", "")).strip_edges()
		if status_id == "" or status_id in status_ids:
			continue
		status_ids.append(status_id)
	status_ids.sort()
	return status_ids

static func _validate_enemies(issues: Array[Dictionary], enemies: Dictionary) -> void:
	for enemy_id in _sorted_keys(enemies):
		var enemy: Variant = enemies[enemy_id]
		if enemy == null or not (enemy is Object):
			_add_error(issues, "enemy_type", "enemy", enemy_id, "Enemy entry must be a Resource/Object.")
			continue
		_validate_embedded_id(issues, "enemy", enemy_id, enemy)
		if str(_value(enemy, "display_name", "")).strip_edges() == "":
			_add_warning(issues, "enemy_display_name", "enemy", enemy_id, "Enemy is missing display_name.")
		if float(_value(enemy, "max_hp", 0.0)) <= 0.0:
			_add_error(issues, "enemy_max_hp", "enemy", enemy_id, "Enemy max_hp must be positive.")
		if float(_value(enemy, "move_speed", -1.0)) < 0.0:
			_add_error(issues, "enemy_move_speed", "enemy", enemy_id, "Enemy move_speed cannot be negative.")
		var movement_profile := str(_value(enemy, "movement_profile", "")).strip_edges()
		if movement_profile not in SUPPORTED_ENEMY_MOVEMENT_PROFILES:
			_add_error(issues, "enemy_movement_profile", "enemy", enemy_id, "Unsupported movement profile '%s'." % movement_profile)
		var combat_profile := str(_value(enemy, "combat_profile", "")).strip_edges()
		if not EnemyCombatProfileRuntimeRef.is_supported(combat_profile):
			_add_error(issues, "enemy_combat_profile", "enemy", enemy_id, "Unsupported combat profile '%s'." % combat_profile)
		var collision_radius := float(_value(enemy, "collision_radius", 0.0))
		if collision_radius < 8.0 or collision_radius > 72.0:
			_add_error(issues, "enemy_collision_radius", "enemy", enemy_id, "Enemy collision radius must stay between 8 and 72.")
		if float(_value(enemy, "contact_damage", -1.0)) < 0.0:
			_add_error(issues, "enemy_contact_damage", "enemy", enemy_id, "Enemy contact_damage cannot be negative.")
		var ranged_damage := float(_value(enemy, "ranged_damage", -1.0))
		var ranged_interval := float(_value(enemy, "ranged_interval_seconds", -1.0))
		var ranged_attack_range := float(_value(enemy, "ranged_attack_range", -1.0))
		var projectile_count := int(_value(enemy, "projectile_count", 1))
		var projectile_spread := float(_value(enemy, "projectile_spread_degrees", 0.0))
		var projectile_speed := float(_value(enemy, "projectile_speed", 0.0))
		var projectile_lifetime := float(_value(enemy, "projectile_lifetime_seconds", 0.0))
		if ranged_damage < 0.0:
			_add_error(issues, "enemy_ranged_damage", "enemy", enemy_id, "Enemy ranged_damage cannot be negative.")
		if projectile_count < 1 or projectile_count > 7:
			_add_error(issues, "enemy_projectile_count", "enemy", enemy_id, "Enemy projectile_count must stay between 1 and 7.")
		if projectile_spread < 0.0 or projectile_spread > 90.0:
			_add_error(issues, "enemy_projectile_spread", "enemy", enemy_id, "Enemy projectile spread must stay between 0 and 90 degrees.")
		if ranged_damage > 0.0:
			if ranged_interval <= 0.0:
				_add_error(issues, "enemy_ranged_interval", "enemy", enemy_id, "Ranged enemies require a positive attack interval.")
			if ranged_attack_range <= 0.0:
				_add_error(issues, "enemy_ranged_range", "enemy", enemy_id, "Ranged enemies require a positive attack range.")
			if projectile_speed <= 0.0:
				_add_error(issues, "enemy_projectile_speed", "enemy", enemy_id, "Ranged enemies require positive projectile speed.")
			if projectile_lifetime < 0.1 or projectile_lifetime > 5.0:
				_add_error(issues, "enemy_projectile_lifetime", "enemy", enemy_id, "Ranged projectile lifetime must stay between 0.1 and 5 seconds.")
			var projectile_path := str(_value(enemy, "projectile_texture_path", "")).strip_edges()
			if projectile_path == "" or not _resource_or_source_exists(projectile_path):
				_add_error(issues, "enemy_projectile_visual", "enemy", enemy_id, "Ranged enemy projectile visual is missing or invalid.")
		elif projectile_count != 1 or projectile_spread > 0.0:
			_add_error(issues, "enemy_melee_projectile_profile", "enemy", enemy_id, "Enemies without ranged damage cannot configure a projectile volley.")
		if enemy_id == "rift_caller" and (projectile_count != 3 or not is_equal_approx(projectile_spread, 18.0)):
			_add_error(issues, "rift_caller_volley_profile", "enemy", enemy_id, "Rift Caller requires its approved three-shot, 18-degree volley profile.")
		if enemy_id == "cinder_marshal":
			if _value(enemy, "is_boss", false) != true or movement_profile != "ranged_hold":
				_add_error(issues, "cinder_marshal_identity", "enemy", enemy_id, "Cinder Marshal must remain a ranged-hold boss.")
			if projectile_count != 1 or projectile_spread > 0.0:
				_add_error(issues, "cinder_marshal_aimed_profile", "enemy", enemy_id, "Cinder Marshal's base attack must remain one aimed projectile; its pressure runtime owns the barrage.")
		if enemy_id == "cinder_ram":
			if combat_profile != "committed_charger" or movement_profile != "chaser":
				_add_error(issues, "cinder_ram_identity", "enemy", enemy_id, "Cinder Ram must remain a committed chaser.")
			if _value(enemy, "is_boss", false) == true or ranged_damage > 0.0:
				_add_error(issues, "cinder_ram_role", "enemy", enemy_id, "Cinder Ram must remain a non-boss melee charger.")
		if enemy_id == "ash_lantern":
			if combat_profile != "area_denier" or movement_profile != "ranged_hold":
				_add_error(issues, "ash_lantern_identity", "enemy", enemy_id, "Ash Lantern must remain a spacing area-denial caster.")
			if _value(enemy, "is_boss", false) == true or ranged_damage > 0.0:
				_add_error(issues, "ash_lantern_role", "enemy", enemy_id, "Ash Lantern's threat must come from bounded hazard zones, not boss or projectile behavior.")
		if enemy_id == "pyre_archon":
			if _value(enemy, "is_boss", false) != true or movement_profile != "ranged_hold":
				_add_error(issues, "pyre_archon_identity", "enemy", enemy_id, "Pyre Archon must remain a ranged-hold control boss.")
			if projectile_count != 3 or not is_equal_approx(projectile_spread, 22.0):
				_add_error(issues, "pyre_archon_volley_profile", "enemy", enemy_id, "Pyre Archon's base pressure must remain the approved three-shot, 22-degree volley.")
		if enemy_id == "last_shade":
			if _value(enemy, "is_boss", false) != true or movement_profile != "chaser":
				_add_error(issues, "last_shade_identity", "enemy", enemy_id, "Last Shade must remain the committed final hunter boss.")
			if projectile_count != 3 or not is_equal_approx(projectile_spread, 20.0):
				_add_error(issues, "last_shade_volley_profile", "enemy", enemy_id, "Last Shade's base hunt pressure must remain the approved three-shot, 20-degree volley.")
		if enemy_id == "bone_captain":
			if combat_profile != "support_commander" or movement_profile != "ranged_hold":
				_add_error(issues, "bone_captain_identity", "enemy", enemy_id, "Bone Captain must remain a spacing support commander.")
			if _value(enemy, "is_boss", false) == true or ranged_damage <= 0.0:
				_add_error(issues, "bone_captain_role", "enemy", enemy_id, "Bone Captain must remain a non-boss ranged support threat.")
		if int(_value(enemy, "reward_gold", -1)) < 0 or int(_value(enemy, "reward_xp", -1)) < 0:
			_add_error(issues, "enemy_reward", "enemy", enemy_id, "Enemy rewards cannot be negative.")
		var visual_path := str(_value(enemy, "visual_texture_path", "")).strip_edges()
		if visual_path != "":
			if not _resource_or_source_exists(visual_path):
				_add_error(issues, "enemy_visual_missing", "enemy", enemy_id, "Enemy visual resource does not exist: %s" % visual_path)
			else:
				var visual_scale := float(_value(enemy, "visual_scale", 0.0))
				if visual_scale <= 0.0:
					_add_error(issues, "enemy_visual_scale", "enemy", enemy_id, "Enemy visual_scale must be positive.")
				else:
					_validate_enemy_presentation_scale(
						issues,
						enemy_id,
						enemy,
						visual_path,
						visual_scale,
						false,
						1,
						1
					)
		var directional_path := str(_value(enemy, "directional_locomotion_texture_path", "")).strip_edges()
		if directional_path != "":
			var directional_exists := _resource_or_source_exists(directional_path)
			if not directional_exists:
				_add_error(issues, "enemy_directional_visual_missing", "enemy", enemy_id, "Enemy directional locomotion resource does not exist: %s" % directional_path)
			var directional_scale := float(_value(enemy, "directional_locomotion_scale", 0.0))
			if directional_scale <= 0.0:
				_add_error(issues, "enemy_directional_visual_scale", "enemy", enemy_id, "Enemy directional locomotion scale must be positive.")
			var directional_columns := int(_value(enemy, "directional_locomotion_columns", 0))
			var directional_rows := int(_value(enemy, "directional_locomotion_rows", 0))
			var directional_grid_valid := (
				directional_columns >= 1
				and directional_columns <= 4
				and directional_rows >= 1
				and directional_rows <= 4
			)
			if not directional_grid_valid:
				_add_error(issues, "enemy_directional_visual_grid", "enemy", enemy_id, "Enemy directional locomotion grid must stay between 1 and 4 columns and rows.")
			var directional_fps := float(_value(enemy, "directional_locomotion_fps", 0.0))
			if directional_fps < 1.0 or directional_fps > 20.0:
				_add_error(issues, "enemy_directional_visual_fps", "enemy", enemy_id, "Enemy directional locomotion FPS must stay between 1 and 20.")
			var directional_offsets_variant: Variant = _value(enemy, "directional_locomotion_frame_offsets", [])
			if not (directional_offsets_variant is Array):
				_add_error(issues, "enemy_directional_visual_offsets_type", "enemy", enemy_id, "Enemy directional locomotion frame offsets must be an array.")
			elif not directional_offsets_variant.is_empty():
				var expected_offset_count := directional_columns * directional_rows
				if directional_offsets_variant.size() != expected_offset_count:
					_add_error(issues, "enemy_directional_visual_offsets_count", "enemy", enemy_id, "Enemy directional locomotion frame offsets must contain one Vector2 per atlas cell (%d expected)." % expected_offset_count)
				for offset_variant in directional_offsets_variant:
					if not (offset_variant is Vector2):
						_add_error(issues, "enemy_directional_visual_offset", "enemy", enemy_id, "Enemy directional locomotion frame offsets must contain only Vector2 values.")
						break
					var frame_offset := offset_variant as Vector2
					if not is_finite(frame_offset.x) or not is_finite(frame_offset.y) or absf(frame_offset.x) > 256.0 or absf(frame_offset.y) > 256.0:
						_add_error(issues, "enemy_directional_visual_offset", "enemy", enemy_id, "Enemy directional locomotion frame offsets must be finite and stay within 256 source pixels.")
						break
			if directional_exists and directional_scale > 0.0 and directional_grid_valid:
				_validate_enemy_presentation_scale(
					issues,
					enemy_id,
					enemy,
					directional_path,
					directional_scale,
					true,
					directional_columns,
					directional_rows
				)

static func _validate_enemy_presentation_scale(
	issues: Array[Dictionary],
	enemy_id: String,
	enemy: Variant,
	visual_path: String,
	visual_scale: float,
	is_directional_atlas: bool,
	columns: int,
	rows: int
) -> void:
	var texture := _load_texture_resource(visual_path)
	if texture == null:
		_add_error(issues, "enemy_visual_load", "enemy", enemy_id, "Enemy visual could not be loaded for presentation-scale validation: %s" % visual_path)
		return
	var visible_size := (
		CombatScaleSpecRef.directional_atlas_visible_size(texture, columns, rows)
		if is_directional_atlas
		else CombatScaleSpecRef.texture_visible_size(texture)
	)
	var screen_height := CombatScaleSpecRef.reference_screen_size(visible_size, visual_scale).y
	var allowed_range := CombatScaleSpecRef.enemy_screen_height_range(
		bool(_value(enemy, "is_boss", false)),
		bool(_value(enemy, "is_elite", false))
	)
	if not CombatScaleSpecRef.is_value_in_range(screen_height, allowed_range):
		var visual_label := "directional locomotion" if is_directional_atlas else "fallback visual"
		_add_error(
			issues,
			"enemy_presentation_scale",
			"enemy",
			enemy_id,
			"Enemy %s renders %.1f px tall at the reference view; expected %s px for its threat tier."
				% [visual_label, screen_height, CombatScaleSpecRef.describe_range(allowed_range)]
		)

static func _validate_portal_events(issues: Array[Dictionary], portal_events: Dictionary) -> void:
	for event_id in _sorted_keys(portal_events):
		var event_variant: Variant = portal_events[event_id]
		if not (event_variant is Dictionary):
			_add_error(issues, "portal_event_type", "portal_event", event_id, "Portal event must be a dictionary.")
			continue
		var event: Dictionary = event_variant
		_validate_embedded_id(issues, "portal_event", event_id, event)
		if str(event.get("title", "")).strip_edges() == "":
			_add_error(issues, "portal_event_title", "portal_event", event_id, "Portal event is missing title.")
		if float(event.get("base_weight", 0.0)) <= 0.0:
			_add_error(issues, "portal_event_weight", "portal_event", event_id, "Portal event base_weight must be positive.")
		if int(event.get("reward_count", 0)) < 0:
			_add_error(issues, "portal_event_reward_count", "portal_event", event_id, "Portal event reward_count cannot be negative.")
		for severity_field in ["risk_level", "reward_level"]:
			var severity := str(event.get(severity_field, "")).strip_edges().to_lower()
			if not PortalRiskRewardRuntimeRef.is_authored_severity(severity):
				_add_error(
					issues,
					"portal_event_%s" % severity_field,
					"portal_event",
					event_id,
					"Portal event %s must be one of: %s."
						% [severity_field, ", ".join(PortalRiskRewardRuntimeRef.AUTHORED_SEVERITY_LEVELS)]
				)
		var risk_level := str(event.get("risk_level", "")).strip_edges().to_lower()
		var reward_level := str(event.get("reward_level", "")).strip_edges().to_lower()
		if (
			PortalRiskRewardRuntimeRef.is_authored_severity(risk_level)
			and PortalRiskRewardRuntimeRef.is_authored_severity(reward_level)
			and risk_level != reward_level
		):
			_add_error(
				issues,
				"portal_event_unbalanced_severity",
				"portal_event",
				event_id,
				"Portal event hidden downside and upside must use the same severity level."
			)

static func _validate_effect_definitions(
	issues: Array[Dictionary],
	category: String,
	definitions: Dictionary,
	validate_mutation_fields: bool
) -> void:
	for definition_id in _sorted_keys(definitions):
		var definition_variant: Variant = definitions[definition_id]
		if not (definition_variant is Dictionary):
			_add_error(issues, "%s_type" % category, category, definition_id, "Definition must be a dictionary.")
			continue
		var definition: Dictionary = definition_variant
		_validate_embedded_id(issues, category, definition_id, definition)
		if str(definition.get("title", "")).strip_edges() == "":
			_add_error(issues, "%s_title" % category, category, definition_id, "Definition is missing title.")
		var stack_policy := str(definition.get("stack_policy", ""))
		if stack_policy not in PortalMutationRuntimeRef.SUPPORTED_STACK_POLICIES:
			_add_error(issues, "%s_stack_policy" % category, category, definition_id, "Unsupported stack_policy '%s'." % stack_policy)
		if validate_mutation_fields:
			var mutation_tier := str(definition.get("mutation_tier", ""))
			if mutation_tier not in SUPPORTED_MUTATION_TIERS:
				_add_error(issues, "portal_mutation_tier", category, definition_id, "Unsupported mutation_tier '%s'." % mutation_tier)
			var duration := str(definition.get("duration", ""))
			if duration not in SUPPORTED_DURATIONS:
				_add_error(issues, "portal_mutation_duration", category, definition_id, "Unsupported duration '%s'." % duration)
		var effects_variant: Variant = definition.get("effects", [])
		if not (effects_variant is Array) or (effects_variant as Array).is_empty():
			_add_error(issues, "%s_effects" % category, category, definition_id, "Definition must contain at least one effect.")
			continue
		for effect_variant in effects_variant:
			if not (effect_variant is Dictionary):
				_add_error(issues, "%s_effect_type" % category, category, definition_id, "Definition contains a non-dictionary effect.")
				continue
			var effect: Dictionary = effect_variant
			var effect_type := str(effect.get("type", ""))
			if effect_type not in PortalMutationRuntimeRef.SUPPORTED_EFFECT_TYPES:
				_add_error(issues, "%s_effect_kind" % category, category, definition_id, "Unsupported effect type '%s'." % effect_type)
		var tags_variant: Variant = definition.get("effect_tags", [])
		if tags_variant is Array:
			var invalid_tags := WeaponTagRuntimeRef.list_noncanonical_gameplay_tags(tags_variant)
			if not invalid_tags.is_empty():
				_add_error(issues, "%s_effect_tags" % category, category, definition_id, "Non-canonical effect_tags: %s" % ", ".join(invalid_tags))

static func _validate_set_bonuses(issues: Array[Dictionary], set_bonuses: Dictionary) -> void:
	for family_id in _sorted_keys(set_bonuses):
		var definition_variant: Variant = set_bonuses[family_id]
		if not (definition_variant is Dictionary):
			_add_error(issues, "set_bonus_type", "set_bonus", family_id, "Set-bonus definition must be a dictionary.")
			continue
		var definition: Dictionary = definition_variant
		var embedded_id := str(definition.get("id", "")).strip_edges()
		if embedded_id != "" and embedded_id != family_id:
			_add_error(issues, "set_bonus_id_mismatch", "set_bonus", family_id, "Embedded id '%s' does not match registry key." % embedded_id)
		var thresholds_variant: Variant = definition.get("thresholds", [])
		if not (thresholds_variant is Array):
			_add_error(issues, "set_bonus_thresholds_type", "set_bonus", family_id, "thresholds must be an array.")
			continue
		var pieces_present: Dictionary = {}
		for threshold_variant in thresholds_variant:
			if not (threshold_variant is Dictionary):
				_add_error(issues, "set_bonus_threshold_type", "set_bonus", family_id, "thresholds contains a non-dictionary entry.")
				continue
			var threshold: Dictionary = threshold_variant
			var pieces := int(threshold.get("pieces", 0))
			if pieces <= 0:
				_add_error(issues, "set_bonus_pieces", "set_bonus", family_id, "Threshold pieces must be positive.")
				continue
			if pieces_present.has(pieces):
				_add_error(issues, "set_bonus_duplicate_threshold", "set_bonus", family_id, "Duplicate %d-piece threshold." % pieces)
			pieces_present[pieces] = true
			var effects_variant: Variant = threshold.get("effects", [])
			if not (effects_variant is Array) or (effects_variant as Array).is_empty():
				_add_error(issues, "set_bonus_effects", "set_bonus", family_id, "%d-piece threshold must contain effects." % pieces)
		for required_pieces in REQUIRED_SET_THRESHOLDS:
			if not pieces_present.has(required_pieces):
				_add_error(issues, "set_bonus_required_threshold", "set_bonus", family_id, "Missing required %d-piece threshold." % required_pieces)

static func _validate_embedded_id(
	issues: Array[Dictionary],
	category: String,
	registry_id: String,
	entry: Variant
) -> void:
	var embedded_id := str(_value(entry, "id", "")).strip_edges()
	if embedded_id == "":
		_add_error(issues, "%s_id_missing" % category, category, registry_id, "Entry is missing id.")
	elif embedded_id != registry_id:
		_add_error(issues, "%s_id_mismatch" % category, category, registry_id, "Embedded id '%s' does not match registry key." % embedded_id)

static func _weapon_family(weapon: Object) -> String:
	if weapon.has_method("get_family_value"):
		return str(weapon.call("get_family_value")).strip_edges()
	return str(_value(weapon, "family", "")).strip_edges()

static func _weapon_damage(weapon: Object) -> float:
	if weapon.has_method("get_damage_value"):
		return float(weapon.call("get_damage_value"))
	return float(_value(weapon, "base_damage", 0.0))

static func _weapon_cooldown(weapon: Object) -> float:
	if weapon.has_method("get_cooldown_value"):
		return float(weapon.call("get_cooldown_value"))
	return float(_value(weapon, "cooldown", 0.0))

static func _weapon_range(weapon: Object) -> float:
	if weapon.has_method("get_attack_range_value"):
		return float(weapon.call("get_attack_range_value"))
	return float(_value(weapon, "range", 0.0))

static func _weapon_projectile_lifetime(weapon: Object) -> float:
	if weapon.has_method("get_projectile_lifetime_value"):
		return float(weapon.call("get_projectile_lifetime_value"))
	return float(_value(weapon, "projectile_lifetime", 0.0))

static func _is_placeholder_weapon(weapon: Object) -> bool:
	var weapon_id := str(_value(weapon, "id", ""))
	return weapon_id.contains("placeholder") or _weapon_family(weapon).contains("placeholder")

static func _dictionary_property(owner: Object, property_name: String) -> Dictionary:
	var value: Variant = owner.get(property_name)
	return value if value is Dictionary else {}

static func _resource_or_source_exists(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)

static func _load_texture_resource(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D

static func _value(entry: Variant, key: String, fallback: Variant) -> Variant:
	if entry is Dictionary:
		return (entry as Dictionary).get(key, fallback)
	if entry is Object:
		var value: Variant = (entry as Object).get(key)
		return fallback if value == null else value
	return fallback

static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not (value is Array):
		return result
	for item in value:
		result.append(str(item).strip_edges())
	return result

static func _sorted_keys(dictionary: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in dictionary.keys():
		result.append(str(key))
	result.sort()
	return result

static func _add_error(issues: Array[Dictionary], code: String, category: String, entry_id: String, message: String) -> void:
	_add_issue(issues, "error", code, category, entry_id, message)

static func _add_warning(issues: Array[Dictionary], code: String, category: String, entry_id: String, message: String) -> void:
	_add_issue(issues, "warning", code, category, entry_id, message)

static func _add_issue(
	issues: Array[Dictionary],
	severity: String,
	code: String,
	category: String,
	entry_id: String,
	message: String
) -> void:
	issues.append({
		"severity": severity,
		"code": code,
		"category": category,
		"id": entry_id,
		"message": message
	})

static func _build_report(issues: Array[Dictionary], counts: Dictionary) -> Dictionary:
	var error_count := 0
	var warning_count := 0
	for issue in issues:
		if str(issue.get("severity", "")) == "error":
			error_count += 1
		elif str(issue.get("severity", "")) == "warning":
			warning_count += 1
	return {
		"valid": error_count == 0,
		"error_count": error_count,
		"warning_count": warning_count,
		"issues": issues.duplicate(true),
		"counts": counts.duplicate(true)
	}
