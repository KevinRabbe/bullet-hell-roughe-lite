extends Control

@export var weapon_loadout_path: NodePath
@export var shop_panel_path: NodePath
var weapon_loadout: Node
var shop_panel: Control

@onready var slots_container: HBoxContainer = $SlotsContainer
var slot_name_labels: Array[Label] = []
var slot_rarity_labels: Array[Label] = []
var slot_icons: Array[TextureRect] = []
var slot_panels: Array[PanelContainer] = []
var slot_merge_buttons: Array[Button] = []
var selected_slot_index: int = -1
var _weapon_data_cache: Dictionary = {}

func _ready() -> void:
	if weapon_loadout_path != NodePath():
		weapon_loadout = get_node_or_null(weapon_loadout_path)
	if shop_panel_path != NodePath():
		shop_panel = get_node_or_null(shop_panel_path)
	
	if weapon_loadout == null:
		var player := get_tree().get_first_node_in_group("players")
		if player != null:
			weapon_loadout = player.get_node_or_null("WeaponLoadout")
			
	if weapon_loadout != null and weapon_loadout.has_signal("loadout_changed"):
		weapon_loadout.connect("loadout_changed", _on_loadout_changed)
	
	_setup_slots()
	# Defer initial update to ensure player is fully initialized
	call_deferred("_update_hud")

func _process(_delta: float) -> void:
	_update_merge_controls()

func _setup_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	
	for i in range(6):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 106)
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
		var merge_button := Button.new()
		merge_button.text = "Merge"
		merge_button.custom_minimum_size = Vector2(64, 22)
		merge_button.pressed.connect(_on_merge_pressed.bind(i))
		merge_button.visible = false
		box.add_child(icon)
		box.add_child(name_label)
		box.add_child(rarity_label)
		box.add_child(merge_button)
		panel.add_child(box)
		panel.gui_input.connect(_on_slot_gui_input.bind(i))
		slots_container.add_child(panel)
		slot_panels.append(panel)
		slot_icons.append(icon)
		slot_name_labels.append(name_label)
		slot_rarity_labels.append(rarity_label)
		slot_merge_buttons.append(merge_button)

func _on_loadout_changed() -> void:
	selected_slot_index = mini(selected_slot_index, _get_equipped_entries().size() - 1)
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
	if selected_slot_index >= equipped_entries.size():
		selected_slot_index = -1
	_update_slot_selection_visuals()
	_update_merge_controls()

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if index >= _get_equipped_entries().size():
		selected_slot_index = -1
	else:
		selected_slot_index = index
	_update_slot_selection_visuals()
	_update_merge_controls()

func _on_merge_pressed(index: int) -> void:
	if not _is_shop_open():
		return
	if index != selected_slot_index:
		print("Select this slot first, then press Merge.")
		return
	if weapon_loadout == null or not weapon_loadout.has_method("try_merge_slot"):
		return
	var result_variant: Variant = weapon_loadout.call("try_merge_slot", index)
	if not (result_variant is Dictionary):
		return
	var result: Dictionary = result_variant
	var success := bool(result.get("success", false))
	var message := str(result.get("message", ""))
	if message != "":
		print(message)
	if success:
		selected_slot_index = -1
	_update_hud()

func _update_slot_selection_visuals() -> void:
	for i in range(slot_panels.size()):
		var panel := slot_panels[i]
		if panel == null:
			continue
		if i == selected_slot_index:
			panel.self_modulate = Color(0.78, 0.9, 1.0, 1.0)
		else:
			panel.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func _update_merge_controls() -> void:
	var equipped_entries: Array[Dictionary] = _get_equipped_entries()
	var shop_open := _is_shop_open()
	for i in range(slot_merge_buttons.size()):
		var merge_button := slot_merge_buttons[i]
		if merge_button == null:
			continue
		var has_entry := i < equipped_entries.size()
		merge_button.visible = shop_open and has_entry
		if not merge_button.visible:
			merge_button.disabled = true
			continue
		var is_selected := i == selected_slot_index
		var can_merge := false
		if is_selected and weapon_loadout != null and weapon_loadout.has_method("can_merge_slot"):
			can_merge = bool(weapon_loadout.call("can_merge_slot", i))
		merge_button.disabled = not (is_selected and can_merge)

func _is_shop_open() -> bool:
	return shop_panel != null and shop_panel.visible

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
	if _weapon_data_cache.has(weapon_id):
		return _weapon_data_cache[weapon_id] as WeaponData
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if not ResourceLoader.exists(resource_path):
		return null
	var loaded := load(resource_path) as WeaponData
	if loaded != null:
		_weapon_data_cache[weapon_id] = loaded
	return loaded

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
