class_name EnemyResourceRuntime
extends RefCounted

const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")

static func load_enemy_data(enemy_data_cache: Dictionary, enemy_data_dir: String, variant_id: String) -> EnemyData:
	if variant_id == "":
		return null
	var resource_path := "%s/%s.tres" % [enemy_data_dir, variant_id]
	if resource_path == "" or not ResourceLoader.exists(resource_path):
		return null
	if enemy_data_cache.has(resource_path):
		return enemy_data_cache[resource_path] as EnemyData
	var loaded := load(resource_path) as EnemyData
	if loaded != null:
		enemy_data_cache[resource_path] = loaded
	return loaded

static func load_texture(texture_cache: Dictionary, resource_path: String) -> Texture2D:
	if resource_path == "":
		return null
	if texture_cache.has(resource_path):
		return texture_cache[resource_path] as Texture2D
	if not ResourceLoader.exists(resource_path):
		return null
	var loaded := load(resource_path) as Texture2D
	if loaded != null:
		texture_cache[resource_path] = loaded
	return loaded

static func resolve_rng(owner: Node, stream_name: String) -> RandomNumberGenerator:
	var run_rng := owner.get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "Enemy")
