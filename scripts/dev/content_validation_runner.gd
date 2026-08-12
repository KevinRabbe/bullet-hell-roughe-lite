extends SceneTree

const DataRegistryScript = preload("res://scripts/autoload/data_registry.gd")
const ContentValidatorRef = preload("res://scripts/dev/content_validator.gd")
const RunProgressionRuntimeRef = preload("res://scripts/game/run_progression_runtime.gd")
const EnemySpawnWavePoolRuntimeRef = preload("res://scripts/spawning/enemy_spawn_wave_pool_runtime.gd")
const ShopOfferRuntimeRef = preload("res://scripts/game/shop_offer_runtime.gd")

const RUN_PROGRESSION_PATH := "res://data/waves/run_progression.json"
const WAVE_SPAWN_CONFIG_PATH := "res://data/waves/wave_spawn_config.json"
const SHOP_CONFIG_PATH := "res://data/shop/shop_config.json"

func _initialize() -> void:
	var registry := DataRegistryScript.new()
	registry.name = "ContentValidationDataRegistry"
	root.add_child(registry)
	call_deferred("_run_validation", registry)

func _run_validation(registry: Node) -> void:
	var run_progression := RunProgressionRuntimeRef.load_progression(RUN_PROGRESSION_PATH)
	var wave_spawn_config := EnemySpawnWavePoolRuntimeRef.read_wave_config(WAVE_SPAWN_CONFIG_PATH)
	var shop_config := ShopOfferRuntimeRef.read_shop_config(SHOP_CONFIG_PATH)
	var report := ContentValidatorRef.validate_registry(registry, run_progression, wave_spawn_config, shop_config)
	_print_report(report)
	var exit_code := 0 if report.get("valid", false) == true else 1
	quit(exit_code)

func _print_report(report: Dictionary) -> void:
	var counts_variant: Variant = report.get("counts", {})
	var counts: Dictionary = counts_variant if counts_variant is Dictionary else {}
	print(
		"CONTENT VALIDATION | characters=%d weapons=%d items=%d enemies=%d portal_events=%d portal_mutations=%d ascensions=%d set_bonuses=%d run_progressions=%d wave_spawn_configs=%d shop_configs=%d"
		% [
			int(counts.get("characters", 0)),
			int(counts.get("weapons", 0)),
			int(counts.get("items", 0)),
			int(counts.get("enemies", 0)),
			int(counts.get("portal_events", 0)),
			int(counts.get("portal_mutations", 0)),
			int(counts.get("ascensions", 0)),
			int(counts.get("set_bonuses", 0)),
			int(counts.get("run_progressions", 0)),
			int(counts.get("wave_spawn_configs", 0)),
			int(counts.get("shop_configs", 0))
		]
	)

	var issues_variant: Variant = report.get("issues", [])
	if issues_variant is Array:
		for issue_variant in issues_variant:
			if not (issue_variant is Dictionary):
				continue
			var issue: Dictionary = issue_variant
			var severity := str(issue.get("severity", "error")).to_upper()
			var category := str(issue.get("category", "content"))
			var entry_id := str(issue.get("id", ""))
			var target := category if entry_id == "" else "%s:%s" % [category, entry_id]
			print("%s [%s] %s - %s" % [severity, target, str(issue.get("code", "invalid_content")), str(issue.get("message", ""))])

	if report.get("valid", false) == true:
		print("CONTENT VALIDATION PASS | errors=0 warnings=%d" % int(report.get("warning_count", 0)))
	else:
		print(
			"CONTENT VALIDATION FAIL | errors=%d warnings=%d"
			% [int(report.get("error_count", 0)), int(report.get("warning_count", 0))]
		)
