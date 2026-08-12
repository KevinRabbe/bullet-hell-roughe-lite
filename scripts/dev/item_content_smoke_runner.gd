extends SceneTree

const ItemDatabaseRef = preload("res://scripts/items/item_database.gd")
const ItemEffectPresentationRuntimeRef = preload("res://scripts/ui/item_effect_presentation_runtime.gd")
const ItemStatConversionRuntimeRef = preload("res://scripts/items/item_stat_conversion_runtime.gd")
const PlayerPassiveRuntimeRef = preload("res://scripts/player/player_passive_runtime.gd")
const ShopInventoryDetailRuntimeRef = preload("res://scripts/ui/shop_inventory_detail_runtime.gd")
const ShopOfferRuntimeRef = preload("res://scripts/game/shop_offer_runtime.gd")
const ContentValidatorRef = preload("res://scripts/dev/content_validator.gd")
const DataRegistryScript = preload("res://scripts/autoload/data_registry.gd")

const BATCH_ONE_ITEM_IDS: Array[String] = [
	"ashrunner_hide",
	"blood_price",
	"cinder_guard",
	"debt_collectors_seal",
	"gilded_hook",
	"grave_stitch",
	"infernal_coupon",
	"portal_compass",
	"ritual_refrain",
	"scatter_mechanism"
]

const BATCH_TWO_ITEM_IDS: Array[String] = [
	"black_candle",
	"black_primer",
	"grave_tithe",
	"last_ember",
	"rift_scar"
]

var _failures: Array[String] = []
var _conversion_source_values: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_validate_batch_inventory()
	_validate_direct_items()
	_validate_threshold_items()
	_validate_stacking_items()
	_validate_distance_item()
	_validate_critical_and_health_items()
	_validate_conversion_items()
	_validate_portal_reward_item()
	_validate_strict_failure_reporting()

	if _failures.is_empty():
		print("ITEM CONTENT SMOKE PASS | items=36 batch_items=15 behavioral=14")
		quit(0)
		return

	for failure in _failures:
		printerr("ITEM CONTENT SMOKE FAIL | %s" % failure)
	quit(1)

func _validate_batch_inventory() -> void:
	var items := ItemDatabaseRef.get_prototype_items()
	_expect(items.size() == 36, "Expected 36 item resources, found %d." % items.size())

	var offers := ShopOfferRuntimeRef.build_item_offer_pool()
	_expect(offers.size() == items.size(), "Shop item pool does not match the item database.")

	var batch_item_ids := BATCH_ONE_ITEM_IDS + BATCH_TWO_ITEM_IDS
	for item_id in batch_item_ids:
		var item := ItemDatabaseRef.get_item_by_id(item_id)
		_expect(item != null, "Missing Batch 1 item '%s'." % item_id)
		if item == null:
			continue
		_expect(item.icon != null, "Item '%s' has no loaded icon." % item_id)
		_expect(item.price > 0, "Item '%s' has no positive price." % item_id)
		_expect(item.description.strip_edges() != "", "Item '%s' has no description." % item_id)
		var detail := ShopInventoryDetailRuntimeRef.build_item_detail(item_id)
		var body := str(detail.get("body", ""))
		_expect(body.contains(item.category.to_upper()), "Item '%s' detail omits its category." % item_id)
		for rule in item.runtime_rules:
			_expect(
				body.contains(str(rule.get("display_text", ""))),
				"Item '%s' detail omits its triggered-effect text." % item_id
			)
		for rule in item.stat_conversion_rules:
			_expect(
				body.contains(str(rule.get("display_text", ""))),
				"Item '%s' detail omits its live-conversion text." % item_id
			)
		var offer := _find_offer(offers, item_id)
		_expect(not offer.is_empty(), "Item '%s' is absent from the Shop pool." % item_id)
		if not offer.is_empty():
			_expect(int(offer.get("price", 0)) == item.price, "Item '%s' Shop price is not data-authoritative." % item_id)
			_expect(str(offer.get("rarity", "")) == item.rarity, "Item '%s' Shop rarity does not match its resource." % item_id)

	for promoted_id in ["glass_scope", "soul_fuse"]:
		var promoted_item := ItemDatabaseRef.get_item_by_id(promoted_id)
		_expect(promoted_item != null and promoted_item.rarity == "rare", "Item '%s' was not promoted to Rare." % promoted_id)

