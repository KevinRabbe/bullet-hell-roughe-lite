extends SceneTree

const WeaponAttackPatternRuntimeRef = preload("res://scripts/weapons/weapon_attack_pattern_runtime.gd")
const ProjectileScript = preload("res://scripts/combat/projectile.gd")

const RETURNING_WEAPON_IDS: Array[String] = [
	"blood_chakram",
	"chain_crescent",
	"sin_shuriken"
]

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_validate_playable_signatures()
	_validate_returning_weapon_data()
	_validate_returning_motion_and_hit_phases()
	_validate_overlap_corrections()

	if _failures.is_empty():
		print("WEAPON CONTENT SMOKE PASS | playable=36 returning=3 signatures=36 corrected_overlaps=3")
		quit(0)
		return
	for failure in _failures:
		printerr("WEAPON CONTENT SMOKE FAIL | %s" % failure)
	quit(1)

func _validate_playable_signatures() -> void:
	var registry := root.get_node_or_null("DataRegistry")
	_expect(registry != null, "DataRegistry is unavailable.")
	if registry == null:
		return
	var weapons_variant: Variant = registry.get("weapons")
	_expect(weapons_variant is Dictionary, "DataRegistry weapons are unavailable.")
	if not (weapons_variant is Dictionary):
		return
	var playable_count := 0
	var signatures: Dictionary = {}
	for weapon_variant in (weapons_variant as Dictionary).values():
		if not (weapon_variant is WeaponData):
			continue
		var weapon := weapon_variant as WeaponData
		if not weapon.shop_enabled:
			continue
		playable_count += 1
		var summary := weapon.signature_attack_summary.strip_edges()
		_expect(summary != "", "Weapon '%s' has no signature summary." % weapon.id)
		_expect(not signatures.has(summary), "Weapon '%s' duplicates a signature summary." % weapon.id)
		signatures[summary] = weapon.id
		_expect(
			WeaponAttackPatternRuntimeRef.build_behavior_lines(weapon).has("Signature: %s" % summary),
			"Weapon '%s' does not expose its signature through shared presentation." % weapon.id
		)
	_expect(playable_count == 36, "Expected 36 playable weapons, found %d." % playable_count)

func _validate_returning_weapon_data() -> void:
	for weapon_id in RETURNING_WEAPON_IDS:
		var weapon := load("res://data/weapons/%s.tres" % weapon_id) as WeaponData
		_expect(weapon != null, "Returning weapon '%s' failed to load." % weapon_id)
		if weapon == null:
			continue
		_expect(weapon.attack_pattern == WeaponAttackPatternRuntimeRef.RETURNING, "Weapon '%s' is not using the returning pattern." % weapon_id)
		_expect("thrown" in weapon.tags, "Returning weapon '%s' is missing the Thrown tag." % weapon_id)
		_expect(weapon.return_after_seconds < weapon.get_projectile_lifetime_value(), "Weapon '%s' returns after its lifetime." % weapon_id)
		_expect(weapon.return_speed_multiplier >= 0.5, "Weapon '%s' has an unusable return speed." % weapon_id)
		_expect(weapon.return_damage_multiplier > 0.0, "Weapon '%s' has no return damage." % weapon_id)

func _validate_returning_motion_and_hit_phases() -> void:
	var weapon := load("res://data/weapons/sin_shuriken.tres") as WeaponData
	if weapon == null:
		_expect(false, "Cannot test returning motion without Sin Shuriken data.")
		return
	var shooter := Node2D.new()
	root.add_child(shooter)
	shooter.global_position = Vector2.ZERO
	var projectile := ProjectileScript.new()
	root.add_child(projectile)
	projectile.global_position = Vector2.ZERO
	projectile.speed = weapon.projectile_speed
	projectile.lifetime_seconds = weapon.get_projectile_lifetime_value()
	projectile.set_shooter(shooter)
	projectile.set_source_weapon_data(weapon)
	projectile.configure_attack_pattern(weapon, Vector2.RIGHT)

	projectile.call("_physics_process", 0.1)
	var outbound_position := projectile.global_position.x
	_expect(outbound_position > 0.0, "Returning projectile did not travel outbound.")
	var target := Node.new()
	root.add_child(target)
	_expect(bool(projectile.call("_can_hit_target", target)), "Returning projectile rejected its first outbound hit.")
	projectile.call("_register_target_hit", target)
	_expect(not bool(projectile.call("_can_hit_target", target)), "Returning projectile repeated an outbound hit on one target.")

	var elapsed := 0.1
	while elapsed <= weapon.return_after_seconds + 0.05:
		projectile.call("_physics_process", 0.05)
		elapsed += 0.05
	_expect(bool(projectile.get("_returning_home")), "Returning projectile never entered its return phase.")
	_expect(bool(projectile.call("_can_hit_target", target)), "Returning projectile did not allow one return hit on the outbound target.")
	projectile.call("_register_target_hit", target)
	_expect(not bool(projectile.call("_can_hit_target", target)), "Returning projectile repeated a return hit on one target.")
	var pre_return_position := projectile.global_position.x
	projectile.call("_physics_process", 0.05)
	_expect(projectile.global_position.x < pre_return_position, "Returning projectile did not travel back toward its shooter.")

	if is_instance_valid(projectile):
		projectile.free()
	target.free()
	shooter.free()

func _validate_overlap_corrections() -> void:
	var rifle := load("res://data/weapons/gunslinger_assault_rifle.tres") as WeaponData
	var smg := load("res://data/weapons/gunslinger_smg.tres") as WeaponData
	_expect(rifle != null and smg != null, "Cannot inspect the Rifle/SMG correction.")
	if rifle != null and smg != null:
		_expect(rifle.attack_pattern == WeaponAttackPatternRuntimeRef.PROJECTILE, "Rift Rifle lost its straight precision stream.")
		_expect(smg.attack_pattern == WeaponAttackPatternRuntimeRef.SPREAD and smg.projectiles_per_attack == 3, "Demon SMG is not a tight three-round spray.")

	var grimoire := load("res://data/weapons/harvester_grimoire.tres") as WeaponData
	var relic := load("res://data/weapons/harvester_occult_weapon.tres") as WeaponData
	_expect(grimoire != null and relic != null, "Cannot inspect the Grimoire/Relic correction.")
	if grimoire != null and relic != null:
		_expect(grimoire.attack_pattern == WeaponAttackPatternRuntimeRef.PROJECTILE, "Grave Grimoire lost its straight bolt stream.")
		_expect(relic.attack_pattern == WeaponAttackPatternRuntimeRef.SPREAD and relic.projectiles_per_attack == 3, "Occult Relic is not a compact three-orb fan.")
		_expect(grimoire.attack_motion_profile != relic.attack_motion_profile, "Grimoire and Relic still share their authored release motion.")

	var revolver := load("res://data/weapons/void_revolver.tres") as WeaponData
	var void_rifle := load("res://data/weapons/void_rifle.tres") as WeaponData
	_expect(revolver != null and void_rifle != null, "Cannot inspect the Void Revolver/Rifle correction.")
	if revolver != null and void_rifle != null:
		_expect(revolver.attack_motion_profile == "recoil", "Void Revolver is missing its sidearm recoil.")
		_expect(void_rifle.attack_motion_profile == "charge_release", "Void Rifle is missing its charged rifle release.")
		_expect(void_rifle.pierce > revolver.pierce, "Void Rifle no longer owns the piercing lane read.")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
