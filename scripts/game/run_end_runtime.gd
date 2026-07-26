class_name RunEndRuntime
extends RefCounted

const CharacterSelectionRuntimeRef = preload("res://scripts/game/character_selection_runtime.gd")

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
	_stage_retry_payload(tree)
	if run_rng != null and run_rng.has_method("randomize_seed"):
		run_rng.call("randomize_seed")
	tree.reload_current_scene()

static func return_to_main_menu(tree: SceneTree, run_rng: Node) -> void:
	if tree == null:
		return
	if run_rng != null and run_rng.has_method("randomize_seed"):
		run_rng.call("randomize_seed")
	CharacterSelectionRuntimeRef.clear_pending_character_id()
	tree.change_scene_to_file("res://scenes/ui/MainMenu.tscn")

static func _stage_retry_payload(tree: SceneTree) -> void:
	var current_scene: Node = tree.current_scene
	if current_scene == null:
		return
	var player: Node = current_scene.get_node_or_null("Player")
	if player == null:
		return
	var character_id := str(player.get("active_character_id"))
	if character_id == "":
		return
	var starting_weapon_id := _resolve_retry_starting_weapon_id(player)
	var data_registry: Node = tree.root.get_node_or_null("DataRegistry")
	var payload := CharacterSelectionRuntimeRef.build_run_start_payload(
		data_registry,
		character_id,
		starting_weapon_id
	)
	CharacterSelectionRuntimeRef.set_pending_run_start_payload(payload)

static func _resolve_retry_starting_weapon_id(player: Node) -> String:
	var weapon_loadout: Node = player.get_node_or_null("WeaponLoadout")
	if weapon_loadout == null or not weapon_loadout.has_method("get_equipped_weapon_ids"):
		return ""
	var weapon_ids_variant: Variant = weapon_loadout.call("get_equipped_weapon_ids")
	if not (weapon_ids_variant is Array):
		return ""
	var weapon_ids: Array = weapon_ids_variant
	for weapon_id_variant in weapon_ids:
		var weapon_id := str(weapon_id_variant)
		if weapon_id != "":
			return weapon_id
	return ""
