class_name RunEndRuntime
extends RefCounted

static func enter_run_end_state(
	current_state: String,
	next_state: String,
) -> Dictionary:
	if current_state == next_state:
		return {
			"changed": false,
			"run_end_state": current_state,
			"waiting_for_restart": RunFlowRuntime.should_wait_for_restart(current_state),
			"waiting_for_wave_continue": false,
			"waiting_for_level_up_choice": false
		}

	return {
		"changed": true,
		"run_end_state": next_state,
		"waiting_for_restart": RunFlowRuntime.should_wait_for_restart(next_state),
		"waiting_for_wave_continue": false,
		"waiting_for_level_up_choice": false
	}

static func apply_run_end_copy(
	state: String,
	run_end_panel: Control,
	run_end_title: Label,
	run_end_body: Label
) -> void:
	var copy := RunFlowRuntime.get_run_end_copy(state)
	if run_end_panel != null:
		run_end_panel.visible = true
	if run_end_title != null:
		run_end_title.text = str(copy.get("title", "Victory"))
	if run_end_body != null:
		run_end_body.text = str(copy.get("body", "The arena is clear. Press R or Restart to run it back."))

static func restart_run(tree: SceneTree, run_rng: Node) -> void:
	if tree == null:
		return
	if run_rng != null and run_rng.has_method("randomize_seed"):
		run_rng.call("randomize_seed")
	tree.reload_current_scene()

static func return_to_main_menu(tree: SceneTree, run_rng: Node) -> void:
	if tree == null:
		return
	if run_rng != null and run_rng.has_method("randomize_seed"):
		run_rng.call("randomize_seed")
	tree.change_scene_to_file("res://scenes/ui/MainMenu.tscn")
