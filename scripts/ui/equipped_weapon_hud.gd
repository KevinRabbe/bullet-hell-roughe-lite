extends Control

@export var weapon_loadout_path: NodePath
var weapon_loadout: Node

@onready var slots_container: HBoxContainer = $SlotsContainer
var slot_labels: Array[Label] = []

func _ready() -> void:
	if weapon_loadout_path != NodePath():
		weapon_loadout = get_node_or_null(weapon_loadout_path)
	
	if weapon_loadout == null:
		var player := get_tree().get_first_node_in_group("players")
		if player != null:
			weapon_loadout = player.get_node_or_null("WeaponLoadout")
			
	if weapon_loadout != null and weapon_loadout.has_signal("loadout_changed"):
		weapon_loadout.connect("loadout_changed", _on_loadout_changed)
	
	_setup_slots()
	# Defer initial update to ensure player is fully initialized
	call_deferred("_update_hud")

func _setup_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	
	for i in range(6):
		var panel := PanelContainer.new()
		var label := Label.new()
		label.text = "Empty"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(120, 60)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(label)
		slots_container.add_child(panel)
		slot_labels.append(label)

func _on_loadout_changed() -> void:
	_update_hud()

func _update_hud() -> void:
	if weapon_loadout == null or not weapon_loadout.has_method("get_equipped_weapon_ids"):
		return
		
	var equipped_ids: Array = weapon_loadout.call("get_equipped_weapon_ids")
	
	for i in range(6):
		if i < equipped_ids.size():
			slot_labels[i].text = _get_display_name(str(equipped_ids[i]))
		else:
			slot_labels[i].text = "Empty"

func _get_display_name(weapon_id: String) -> String:
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if ResourceLoader.exists(resource_path):
		var weapon_data := load(resource_path)
		if weapon_data != null and "display_name" in weapon_data and weapon_data.display_name != "":
			return weapon_data.display_name
			
	var pretty_name := weapon_id.replace("_", " ").capitalize()
	return pretty_name
