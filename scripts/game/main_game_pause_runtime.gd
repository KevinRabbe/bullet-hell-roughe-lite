class_name MainGamePauseRuntime
extends RefCounted

static func toggle_pause(tree: SceneTree) -> String:
	var should_pause := not tree.paused
	tree.paused = should_pause
	if should_pause:
		return "GAME PAUSED"
	return "GAME RESUMED"