func _validate_direct_items() -> void:
	var portal_compass := ItemDatabaseRef.get_item_by_id("portal_compass")
	_expect_stat(portal_compass, "portal_frequency", 0.12)
	_expect_stat(portal_compass, "portal_instability", 0.08)

	var gilded_hook := ItemDatabaseRef.get_item_by_id("gilded_hook")
	_expect_stat(gilded_hook, "coin_gain", 0.1)
	_expect_stat(gilded_hook, "pickup_range", 40.0)

	var infernal_coupon := ItemDatabaseRef.get_item_by_id("infernal_coupon")
	_expect_stat(infernal_coupon, "shop_discount", 0.12)
	_expect_stat(infernal_coupon, "reroll_cost", 0.2)
	var coupon_lines := ItemEffectPresentationRuntimeRef.build_stat_lines(infernal_coupon.stat_modifiers)
	_expect(coupon_lines.has("+20% REROLL COST"), "Infernal Coupon reroll cost is not presented as an exact percentage.")

	var blood_price := ItemDatabaseRef.get_item_by_id("blood_price")
	_expect_stat(blood_price, "max_hp", -15.0)
	_expect_stat(blood_price, "coin_gain", 0.2)
	_expect_stat(blood_price, "shop_discount", 0.1)

func _validate_threshold_items() -> void:
	var scatter_runtime := _runtime_for("scatter_mechanism")
	for shot_index in range(7):
		var early_adjustments: Array = scatter_runtime.trigger(
			"on_weapon_fired",
			{"source_weapon_tags": ["spread"], "trigger_progress": 1.0}
		)
		_expect(early_adjustments.is_empty(), "Scatter Mechanism activated before shot 8 (%d)." % (shot_index + 1))
	var scatter_adjustments: Array = scatter_runtime.trigger(
		"on_weapon_fired",
		{"source_weapon_tags": ["spread"], "trigger_progress": 1.0}
	)
	_expect_adjustment(scatter_adjustments, "attack_speed", 0.18, ["spread", "close_range"], "Scatter Mechanism activation")
	_expect_adjustment(scatter_runtime.tick(4.1), "attack_speed", -0.18, ["spread", "close_range"], "Scatter Mechanism expiry")

	var grave_runtime := _runtime_for("grave_stitch")
	for kill_index in range(4):
		var early_adjustments: Array = grave_runtime.trigger("on_enemy_kill", {"source_weapon_tags": ["necromancy"]})
		_expect(early_adjustments.is_empty(), "Grave Stitch activated before kill 5 (%d)." % (kill_index + 1))
	var grave_adjustments: Array = grave_runtime.trigger("on_enemy_kill", {"source_weapon_tags": ["necromancy"]})
	_expect_adjustment(grave_adjustments, "hp_regen", 2.0, [], "Grave Stitch activation")
	_expect_adjustment(grave_runtime.tick(5.1), "hp_regen", -2.0, [], "Grave Stitch expiry")

