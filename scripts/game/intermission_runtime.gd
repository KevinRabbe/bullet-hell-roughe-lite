class_name IntermissionRuntime
extends RefCounted

static func begin_intermission(owner: Node, wave_panel: Control, level_up_panel: Control, shop_enabled: bool) -> void:
	if owner == null:
		return
	if owner.has_method("_set_combat_active"):
		owner.call("_set_combat_active", false)
	if owner.has_method("_clear_combat_entities"):
		owner.call("_clear_combat_entities")
	if shop_enabled:
		if wave_panel != null:
			wave_panel.visible = false
		if level_up_panel != null:
			level_up_panel.visible = false
	else:
		if owner.has_method("_hide_run_overlays"):
			owner.call("_hide_run_overlays")
	if not shop_enabled and wave_panel != null:
		wave_panel.visible = true

static func end_intermission(owner: Node) -> void:
	if owner == null:
		return
	if owner.has_method("_hide_run_overlays"):
		owner.call("_hide_run_overlays")

static func start_next_wave(owner: Node, enemy_spawner: Node) -> void:
	if owner != null:
		if owner.has_method("_heal_player_to_full"):
			owner.call("_heal_player_to_full")
		if owner.has_method("_set_combat_active"):
			owner.call("_set_combat_active", true)
	if enemy_spawner != null and enemy_spawner.has_method("start_next_wave"):
		enemy_spawner.call("start_next_wave")
