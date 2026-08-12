class_name AreaDenierRuntime
extends RefCounted

const EnemyHazardZoneRuntimeRef = preload("res://scripts/enemies/enemy_hazard_zone_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

const PHASE_REPOSITION := "reposition"
const PHASE_WINDUP := "windup"
const PHASE_RECOVER := "recover"

const REPOSITION_SECONDS := 2.8
const WINDUP_SECONDS := 0.70
const RECOVER_SECONDS := 0.85
const ZONE_RADIUS := 78.0
const ZONE_DAMAGE := 5.0
const ZONE_ACTIVE_SECONDS := 2.60
const ZONE_DAMAGE_INTERVAL := 0.65

var _phase: String = PHASE_REPOSITION
var _phase_left: float = REPOSITION_SECONDS
var _target_position: Vector2 = Vector2.ZERO

func configure(_enemy: Node) -> void:
	_phase = PHASE_REPOSITION
	_phase_left = REPOSITION_SECONDS
	_target_position = Vector2.ZERO

func resolve_velocity(
	delta: float,
	enemy: Node2D,
	target: Node2D,
	base_velocity: Vector2
) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return base_velocity
	if target == null or not is_instance_valid(target):
		return Vector2.ZERO
	_tick_phase(delta, enemy, target)
	return Vector2.ZERO if _phase == PHASE_WINDUP or _phase == PHASE_RECOVER else base_velocity

func get_phase() -> String:
	return _phase

func get_target_position() -> Vector2:
	return _target_position

func _tick_phase(delta: float, enemy: Node2D, target: Node2D) -> void:
	if delta <= 0.0:
		return
	var remaining_delta := delta
	while remaining_delta >= _phase_left:
		remaining_delta -= _phase_left
		_advance_phase(enemy, target)
	_phase_left -= remaining_delta

func _advance_phase(enemy: Node2D, target: Node2D) -> void:
	match _phase:
		PHASE_REPOSITION:
			_phase = PHASE_WINDUP
			_phase_left = WINDUP_SECONDS
			_target_position = target.global_position
			SfxRuntimeRef.play(enemy, "enemy_hazard", -15.0, 1.0, 350)
			EnemyHazardZoneRuntimeRef.spawn(
				enemy,
				_target_position,
				ZONE_RADIUS,
				ZONE_DAMAGE,
				WINDUP_SECONDS,
				ZONE_ACTIVE_SECONDS,
				ZONE_DAMAGE_INTERVAL
			)
		PHASE_WINDUP:
			_phase = PHASE_RECOVER
			_phase_left = RECOVER_SECONDS
		_:
			_phase = PHASE_REPOSITION
			_phase_left = REPOSITION_SECONDS
