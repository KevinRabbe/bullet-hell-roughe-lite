class_name GateBeastPressureRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const PHASE_CHASE := "chase"
const PHASE_WINDUP := "windup"
const PHASE_RUSH := "rush"
const PHASE_RECOVER := "recover"

const CHASE_SECONDS := 1.8
const WINDUP_SECONDS := 0.45
const RUSH_SECONDS := 0.65
const RECOVER_SECONDS := 0.55

const WINDUP_SPEED_MULTIPLIER := 0.25
const RUSH_SPEED_MULTIPLIER := 2.15
const RECOVER_SPEED_MULTIPLIER := 0.65

const COLOR_BASE := Color(0.62, 0.10, 0.18, 0.68)
const COLOR_WINDUP := Color(0.94, 0.42, 0.10, 0.95)
const COLOR_RUSH := Color(0.86, 0.14, 0.12, 0.92)
const COLOR_HIGH_CONTRAST := Color(1.0, 0.72, 0.30, 1.0)

var _phase: String = PHASE_CHASE
var _phase_left: float = CHASE_SECONDS
var _base_move_speed: float = 0.0

func configure(boss: Node) -> void:
	_phase = PHASE_CHASE
	_phase_left = CHASE_SECONDS
	_base_move_speed = maxf(float(boss.get("move_speed")), 1.0) if boss != null else 1.0
	_apply_phase(boss)

func tick(delta: float, boss: Node) -> void:
	if boss == null or not is_instance_valid(boss) or delta <= 0.0:
		return
	_phase_left -= delta
	if _phase_left > 0.0:
		return
	_advance_phase()
	_apply_phase(boss)

func restore(boss: Node) -> void:
	if boss != null and is_instance_valid(boss) and _base_move_speed > 0.0:
		boss.set("move_speed", _base_move_speed)
	_phase = PHASE_CHASE
	_phase_left = CHASE_SECONDS

func get_phase() -> String:
	return _phase

func _advance_phase() -> void:
	match _phase:
		PHASE_CHASE:
			_phase = PHASE_WINDUP
			_phase_left = WINDUP_SECONDS
		PHASE_WINDUP:
			_phase = PHASE_RUSH
			_phase_left = RUSH_SECONDS
		PHASE_RUSH:
			_phase = PHASE_RECOVER
			_phase_left = RECOVER_SECONDS
		_:
			_phase = PHASE_CHASE
			_phase_left = CHASE_SECONDS

func _apply_phase(boss: Node) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var speed_multiplier := 1.0
	match _phase:
		PHASE_WINDUP:
			speed_multiplier = WINDUP_SPEED_MULTIPLIER
		PHASE_RUSH:
			speed_multiplier = RUSH_SPEED_MULTIPLIER
		PHASE_RECOVER:
			speed_multiplier = RECOVER_SPEED_MULTIPLIER
	boss.set("move_speed", _base_move_speed * speed_multiplier)
	_apply_presence_telegraph(boss)

func _apply_presence_telegraph(boss: Node) -> void:
	var ring := boss.get_node_or_null("BossPresence") as Line2D
	if ring == null:
		return
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		ring.default_color = COLOR_HIGH_CONTRAST
	else:
		match _phase:
			PHASE_WINDUP:
				ring.default_color = COLOR_WINDUP
			PHASE_RUSH:
				ring.default_color = COLOR_RUSH
			_:
				ring.default_color = COLOR_BASE
	match _phase:
		PHASE_WINDUP:
			ring.width = 6.0
		PHASE_RUSH:
			ring.width = 5.0
		_:
			ring.width = 3.5
