extends Node

var player_facade: Node
var _current_hp: float = 0.0
var _is_dead: bool = false
var _regen_tick_accumulator: float = 0.0

const REGEN_TICK_SECONDS: float = 0.25

func configure(next_player_facade: Node) -> void:
	player_facade = next_player_facade

func get_current_hp() -> float:
	return _current_hp

func set_current_hp(value: float) -> void:
	_current_hp = value

func get_is_dead() -> bool:
	return _is_dead

func set_is_dead(value: bool) -> void:
	_is_dead = value

func reset_for_stats(max_hp: float) -> void:
	_current_hp = max_hp
	_is_dead = false
	_regen_tick_accumulator = 0.0

func clamp_to_max_hp(max_hp: float) -> void:
	_current_hp = minf(_current_hp, max_hp)

func add_hp_and_clamp(amount: float, max_hp: float) -> void:
	_current_hp += amount
	_current_hp = minf(_current_hp, max_hp)

func take_damage(amount: float) -> void:
	if _is_dead:
		return
	_current_hp = maxf(_current_hp - amount, 0.0)
	_emit_player_ui_updates()
	if player_facade != null and player_facade.get("log_runtime_events") == true:
		var stats_variant: Variant = player_facade.get("stats")
		var max_hp: float = 0.0
		if stats_variant is StatBlock:
			max_hp = (stats_variant as StatBlock).max_hp
		print("PLAYER TOOK %.1f DAMAGE | HP: %.1f / %.1f" % [amount, _current_hp, max_hp])
	if _current_hp <= 0.0:
		die()

func heal_to_full() -> void:
	if _is_dead or player_facade == null:
		return
	var stats_variant: Variant = player_facade.get("stats")
	if not (stats_variant is StatBlock):
		return
	var stats_resource: StatBlock = stats_variant
	_current_hp = stats_resource.max_hp
	_emit_player_ui_updates()
	if player_facade.get("log_runtime_events") == true:
		print("PLAYER HEALED TO FULL | HP: %.1f / %.1f" % [_current_hp, stats_resource.max_hp])

func die() -> void:
	if _is_dead or player_facade == null:
		return
	_is_dead = true
	print("PLAYER DIED. Press R to restart.")
	player_facade.emit_signal("player_died")

func process_regen(delta: float) -> void:
	if delta <= 0.0 or _is_dead or player_facade == null:
		return
	var stats_variant: Variant = player_facade.get("stats")
	if not (stats_variant is StatBlock):
		return
	var stats_resource: StatBlock = stats_variant
	if stats_resource.hp_regen <= 0.0 or _current_hp >= stats_resource.max_hp:
		_regen_tick_accumulator = 0.0
		return
	_regen_tick_accumulator += delta
	if _regen_tick_accumulator < REGEN_TICK_SECONDS:
		return
	var elapsed: float = _regen_tick_accumulator
	_regen_tick_accumulator = 0.0
	var heal_amount: float = stats_resource.hp_regen * elapsed
	if heal_amount <= 0.0:
		return
	_current_hp = minf(_current_hp + heal_amount, stats_resource.max_hp)
	_emit_player_ui_updates()

func _emit_player_ui_updates() -> void:
	if player_facade == null:
		return
	if player_facade.has_method("_update_hp_label"):
		player_facade.call("_update_hp_label")
	if player_facade.has_method("request_ui_snapshot_refresh"):
		player_facade.call("request_ui_snapshot_refresh")
	elif player_facade.has_method("_emit_ui_snapshot_changed"):
		player_facade.call("_emit_ui_snapshot_changed")
