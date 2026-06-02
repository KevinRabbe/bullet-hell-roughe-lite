extends Node

const ItemDatabase = preload("res://scripts/items/item_database.gd")

@export var player_path: NodePath
@export var portal_event_manager_path: NodePath

var player: Node
var portal_event_manager: Node
var rng: RandomNumberGenerator

func _ready() -> void:
	rng = _resolve_rng("rewards")
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if portal_event_manager_path != NodePath():
		portal_event_manager = get_node_or_null(portal_event_manager_path)
	if portal_event_manager != null and portal_event_manager.has_signal("portal_event_completed"):
		portal_event_manager.connect("portal_event_completed", _on_portal_event_completed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_grant_item"):
		_grant_random_item("debug_key")

func _on_portal_event_completed() -> void:
	print("Reward trigger: portal event completed.")
	_grant_random_item("portal_event")

func _grant_random_item(source: String) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player.has_method("grant_item"):
		return
	var reward_tier := _roll_reward_tier(source)
	var item: ItemData = ItemDatabase.get_random_item_for_tier(reward_tier, rng)
	print("Reward granted [%s] tier %d: %s" % [source, reward_tier, item.name])
	player.call("grant_item", item)

func _roll_reward_tier(source: String) -> int:
	if source != "portal_event":
		return 1

	var portal_luck := _player_portal_stat("portal_luck", 0.0)
	var portal_risk := _player_portal_stat("portal_instability", 0.0)
	var reward_multiplier := maxf(_player_portal_stat("portal_reward_multiplier", 1.0), 0.25)
	var tier2_chance := clampf((0.35 + (portal_luck * 0.08) + (portal_risk * 0.03)) * reward_multiplier, 0.2, 0.9)
	var tier3_chance := clampf((0.08 + (portal_luck * 0.05) + (portal_risk * 0.1)) * reward_multiplier, 0.02, 0.7)
	var roll := rng.randf()
	var tier := 1
	if roll <= tier3_chance:
		tier = 3
	elif roll <= tier2_chance:
		tier = 2
	print(
		"Portal reward roll | luck=%.2f risk=%.2f tier2=%.2f tier3=%.2f roll=%.2f -> tier=%d"
		% [portal_luck, portal_risk, tier2_chance, tier3_chance, roll, tier]
	)
	return tier

func _player_portal_stat(stat_name: String, fallback: float) -> float:
	if player == null or not is_instance_valid(player):
		return fallback
	var stats_variant: Variant = player.get("stats")
	if stats_variant == null or not (stats_variant is Object):
		return fallback
	return float(stats_variant.get(stat_name))

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback
