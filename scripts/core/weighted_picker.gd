class_name WeightedPicker
extends RefCounted

static func pick_index(rng: RandomNumberGenerator, weights: Array[float]) -> int:
	if rng == null or weights.is_empty():
		return -1
	var total_weight := 0.0
	for weight in weights:
		total_weight += maxf(float(weight), 0.0)
	if total_weight <= 0.0:
		return -1
	var roll := rng.randf_range(0.0, total_weight)
	var cumulative := 0.0
	for index in range(weights.size()):
		cumulative += maxf(float(weights[index]), 0.0)
		if roll <= cumulative:
			return index
	return weights.size() - 1

static func pick_value(rng: RandomNumberGenerator, values: Array, weights: Array[float]) -> Variant:
	var index := pick_index(rng, weights)
	if index < 0 or index >= values.size():
		return null
	return values[index]
