class_name EnemyLifecycleRuntime
extends RefCounted

var _owner: Node
var _death_vfx_callback: Callable
var _last_hit_player: Node
var _last_hit_weapon_id: String = ""
var _last_hit_slot_index: int = -1
var _death_started: bool = false

func configure(owner: Node, death_vfx_callback: Callable) -> void:
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
	_grant_kill_rewards(reward_gold, reward_xp)
	if _owner != null and is_instance_valid(_owner):
		_owner.queue_free()

func has_started_death() -> bool:
	return _death_started

func _grant_kill_rewards(reward_gold: int, reward_xp: int) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	var tree := _owner.get_tree()
	if tree == null:
		return
	var players := tree.get_nodes_in_group("players")
	if players.is_empty() and (_last_hit_player == null or not is_instance_valid(_last_hit_player)):
		return
	var player_node: Node = _resolve_reward_player(players)
	if player_node != null and player_node.has_method("add_gold"):
		player_node.call("add_gold", reward_gold)
	if player_node != null and player_node.has_method("add_xp"):
		player_node.call("add_xp", reward_xp)
	if player_node != null and player_node.has_method("notify_enemy_killed"):
		player_node.call("notify_enemy_killed", _last_hit_weapon_id, _last_hit_slot_index)

func _resolve_reward_player(players: Array) -> Node:
	if _last_hit_player != null and is_instance_valid(_last_hit_player):
		return _last_hit_player
	return players[0] if not players.is_empty() else null