func _validate_stacking_items() -> void:
	var cinder_runtime := _runtime_for("cinder_guard")
	for stack_index in range(3):
		_expect_adjustment(
			cinder_runtime.trigger("on_damage_taken", {"damage": 5.0, "trigger_progress": 5.0}),
			"armor",
			1.0,
			[],
			"Cinder Guard stack %d" % (stack_index + 1)
		)
	_expect(cinder_runtime.trigger("on_damage_taken", {"damage": 5.0}).is_empty(), "Cinder Guard exceeded three stacks.")
	_expect_adjustment(cinder_runtime.tick(3.1), "armor", -3.0, [], "Cinder Guard expiry")

	var ritual_runtime := _runtime_for("ritual_refrain")
	_expect(
		ritual_runtime.trigger("on_status_released", {"source_weapon_tags": ["gun"], "status_id": "ritual_mark"}).is_empty(),
		"Ritual Refrain accepted a non-Ritual source."
	)
	_expect(
		ritual_runtime.trigger("on_status_released", {"source_weapon_tags": ["ritual"], "status_id": "devils_debt"}).is_empty(),
		"Ritual Refrain accepted the wrong released status."
	)
	for stack_index in range(2):
		_expect_adjustment(
			ritual_runtime.trigger("on_status_released", {"source_weapon_tags": ["ritual"], "status_id": "ritual_mark"}),
			"damage",
			0.1,
			["wave", "orbit"],
			"Ritual Refrain stack %d" % (stack_index + 1)
		)
	_expect(ritual_runtime.trigger("on_status_released", {"source_weapon_tags": ["ritual"], "status_id": "ritual_mark"}).is_empty(), "Ritual Refrain exceeded two stacks.")
	_expect_adjustment(ritual_runtime.tick(5.1), "damage", -0.2, ["wave", "orbit"], "Ritual Refrain expiry")

	var debt_runtime := _runtime_for("debt_collectors_seal")
	_expect(
		debt_runtime.trigger("on_status_released", {"source_weapon_tags": ["gun"], "status_id": "devils_debt"}).is_empty(),
		"Debt Collector's Seal accepted an unrelated source."
	)
	_expect(
		debt_runtime.trigger("on_status_released", {"source_weapon_tags": ["blood"], "status_id": "ritual_mark"}).is_empty(),
		"Debt Collector's Seal accepted the wrong released status."
	)
	for stack_index in range(2):
		_expect_adjustment(
			debt_runtime.trigger("on_status_released", {"source_weapon_tags": ["blood"], "status_id": "devils_debt"}),
			"damage",
			0.1,
			["blood", "melee", "thrown"],
			"Debt Collector's Seal stack %d" % (stack_index + 1)
		)
	_expect(debt_runtime.trigger("on_status_released", {"source_weapon_tags": ["thrown"], "status_id": "devils_debt"}).is_empty(), "Debt Collector's Seal exceeded two stacks.")
	_expect_adjustment(debt_runtime.tick(4.1), "damage", -0.2, ["blood", "melee", "thrown"], "Debt Collector's Seal expiry")

func _validate_distance_item() -> void:
	var runtime := _runtime_for("ashrunner_hide")
	_expect(runtime.trigger("on_distance_moved", {"trigger_progress": 599.0}).is_empty(), "Ashrunner Hide activated before 600 distance.")
	_expect_adjustment(
		runtime.trigger("on_distance_moved", {"trigger_progress": 1.0}),
		"dodge",
		0.12,
		[],
		"Ashrunner Hide activation"
	)
	_expect_adjustment(runtime.tick(3.1), "dodge", -0.12, [], "Ashrunner Hide expiry")

func _validate_critical_and_health_items() -> void:
	var primer_runtime := _runtime_for("black_primer")
	for hit_index in range(3):
		_expect(
			primer_runtime.trigger("on_critical_hit", {"trigger_progress": 1.0}).is_empty(),
			"Black Primer activated before critical hit 4 (%d)." % (hit_index + 1)
		)
	var primer_adjustments: Array = primer_runtime.trigger("on_critical_hit", {"trigger_progress": 1.0})
	_expect(primer_adjustments.size() == 2, "Black Primer did not return both Precision adjustments.")
	_expect_adjustment_present(primer_adjustments, "damage", 0.25, ["precision"], "Black Primer damage")
	_expect_adjustment_present(primer_adjustments, "attack_speed", 0.15, ["precision"], "Black Primer attack speed")
	var primer_expiry: Array = primer_runtime.tick(5.1)
	_expect_adjustment_present(primer_expiry, "damage", -0.25, ["precision"], "Black Primer damage expiry")
	_expect_adjustment_present(primer_expiry, "attack_speed", -0.15, ["precision"], "Black Primer attack speed expiry")

	var ember_runtime := _runtime_for("last_ember")
	_expect(
		ember_runtime.trigger("on_damage_taken", {"health_fraction": 0.36}).is_empty(),
		"Last Ember activated above 35% HP."
	)
	var ember_adjustments: Array = ember_runtime.trigger("on_damage_taken", {"health_fraction": 0.35})
	_expect(ember_adjustments.size() == 2, "Last Ember did not return offense and defense adjustments.")
	_expect_adjustment_present(ember_adjustments, "damage", 0.25, [], "Last Ember damage")
	_expect_adjustment_present(ember_adjustments, "armor", 3.0, [], "Last Ember armor")

