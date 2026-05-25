extends Node

const ItemDatabase = preload("res://scripts/items/item_database.gd")

@export var player_path: NodePath
@export var portal_event_manager_path: NodePath

var player: Node
var portal_event_manager: Node
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if portal_event_manager_path != NodePath():
		portal_event_manager = get_node_or_null(portal_event_manager_path)
	if portal_event_manager != null and portal_event_manager.has_signal("portal_event_completed"):
		portal_event_manager.connect("portal_event_completed", _on_portal_event_completed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_grant_item"):
		_grant_random_item("debug_key")

func _on_portal_event_completed() -> void:
	print("Reward trigger: portal event completed.")
	_grant_random_item("portal_event")

func _grant_random_item(source: String) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player.has_method("grant_item"):
		return
	var item: ItemData = ItemDatabase.get_random_item(rng)
	print("Reward granted [%s]: %s" % [source, item.name])
	player.call("grant_item", item)
