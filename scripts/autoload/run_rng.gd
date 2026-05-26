extends Node

const DEBUG_FIXED_SEED: int = -1

var run_seed: int = 0
var stream_rngs: Dictionary = {}

func _ready() -> void:
	new_run()

func set_seed(seed: int) -> void:
	run_seed = seed
	stream_rngs.clear()
	print("RUN SEED: %d" % run_seed)

func new_run(optional_seed: int = -1) -> int:
	var next_seed: int = optional_seed
	if next_seed < 0 and DEBUG_FIXED_SEED >= 0:
		next_seed = DEBUG_FIXED_SEED
	if next_seed < 0:
		next_seed = int(Time.get_unix_time_from_system()) ^ (randi() & 0x7fffffff)
	set_seed(next_seed)
	return run_seed

func get_rng(stream_name: String) -> RandomNumberGenerator:
	if stream_rngs.has(stream_name):
		return stream_rngs[stream_name] as RandomNumberGenerator
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _derive_stream_seed(stream_name)
	stream_rngs[stream_name] = rng
	return rng

func current_seed() -> int:
	return run_seed

func _derive_stream_seed(stream_name: String) -> int:
	var hash_value := int(hash(stream_name))
	return (run_seed * 1103515245 + hash_value * 12345) & 0x7fffffff