func _validate_conversion_items() -> void:
	var rift_scar := ItemDatabaseRef.get_item_by_id("rift_scar")
	_expect_stat(rift_scar, "portal_instability", 0.1)
	_expect(rift_scar != null and rift_scar.stat_conversion_rules.size() == 1, "Rift Scar has no conversion rule.")
	if rift_scar != null and rift_scar.stat_conversion_rules.size() == 1:
		_conversion_source_values = {"portal_instability": 0.39}
		_expect_close(
			ItemStatConversionRuntimeRef.resolve_rule_amount(
				rift_scar.stat_conversion_rules[0],
				Callable(self, "_resolve_conversion_source_value")
			),
			0.24,
			"Rift Scar stepped conversion"
		)
		var portal_weapon := load("res://data/weapons/void_rifle.tres") as WeaponData
		var non_portal_weapon := load("res://data/weapons/hell_claw.tres") as WeaponData
		var portal_overrides := ItemStatConversionRuntimeRef.build_weapon_bonus_overrides(
			[rift_scar],
			portal_weapon,
			Callable(self, "_resolve_conversion_source_value")
		)
		_expect_close(float(portal_overrides.get("damage", NAN)), 0.24, "Rift Scar Portal-weapon override")
		_expect(
			ItemStatConversionRuntimeRef.build_weapon_bonus_overrides(
				[rift_scar],
				non_portal_weapon,
				Callable(self, "_resolve_conversion_source_value")
			).is_empty(),
			"Rift Scar affected a weapon without the Portal tag."
		)
		_conversion_source_values = {"portal_instability": 0.8}
		_expect_close(
			ItemStatConversionRuntimeRef.resolve_rule_amount(
				rift_scar.stat_conversion_rules[0],
				Callable(self, "_resolve_conversion_source_value")
			),
			0.4,
			"Rift Scar conversion cap"
		)

	var black_candle := ItemDatabaseRef.get_item_by_id("black_candle")
	_expect_stat(black_candle, "corruption", 0.1)
	_expect_stat(black_candle, "portal_instability", 0.05)
	_expect(black_candle != null and black_candle.stat_conversion_rules.size() == 1, "Black Candle has no conversion rule.")
	if black_candle != null and black_candle.stat_conversion_rules.size() == 1:
		_conversion_source_values = {"corruption": 0.3}
		_expect_close(
			ItemStatConversionRuntimeRef.resolve_rule_amount(
				black_candle.stat_conversion_rules[0],
				Callable(self, "_resolve_conversion_source_value")
			),
			0.3,
			"Black Candle corruption conversion"
		)
		_expect_close(
			ItemStatConversionRuntimeRef.build_global_stat_bonus(
				[black_candle],
				"portal_reward_multiplier",
				Callable(self, "_resolve_conversion_source_value")
			),
			0.3,
			"Black Candle global Portal Reward bonus"
		)

func _validate_portal_reward_item() -> void:
	var inactive_runtime := _runtime_for("grave_tithe")
	for kill_index in range(5):
		_expect(
			inactive_runtime.trigger("on_enemy_kill", {
				"portal_combat_event_active": false,
				"trigger_progress": 1.0
			}).is_empty(),
			"Grave Tithe accepted kill %d outside a portal combat event." % (kill_index + 1)
		)
	var active_runtime := _runtime_for("grave_tithe")
	for kill_index in range(4):
		_expect(
			active_runtime.trigger("on_enemy_kill", {
				"portal_combat_event_active": true,
				"trigger_progress": 1.0
			}).is_empty(),
			"Grave Tithe paid before active-event kill 5 (%d)." % (kill_index + 1)
		)
	var reward_adjustments: Array = active_runtime.trigger("on_enemy_kill", {
		"portal_combat_event_active": true,
		"trigger_progress": 1.0
	})
	_expect(reward_adjustments.size() == 1, "Grave Tithe did not return one reward proc.")
	if reward_adjustments.size() == 1 and reward_adjustments[0] is Dictionary:
		_expect(int((reward_adjustments[0] as Dictionary).get("reward_gold", 0)) == 2, "Grave Tithe did not grant exactly 2 Gold.")

