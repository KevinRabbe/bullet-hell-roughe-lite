class_name RunOnboardingDriver
extends Node

const EventBannerRuntimeRef = preload("res://scripts/ui/event_banner_runtime.gd")

const INTRO_DELAY_SECONDS := 0.55
const INTRO_DURATION_SECONDS := 3.4
const PORTAL_HINT_DURATION_SECONDS := 2.8
const PORTAL_HINT_GAP_SECONDS := 0.35

var _intro_delay_left: float = INTRO_DELAY_SECONDS
var _intro_shown: bool = false
var _portal_hint_shown: bool = false
var _next_banner_allowed_msec: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if delta <= 0.0 or _portal_hint_shown:
		return
	var scene := _current_game_scene()
	if scene == null or not _is_normal_run(scene) or not bool(scene.get("run_started")):
		return
	if not _intro_shown:
		_intro_delay_left = maxf(_intro_delay_left - delta, 0.0)
		if _intro_delay_left <= 0.0:
			_show_intro()
		return
	if Time.get_ticks_msec() < _next_banner_allowed_msec:
		return
	if _has_active_portal():
		_show_portal_hint()

func _show_intro() -> void:
	_intro_shown = true
	EventBannerRuntimeRef.show(
		self,
		"FRONTIER RULES",
		"MOVE. SURVIVE. BUILD.",
		"Move with WASD, arrow keys, left stick, or D-pad. Weapons fire automatically. Shop and Level Up choices shape your build. Esc / Menu pauses.",
		INTRO_DURATION_SECONDS
	)
	_next_banner_allowed_msec = Time.get_ticks_msec() + int(round((INTRO_DURATION_SECONDS + PORTAL_HINT_GAP_SECONDS) * 1000.0))

func _show_portal_hint() -> void:
	_portal_hint_shown = true
	EventBannerRuntimeRef.show(
		self,
		"RIFT SIGHTED",
		"OPTIONAL DANGER",
		"Entering a portal accepts a risk/reward event. Avoid it when the trade is not worth the danger.",
		PORTAL_HINT_DURATION_SECONDS
	)

func _current_game_scene() -> Node:
	if get_tree() == null:
		return null
	return get_tree().current_scene

func _is_normal_run(scene: Node) -> bool:
	if scene == null:
		return false
	if scene.has_method("_get_effective_debug_preset"):
		return str(scene.call("_get_effective_debug_preset")) == "normal"
	return true

func _has_active_portal() -> bool:
	if get_tree() == null:
		return false
	for portal in get_tree().get_nodes_in_group("portals"):
		if portal == null or not is_instance_valid(portal):
			continue
		if bool(portal.get("is_active")):
			return true
	return false
