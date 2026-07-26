class_name ActorMotionDriver
extends Node

const ActorLocomotionRuntimeRef = preload("res://scripts/visual/actor_locomotion_runtime.gd")

@export var profile_id: String = ""
@export var visual_path: NodePath = NodePath("../Visual")

var _actor: CharacterBody2D
var _visual: Sprite2D
var _tracked_texture: Texture2D
var _capture_delay_left: float = 0.0
var _configured: bool = false

func _ready() -> void:
	process_physics_priority = 50
	_actor = get_parent() as CharacterBody2D
	_visual = get_node_or_null(visual_path) as Sprite2D
	if _visual != null:
		_tracked_texture = _visual.texture
	_capture_delay_left = _initial_capture_delay()

func _physics_process(delta: float) -> void:
	if _actor == null or not is_instance_valid(_actor) or _visual == null or not is_instance_valid(_visual):
		return
	if _visual.texture != _tracked_texture:
		_tracked_texture = _visual.texture
		_configured = false
		_capture_delay_left = _initial_capture_delay()
	if _capture_delay_left > 0.0:
		_capture_delay_left = maxf(_capture_delay_left - delta, 0.0)
		return
	if not _configured:
		ActorLocomotionRuntimeRef.capture_rest_pose(_visual)
		_configured = true
	if _actor.is_in_group("players") and bool(_actor.get("is_dead")):
		ActorLocomotionRuntimeRef.settle_visual(_visual)
		return
	ActorLocomotionRuntimeRef.update_visual(_visual, _actor.velocity, delta, _resolve_profile_id())

func _resolve_profile_id() -> String:
	if profile_id != "":
		return profile_id
	var variant: Variant = _actor.get("enemy_variant")
	var resolved := str(variant)
	return resolved if resolved != "" else "enemy"

func _initial_capture_delay() -> float:
	if profile_id == "player":
		return 0.0
	# Enemy visuals play a short spawn tween when their data is applied. Wait until that
	# finishes before capturing the locomotion rest pose so the two animations never fight.
	return 0.18
