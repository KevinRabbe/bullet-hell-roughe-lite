class_name StatBlock
extends RefCounted

var max_hp: float = 100.0
var hp_regen: float = 0.0
var damage: float = 1.0
var attack_speed: float = 1.0
var attack_range: float = 1.0
var projectile_speed: float = 1.0
var crit_chance: float = 0.0
var crit_damage: float = 1.5
var armor: float = 0.0
var dodge: float = 0.0
var movement_speed: float = 300.0
var luck: float = 0.0
var pickup_range: float = 48.0

var xp_gain: float = 1.0
var coin_gain: float = 1.0
var shop_discount: float = 0.0
var reroll_cost: float = 1.0

var portal_luck: float = 0.0
var portal_frequency: float = 1.0
var portal_instability: float = 0.0
var portal_reward_multiplier: float = 1.0
var corruption: float = 0.0

var burn_damage: float = 1.0
var poison_damage: float = 1.0
var bleed_damage: float = 1.0
var fear_chance: float = 0.0
var frost_power: float = 1.0

func duplicate_values() -> StatBlock:
	var copy := StatBlock.new()
	copy.max_hp = max_hp
	copy.hp_regen = hp_regen
	copy.damage = damage
	copy.attack_speed = attack_speed
	copy.attack_range = attack_range
	copy.projectile_speed = projectile_speed
	copy.crit_chance = crit_chance
	copy.crit_damage = crit_damage
	copy.armor = armor
	copy.dodge = dodge
	copy.movement_speed = movement_speed
	copy.luck = luck
	copy.pickup_range = pickup_range
	copy.xp_gain = xp_gain
	copy.coin_gain = coin_gain
	copy.shop_discount = shop_discount
	copy.reroll_cost = reroll_cost
	copy.portal_luck = portal_luck
	copy.portal_frequency = portal_frequency
	copy.portal_instability = portal_instability
	copy.portal_reward_multiplier = portal_reward_multiplier
	copy.corruption = corruption
	copy.burn_damage = burn_damage
	copy.poison_damage = poison_damage
	copy.bleed_damage = bleed_damage
	copy.fear_chance = fear_chance
	copy.frost_power = frost_power
	return copy
