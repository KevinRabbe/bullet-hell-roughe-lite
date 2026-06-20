class_name RunFlowRuntime
extends RefCounted

const RUN_END_COPY: Dictionary = {
	"game_over": {
		"title": "Game Over",
		"body": "You were overwhelmed. Press R or Restart to try again."
	},
	"victory": {
		"title": "Victory",
		"body": "The arena is clear. Press R or Restart to run it back."
	}
}

static func should_wait_for_restart(state: String) -> bool:
	return state == "game_over" or state == "victory"

static func get_run_end_copy(state: String) -> Dictionary:
	var copy_variant: Variant = RUN_END_COPY.get(state, RUN_END_COPY.get("victory", {}))
	if copy_variant is Dictionary:
		return (copy_variant as Dictionary).duplicate(true)
	return {}

static func has_pending_level_up(player: Node) -> bool:
	return player != null and player.has_method("has_pending_level_up") and player.call("has_pending_level_up") == true

static func set_process_mode_for_paths(owner: Node, paths: Array[String], mode: Node.ProcessMode) -> void:
	if owner == null:
		return
	for path in paths:
		var node := owner.get_node_or_null(path)
		if node != null:
			node.process_mode = mode

static func set_group_process_mode(tree: SceneTree, group_name: StringName, mode: Node.ProcessMode) -> void:
	if tree == null:
		return
	var nodes := tree.get_nodes_in_group(group_name)
	for group_node in nodes:
		if group_node is Node:
			(group_node as Node).process_mode = mode

static func clear_group_nodes(tree: SceneTree, group_name: StringName) -> void:
	if tree == null:
		return
	var nodes := tree.get_nodes_in_group(group_name)
	for group_node in nodes:
		if group_node is Node:
			(group_node as Node).queue_free()