func _resolve_conversion_source_value(stat_id: String) -> float:
	return float(_conversion_source_values.get(stat_id, 0.0))

func _validate_strict_failure_reporting() -> void:
	var registry := DataRegistryScript.new()
	registry.load_failures = [{
		"code": "resource_unreadable",
		"path": "res://data/items/broken_item.tres",
		"message": "ResourceLoader cannot resolve this content resource."
	}]
	var broken_item := ItemData.new()
	broken_item.id = "broken_item"
	broken_item.name = "Broken Item"
	broken_item.price = 1
	broken_item.stack_limit = 1
	broken_item.reward_tier = 1
	broken_item.rarity = "common"
	registry.items = {"broken_item": broken_item}
	var report := ContentValidatorRef.validate_registry(registry)
	var issue_codes: Array[String] = []
	for issue_variant in report.get("issues", []):
		if issue_variant is Dictionary:
			issue_codes.append(str((issue_variant as Dictionary).get("code", "")))
	_expect(issue_codes.has("resource_unreadable"), "Strict validation ignored a registry resource-load failure.")
	_expect(issue_codes.has("item_icon"), "Strict validation ignored a missing item icon.")
	registry.free()
	broken_item = null
	report.clear()

func _runtime_for(item_id: String) -> RefCounted:
	var item := ItemDatabaseRef.get_item_by_id(item_id)
	_expect(item != null, "Cannot configure runtime for missing item '%s'." % item_id)
	var runtime := PlayerPassiveRuntimeRef.new()
	if item != null:
		runtime.configure({"passive_runtime_rules": item.runtime_rules})
	return runtime

func _expect_stat(item: ItemData, stat_id: String, expected: float) -> void:
	if item == null:
		_expect(false, "Cannot inspect stat '%s' on a missing item." % stat_id)
		return
	_expect_close(float(item.stat_modifiers.get(stat_id, NAN)), expected, "%s.%s" % [item.id, stat_id])

func _expect_adjustment(
	adjustments: Array,
	stat_id: String,
	expected_value: float,
	expected_tags: Array,
	label: String
) -> void:
	_expect(adjustments.size() == 1, "%s returned %d adjustments instead of 1." % [label, adjustments.size()])
	if adjustments.size() != 1 or not (adjustments[0] is Dictionary):
		return
	var adjustment: Dictionary = adjustments[0]
	_expect(str(adjustment.get("stat_id", "")) == stat_id, "%s targeted the wrong stat." % label)
	_expect_close(float(adjustment.get("value", NAN)), expected_value, "%s value" % label)
	var actual_tags_variant: Variant = adjustment.get("effect_tags", [])
	var actual_tags: Array = actual_tags_variant if actual_tags_variant is Array else []
	_expect(actual_tags == expected_tags, "%s resolved effect tags %s instead of %s." % [label, actual_tags, expected_tags])

func _expect_adjustment_present(
	adjustments: Array,
	stat_id: String,
	expected_value: float,
	expected_tags: Array,
	label: String
) -> void:
	for adjustment_variant in adjustments:
		if not (adjustment_variant is Dictionary):
			continue
		var adjustment: Dictionary = adjustment_variant
		if str(adjustment.get("stat_id", "")) != stat_id:
			continue
		_expect_close(float(adjustment.get("value", NAN)), expected_value, "%s value" % label)
		var actual_tags_variant: Variant = adjustment.get("effect_tags", [])
		var actual_tags: Array = actual_tags_variant if actual_tags_variant is Array else []
		_expect(actual_tags == expected_tags, "%s resolved effect tags %s instead of %s." % [label, actual_tags, expected_tags])
		return
	_expect(false, "%s did not return a '%s' adjustment." % [label, stat_id])

func _find_offer(offers: Array[Dictionary], item_id: String) -> Dictionary:
	for offer in offers:
		if str(offer.get("id", "")) == item_id:
			return offer
	return {}

func _expect_close(actual: float, expected: float, label: String) -> void:
	_expect(is_equal_approx(actual, expected), "%s resolved %.4f instead of %.4f." % [label, actual, expected])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
