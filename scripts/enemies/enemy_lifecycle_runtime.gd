class_name EnemyLifecycleRuntime
extends RefCounted

static func record_hit_source(owner: Node, source: Node, source_weapon_id: String, source_slot_index: int) -> void:
	if source != null and source.is_in_group("players"):
		owner.last_hit_player = source
		owner.last_hit_weapon_id = source_weapon_id
		owner.last_hit_slot_index = source_slot_index

static func grant_kill_rewards(
	tree: SceneTree,
	last_hit_player: Node,
	last_hit_weapon_id: String,
	last_hit_slot_index: int,
	reward_gold: int,
	reward_xp: int
) -> void:
	if tree == null:
		return
	var players := tree.get_nodes_in_group("players")
	if players.is_empty() and (last_hit_player == null or not is_instance_valid(last_hit_player)):
		return
	var player_node: Node = last_hit_player
	if player_node == null or not is_instance_valid(player_node):
		player_node = players[0]
	if player_node != null and player_node.has_method("add_gold"):
		player_node.call("add_gold", reward_gold)
	if player_node != null and player_node.has_method("add_xp"):
		player_node.call("add_xp", reward_xp)
	if player_node != null and player_node.has_method("notify_enemy_killed"):
		player_node.call("notify_enemy_killed", last_hit_weapon_id, last_hit_slot_index)

static func spawn_enemy_hit_flash(visual: CanvasItem) -> void:
	if visual == null:
		return
	visual.modulate = Color(1.35, 1.35, 1.35, 1.0)
	var tween := visual.create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

static func spawn_death_puff(
	tree: SceneTree,
	global_position: Vector2,
	z_index: int,
	visual_sprite: Sprite2D
) -> void:
	if tree == null or tree.current_scene == null:
		return
	var puff := Sprite2D.new()
	puff.global_position = global_position
	puff.z_index = z_index + 1
	if visual_sprite != null and visual_sprite.texture != null:
		puff.texture = visual_sprite.texture
		puff.scale = visual_sprite.scale * 0.85
	else:
		puff.self_modulate = Color(1.0, 0.45, 0.35, 0.9)
	tree.current_scene.add_child(puff)
	var tween := puff.create_tween()
	tween.tween_property(puff, "scale", puff.scale * 1.35, 0.18)
	tween.parallel().tween_property(puff, "modulate", Color(1.0, 0.45, 0.35, 0.0), 0.18)
	tween.finished.connect(func() -> void:
		if is_instance_valid(puff):
			puff.queue_free()
	)
