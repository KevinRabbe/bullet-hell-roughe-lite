extends Node

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const PortalRiskRewardRuntime = preload("res://scripts/portal/portal_risk_reward_runtime.gd")
const EventBannerRuntimeRef = preload("res://scripts/ui/event_banner_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

const INSTANT_PORTAL_EVENTS: Array[String] = [
	"power_for_hp_loss",
	"attack_speed_for_damage_loss"
]

@export var player_path: NodePath
@export var portal_event_manager_path: NodePath
@export var log_reward_events: bool = false

var player: Node
var portal_event_manager: Node
var rng: RandomNumberGenerator

func _ready() -> void:
	rng = _resolve_rng("rewards")
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if portal_event_manager_path != NodePath():
		portal_event_manager = get_node_or_null(portal_event_manager_path)
	if portal_event_manager != null and portal_event_manager.has_signal("portal_event_completed"):
		portal_event_manager.connect("portal_event_completed", _on_portal_event_completed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_grant_item"):
		_grant_random_item("debug_key")

func _on_portal_event_completed(event_result: Dictionary = {}) -> void:
	if log_reward_events:
		print("Reward trigger: portal event completed.")
	var reward_count: int = maxi(int(event_result.get("reward_count", 1)), 0)
	var granted_names: Array[String] = []
	for reward_index in range(reward_count):
		var granted_name := _grant_random_item("portal_event", event_result, reward_index)
		if granted_name != "":
			granted_names.append(granted_name)
	_queue_portal_reward_feedback(granted_names, event_result)

func _grant_random_item(source: String, event_result: Dictionary = {}, reward_index: int = 0) -> String:
	if player == null or not is_instance_valid(player):
		return ""
	if not player.has_method("grant_item"):
		return ""
	var reward_tier: int = _roll_reward_tier(source, event_result)
	var item: ItemData = ItemDatabase.get_random_item_for_tier(reward_tier, rng)
	if item == null:
		return ""
	if log_reward_events:
		print("Reward granted [%s #%d] tier %d: %s" % [source, reward_index + 1, reward_tier, item.name])
	player.call("grant_item", item)
	return item.name

func _queue_portal_reward_feedback(granted_names: Array[String], event_result: Dictionary) -> void:
	if granted_names.is_empty():
		return
	var event_id := str(event_result.get("event_id", ""))
	if event_id not in INSTANT_PORTAL_EVENTS:
		_show_portal_reward_feedback(granted_names)
		return
	if get_tree() == null:
		return
	var names_copy: Array[String] = []
	names_copy.assign(granted_names)
	var timer := get_tree().create_timer(EventBannerRuntimeRef.DEFAULT_SECONDS + 0.08)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(self):
			_show_portal_reward_feedback(names_copy)
	)

func _show_portal_reward_feedback(granted_names: Array[String]) -> void:
	if granted_names.is_empty():
		return
	var title := "REWARD CLAIMED" if granted_names.size() == 1 else "%d REWARDS CLAIMED" % granted_names.size()
	SfxRuntimeRef.play(self, "portal_reward", -8.0, 1.0, 160)
	EventBannerRuntimeRef.show(
		self,
		"RIFT REWARD",
		title,
		", ".join(granted_names)
	)

func _roll_reward_tier(source: String, event_result: Dictionary = {}) -> int:
	var reward_result: Dictionary = PortalRiskRewardRuntime.roll_reward_tier_result(rng, source, player, event_result)
	var tier: int = int(reward_result.get("tier", 1))
	if log_reward_events:
		print(
			"Portal reward roll | luck=%.2f risk=%.2f tier2=%.2f tier3=%.2f bias2=%.2f bias3=%.2f event2=%.2f event3=%.2f roll=%.2f -> tier=%d"
			% [
				float(reward_result.get("portal_luck", 0.0)),
				float(reward_result.get("portal_instability", 0.0)),
				float(reward_result.get("tier2_chance", 0.0)),
				float(reward_result.get("tier3_chance", 0.0)),
				float(reward_result.get("tier2_bias", 0.0)),
				float(reward_result.get("tier3_bias", 0.0)),
				float(reward_result.get("event_tier2_bonus", 0.0)),
				float(reward_result.get("event_tier3_bonus", 0.0)),
				float(reward_result.get("roll", 0.0)),
				tier
			]
		)
	return tier

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "RewardController")
