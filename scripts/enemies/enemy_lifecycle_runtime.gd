class_name EnemyLifecycleRuntime
extends RefCounted

const CombatRewardResolverRef = preload("res://scripts/game/combat_reward_resolver.gd")
const RewardPickupRef = preload("res://scripts/game/reward_pickup.gd")

var _owner: Node
var _death_vfx_callback: Callable
var _last_hit_player: Node
var _last_hit_weapon_id: String = ""
var _last_hit_slot_index: int = -1
var _death_started: bool = false

func configure(
	owner: Node,
	death_vfx_callback: Callable,
	_reward_vfx_callback: Callable = Callable()
) -> void:
	_owner = owner
	_death_vfx_callback = death_vfx_callback

func register_damage_source(source: Node, source_weapon_id: String = "", source_slot_index: int = -1) -> void:
	if source == null or not source.is_in_group("players"):
		return
	_last_hit_player = source
	_last_hit_weapon_id = source_weapon_id
	_last_hit_slot_index = source_slot_index

func handle_death(reward_gold: int, reward_xp: int) -> void:
	if _death_started:
		return
	_death_started = true
	if _death_vfx_callback.is_valid():
		_death_vfx_callback.call()
	_spawn_kill_rewards(reward_gold, reward_xp)
	if _owner != null and is_instance_valid(_owner):
		_owner.queue_free()

func has_started_death() -> bool:
	return _death_started

func _spawn_kill_rewards(reward_gold: int, reward_xp: int) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	var tree := _owner.get_tree()
	if tree == null:
		return
	var players := tree.get_nodes_in_group("players")
	if players.is_empty() and (_last_hit_player == null or not is_instance_valid(_last_hit_player)):
		return
	var player_node: Node = _resolve_reward_player(players)
	if player_node == null:
		return

	if player_node.has_method("notify_enemy_killed"):
		player_node.call("notify_enemy_killed", _last_hit_weapon_id, _last_hit_slot_index)

	var resolved_rewards := CombatRewardResolverRef.resolve(player_node, reward_gold, reward_xp)
	var granted_gold := int(resolved_rewards.get("gold", 0))
	var granted_xp := int(resolved_rewards.get("xp", 0))
	if granted_gold <= 0 and granted_xp <= 0:
		return
	if _spawn_reward_pickup(tree, player_node, granted_gold, granted_xp):
		return
	_grant_resolved_rewards(player_node, granted_gold, granted_xp)

func _spawn_reward_pickup(tree: SceneTree, player_node: Node, gold_reward: int, xp_reward: int) -> bool:
	var scene := tree.current_scene
	if scene == null:
		return false
	var pickup := RewardPickupRef.new()
	if pickup == null:
		return false
	pickup.call("configure", player_node, gold_reward, xp_reward)
	scene.add_child(pickup)
	if pickup is Node2D:
		(pickup as Node2D).global_position = (_owner as Node2D).global_position if _owner is Node2D else Vector2.ZERO
	return true

func _grant_resolved_rewards(player_node: Node, gold_reward: int, xp_reward: int) -> void:
	if gold_reward > 0 and player_node.has_method("add_gold"):
		player_node.call("add_gold", gold_reward)
	if xp_reward > 0 and player_node.has_method("add_xp"):
		player_node.call("add_xp", xp_reward)

func _resolve_reward_player(players: Array) -> Node:
	if _last_hit_player != null and is_instance_valid(_last_hit_player):
		return _last_hit_player
	return players[0] if not players.is_empty() else null
