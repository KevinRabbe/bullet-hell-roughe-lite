extends Control

@export var weapon_loadout_path: NodePath
var weapon_loadout: Node

@onready var slots_container: HBoxContainer = $SlotsContainer
var slot_name_labels: Array[Label] = []
var slot_rarity_labels: Array[Label] = []
var slot_icons: Array[TextureRect] = []

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
		panel.custom_minimum_size = Vector2(130, 82)
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(52, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var name_label := Label.new()
		name_label.text = "Empty"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var rarity_label := Label.new()
		rarity_label.text = "-"
		rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(icon)
		box.add_child(name_label)
		box.add_child(rarity_label)
		panel.add_child(box)
		slots_container.add_child(panel)
		slot_icons.append(icon)
		slot_name_labels.append(name_label)
		slot_rarity_labels.append(rarity_label)

func _on_loadout_changed() -> void:
	_update_hud()

func _update_hud() -> void:
	if weapon_loadout == null or not weapon_loadout.has_method("get_equipped_weapon_ids"):
		return
		
	var equipped_entries: Array[Dictionary] = _get_equipped_entries()
	
	for i in range(6):
		if i < equipped_entries.size():
			var entry := equipped_entries[i]
			var weapon_id := str(entry.get("id", ""))
			var rarity := str(entry.get("rarity", "common"))
			var weapon_data := _load_weapon_data(weapon_id)
			slot_name_labels[i].text = _get_display_name(weapon_id, weapon_data)
			slot_rarity_labels[i].text = rarity.capitalize()
			slot_rarity_labels[i].modulate = _rarity_color(rarity)
			slot_icons[i].texture = _get_icon_texture(weapon_data)
		else:
			slot_name_labels[i].text = "Empty"
			slot_rarity_labels[i].text = "-"
			slot_rarity_labels[i].modulate = Color(0.7, 0.7, 0.7, 1.0)
			slot_icons[i].texture = null

func _get_equipped_entries() -> Array[Dictionary]:
	if weapon_loadout != null and weapon_loadout.has_method("get_weapon_entries"):
		var entries_variant: Variant = weapon_loadout.call("get_weapon_entries")
		if entries_variant is Array:
			var entries: Array[Dictionary] = []
			for entry_variant in entries_variant:
				if entry_variant is Dictionary:
					entries.append(entry_variant)
			if not entries.is_empty():
				return entries
	var fallback_entries: Array[Dictionary] = []
	if weapon_loadout != null and weapon_loadout.has_method("get_equipped_weapon_ids"):
		var ids_variant: Variant = weapon_loadout.call("get_equipped_weapon_ids")
		if ids_variant is Array:
			for weapon_id_variant in ids_variant:
				fallback_entries.append({"id": str(weapon_id_variant), "rarity": "common"})
	return fallback_entries

func _load_weapon_data(weapon_id: String) -> WeaponData:
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if not ResourceLoader.exists(resource_path):
		return null
	return load(resource_path) as WeaponData

func _get_display_name(weapon_id: String, weapon_data: WeaponData) -> String:
	if weapon_data != null and weapon_data.display_name != "":
		return weapon_data.display_name
	var pretty_name := weapon_id.replace("_", " ").capitalize()
	return pretty_name

func _get_icon_texture(weapon_data: WeaponData) -> Texture2D:
	if weapon_data == null:
		return null
	return weapon_data.icon

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return Color(0.45, 0.75, 1.0, 1.0)
		"epic":
			return Color(0.82, 0.52, 1.0, 1.0)
		"legendary":
			return Color(1.0, 0.78, 0.35, 1.0)
		_:
			return Color(0.85, 0.85, 0.85, 1.0)
