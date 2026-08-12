class_name EnemyCombatProfileRuntime
extends RefCounted

const CommittedChargerRuntimeRef = preload("res://scripts/enemies/committed_charger_runtime.gd")
const AreaDenierRuntimeRef = preload("res://scripts/enemies/area_denier_runtime.gd")
const SupportCommanderRuntimeRef = preload("res://scripts/enemies/support_commander_runtime.gd")

const SUPPORTED_PROFILES: Array[String] = ["standard", "committed_charger", "area_denier", "support_commander"]

static func create(profile_id: String) -> RefCounted:
	match profile_id:
		"committed_charger":
			return CommittedChargerRuntimeRef.new()
		"area_denier":
			return AreaDenierRuntimeRef.new()
		"support_commander":
			return SupportCommanderRuntimeRef.new()
		_:
			return null

static func is_supported(profile_id: String) -> bool:
	return profile_id in SUPPORTED_PROFILES
