extends SceneTree

const DataRegistryScript = preload("res://scripts/autoload/data_registry.gd")
const ContentValidatorRef = preload("res://scripts/dev/content_validator.gd")

func _initialize() -> void:
	var registry := DataRegistryScript.new()
	registry.name = "ContentValidationDataRegistry"
	root.add_child(registry)
	call_deferred("_run_validation", registry)

func _run_validation(registry: Node) -> void:
	var report := ContentValidatorRef.validate_registry(registry)
	_print_report(report)
	var exit_code := 0 if report.get("valid", false) == true else 1
	quit(exit_code)

func _print_report(report: Dictionary) -> void:
	var counts_variant: Variant = report.get("counts", {})
	var counts: Dictionary = counts_variant if counts_variant is Dictionary else {}
	print(
		"CONTENT VALIDATION | characters=%d weapons=%d items=%d enemies=%d portal_events=%d portal_mutations=%d ascensions=%d set_bonuses=%d"
		% [
			int(counts.get("characters", 0)),
			int(counts.get("weapons", 0)),
			int(counts.get("items", 0)),
			int(counts.get("enemies", 0)),
			int(counts.get("portal_events", 0)),
			int(counts.get("portal_mutations", 0)),
			int(counts.get("ascensions", 0)),
			int(counts.get("set_bonuses", 0))
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
