class_name DeterministicRng
extends RefCounted

static var _warned_contexts: Dictionary = {}

static func create_fallback_rng(stream_name: String, context: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%s::%s::fallback" % [context, stream_name])) & 0x7fffffff
	if not _warned_contexts.has(context):
		_warned_contexts[context] = true
		push_warning("%s is using deterministic fallback RNG for stream '%s'." % [context, stream_name])
	return rng
