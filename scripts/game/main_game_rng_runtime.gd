class_name MainGameRngRuntime
extends RefCounted

const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")

static func resolve_rng(owner: Node, stream_name: String) -> RandomNumberGenerator:
	var run_rng := owner.get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "MainGame")
