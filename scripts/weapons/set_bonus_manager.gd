extends Node

# Compatibility shell for the retired weapon-family set-bonus system.
#
# Weapon classes describe what a weapon is; they do not grant automatic
# collection bonuses. Mechanical synergy belongs to explicit weapon/item tags
# and authored runtime rules instead. Keep this node/API temporarily so current
# Player and AutoWeapon callers remain stable while the taxonomy migration is
# completed.

@export var weapon_loadout_path: NodePath
@export var log_set_bonus_changes: bool = false

var weapon_loadout: Node

func _ready() -> void:
	if weapon_loadout_path != NodePath():
		weapon_loadout = get_node_or_null(weapon_loadout_path)

func evaluate_and_debug_print() -> Dictionary:
	if log_set_bonus_changes:
		print("Weapon collection bonuses are disabled; classes do not grant set bonuses.")
	return {}

func get_damage_multiplier_bonus() -> float:
	return 0.0

func get_player_stat_bonus(_stat_id: String) -> float:
	return 0.0

func get_weapon_bonus_overrides(_weapon_data: WeaponData) -> Dictionary:
	return {}

func get_active_weapon_bonus_rules() -> Array[Dictionary]:
	return []

func can_pierce_shot() -> bool:
	return false

func should_fire_execution_shot() -> bool:
	return false

func get_execution_damage_multiplier() -> float:
	return 1.0

func debug_evaluate_from_weapon_ids(_weapon_ids: Array[String]) -> Dictionary:
	return {}
