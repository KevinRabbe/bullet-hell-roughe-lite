extends Node

var player_facade: Node
var _current_gold: int = 0
var _current_xp: int = 0
var _current_level: int = 1
var _xp_to_next_level: int = 10
var _pending_level_ups: int = 0
var _owned_items: Array[ItemData] = []

func configure(next_player_facade: Node) -> void:
	player_facade = next_player_facade

func get_current_gold() -> int:
	return _current_gold

func set_current_gold(value: int) -> void:
	_current_gold = value

func get_current_xp() -> int:
	return _current_xp

func set_current_xp(value: int) -> void:
	_current_xp = value

func get_current_level() -> int:
	return _current_level

func set_current_level(value: int) -> void:
	_current_level = value

func get_xp_to_next_level() -> int:
	return _xp_to_next_level

func set_xp_to_next_level(value: int) -> void:
	_xp_to_next_level = value

func get_pending_level_ups() -> int:
	return _pending_level_ups

func set_pending_level_ups(value: int) -> void:
	_pending_level_ups = value

func get_owned_items() -> Array[ItemData]:
	return _owned_items

func set_owned_items(value: Array[ItemData]) -> void:
	_owned_items = value.duplicate()

func add_owned_item(item: ItemData) -> void:
	if item == null:
		return
	_owned_items.append(item)

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	_current_gold += amount
	_emit_ui_snapshot_changed()
	if _log_runtime_events():
		print("GOLD +%d | Total: %d" % [amount, _current_gold])

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if _current_gold < amount:
		print("Not enough gold. Need %d, have %d." % [amount, _current_gold])
		return false
	_current_gold -= amount
	_emit_ui_snapshot_changed()
	if _log_runtime_events():
		print("GOLD -%d | Total: %d" % [amount, _current_gold])
	return true

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	_current_xp += amount
	if _log_runtime_events():
		print("XP +%d | Progress: %d/%d" % [amount, _current_xp, _xp_to_next_level])
	while _current_xp >= _xp_to_next_level:
		_current_xp -= _xp_to_next_level
		_current_level += 1
		_pending_level_ups += 1
		_xp_to_next_level += 5
		print("LEVEL UP! Reached level %d. Pending choices: %d" % [_current_level, _pending_level_ups])
		_emit_level_up_pending_changed()
	_emit_ui_snapshot_changed()

func has_pending_level_up() -> bool:
	return _pending_level_ups > 0

func consume_pending_level_up() -> bool:
	if _pending_level_ups <= 0:
		return false
	_pending_level_ups -= 1
	_emit_level_up_pending_changed()
	_emit_ui_snapshot_changed()
	return true

func _emit_level_up_pending_changed() -> void:
	if player_facade != null:
		player_facade.emit_signal("level_up_pending_changed")

func _emit_ui_snapshot_changed() -> void:
	if player_facade != null and player_facade.has_method("request_ui_snapshot_refresh"):
		player_facade.call("request_ui_snapshot_refresh")
	elif player_facade != null and player_facade.has_method("_emit_ui_snapshot_changed"):
		player_facade.call("_emit_ui_snapshot_changed")
	if player_facade != null and player_facade.has_method("_update_hp_label"):
		player_facade.call("_update_hp_label")

func _log_runtime_events() -> bool:
	return player_facade != null and player_facade.get("log_runtime_events") == true
