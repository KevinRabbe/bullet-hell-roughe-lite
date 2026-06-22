extends Node

const ShopViewModelScript = preload("res://scripts/ui/shop_view_model.gd")

@export var shop_controller_path: NodePath
@export var player_path: NodePath
@export var weapon_loadout_path: NodePath
@export var shop_panel_path: NodePath
@export var title_label_path: NodePath
@export var offer_button_paths: Array[NodePath] = []
@export var reroll_button_path: NodePath
@export var continue_button_path: NodePath

var shop_controller: Node
var player: Node
var weapon_loadout: Node
var panel: Panel
var title_label: Label
var offer_buttons: Array[Button] = []
var reroll_button: Button
var continue_button: Button

var top_wave_label: Label
var top_gold_label: Label
var right_stats_label: RichTextLabel
var bottom_items_label: RichTextLabel
var bottom_weapons_title: Label
var weapon_slots_container: HBoxContainer
var weapon_slot_buttons: Array[Button] = []
var weapon_slot_labels: Array[Label] = []
var selected_weapon_slot: int = -1
var merge_selected_button: Button
var card_title_labels: Array[Label] = []
var card_type_labels: Array[Label] = []
var card_desc_labels: Array[RichTextLabel] = []
var card_lock_buttons: Array[Button] = []
var card_panels: Array[Panel] = []
var shop_view_model: RefCounted
var _snapshot: Dictionary = {}
var _is_dirty: bool = true

func _ready() -> void:
	_resolve_references()
	_init_view_model()
	_build_layout_once()
	_connect_runtime_updates()
	_mark_dirty()
	_refresh_if_needed()

func _resolve_references() -> void:
	shop_controller = get_node_or_null(shop_controller_path)
	player = get_node_or_null(player_path)
	weapon_loadout = get_node_or_null(weapon_loadout_path)
	panel = get_node_or_null(shop_panel_path) as Panel
	title_label = get_node_or_null(title_label_path) as Label
	reroll_button = get_node_or_null(reroll_button_path) as Button
	continue_button = get_node_or_null(continue_button_path) as Button
	for path in offer_button_paths:
		var button := get_node_or_null(path)
		if button is Button:
			offer_buttons.append(button)

func _init_view_model() -> void:
	shop_view_model = ShopViewModelScript.new()
	shop_view_model.configure(shop_controller, player, weapon_loadout)

func _connect_runtime_updates() -> void:
	var state_changed_callable := Callable(self, "_on_shop_state_changed")
	var payload_changed_callable := Callable(self, "_on_shop_payload_changed")
	if shop_controller != null:
		if shop_controller.has_signal("shop_opened") and not shop_controller.is_connected("shop_opened", state_changed_callable):
			shop_controller.connect("shop_opened", state_changed_callable)
		if shop_controller.has_signal("shop_closed") and not shop_controller.is_connected("shop_closed", state_changed_callable):
			shop_controller.connect("shop_closed", state_changed_callable)
		if shop_controller.has_signal("offers_changed") and not shop_controller.is_connected("offers_changed", payload_changed_callable):
			shop_controller.connect("offers_changed", payload_changed_callable)
		if shop_controller.has_signal("reroll_cost_changed") and not shop_controller.is_connected("reroll_cost_changed", payload_changed_callable):
			shop_controller.connect("reroll_cost_changed", payload_changed_callable)
		if shop_controller.has_signal("offer_purchased") and not shop_controller.is_connected("offer_purchased", payload_changed_callable):
			shop_controller.connect("offer_purchased", payload_changed_callable)
	if weapon_loadout != null and weapon_loadout.has_signal("loadout_changed") and not weapon_loadout.is_connected("loadout_changed", payload_changed_callable):
		weapon_loadout.connect("loadout_changed", payload_changed_callable)
	if player != null and player.has_signal("ui_snapshot_changed") and not player.is_connected("ui_snapshot_changed", payload_changed_callable):
		player.connect("ui_snapshot_changed", payload_changed_callable)

func _mark_dirty() -> void:
	_is_dirty = true

func _refresh_if_needed() -> void:
	if panel == null:
		return
	if not _is_dirty:
		return
	_refresh_all()
	_is_dirty = false

func _on_shop_state_changed(_value: Variant = null) -> void:
	_mark_dirty()
	_refresh_if_needed()

func _on_shop_payload_changed(_arg0: Variant = null, _arg1: Variant = null) -> void:
	_mark_dirty()
	_refresh_if_needed()

func _build_layout_once() -> void:
	if panel == null:
		return

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.16, 0.18, 0.24, 0.94)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.22, 0.25, 0.34, 0.95)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	panel.offset_right = 1144.0
	panel.offset_bottom = 640.0

	if title_label != null:
		title_label.visible = false

	top_wave_label = Label.new()
	top_wave_label.position = Vector2(16.0, 12.0)
	top_wave_label.size = Vector2(420.0, 34.0)
	top_wave_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(top_wave_label)

	top_gold_label = Label.new()
	top_gold_label.position = Vector2(468.0, 14.0)
	top_gold_label.size = Vector2(220.0, 30.0)
	top_gold_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(top_gold_label)

	var card_width := 248.0
	var card_height := 360.0
	var start_x := 12.0
	var gap := 8.0
	var start_y := 74.0
	for i in range(4):
		var card := Panel.new()
		card.position = Vector2(start_x + (card_width + gap) * i, start_y)
		card.size = Vector2(card_width, card_height)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.03, 0.06, 0.1, 0.95)
		card_style.border_width_left = 1
		card_style.border_width_top = 1
		card_style.border_width_right = 1
		card_style.border_width_bottom = 1
		card_style.border_color = Color(0.08, 0.18, 0.3, 0.95)
		card.add_theme_stylebox_override("panel", card_style)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(card)
		card_panels.append(card)

		var title := Label.new()
		title.position = Vector2(12.0, 10.0)
		title.size = Vector2(card_width - 24.0, 48.0)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.add_theme_font_size_override("font_size", 18)
		card.add_child(title)
		card_title_labels.append(title)

		var type_label := Label.new()
		type_label.position = Vector2(12.0, 62.0)
		type_label.size = Vector2(180.0, 30.0)
		type_label.add_theme_font_size_override("font_size", 15)
		card.add_child(type_label)
		card_type_labels.append(type_label)

		var desc := RichTextLabel.new()
		desc.position = Vector2(12.0, 92.0)
		desc.size = Vector2(card_width - 24.0, 170.0)
		desc.bbcode_enabled = true
		desc.scroll_active = false
		desc.fit_content = false
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc.add_theme_font_size_override("normal_font_size", 12)
		card.add_child(desc)
		card_desc_labels.append(desc)

		var lock_button := Button.new()
		lock_button.position = Vector2(12.0, 315.0)
		lock_button.size = Vector2(card_width - 24.0, 32.0)
		lock_button.text = "Lock (soon)"
		lock_button.disabled = true
		lock_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock_button)
		card_lock_buttons.append(lock_button)

		if i < offer_buttons.size():
			var price_button := offer_buttons[i]
			price_button.position = Vector2(card.position.x + 72.0, card.position.y + 270.0)
			price_button.size = Vector2(card_width - 144.0, 42.0)
			price_button.text = "Buy"
			price_button.mouse_filter = Control.MOUSE_FILTER_STOP
			panel.move_child(price_button, panel.get_child_count() - 1)

	var stats_panel := Panel.new()
	stats_panel.position = Vector2(1020.0, 12.0)
	stats_panel.size = Vector2(112.0, 520.0)
	var stats_style := StyleBoxFlat.new()
	stats_style.bg_color = Color(0.08, 0.1, 0.14, 0.96)
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	panel.add_child(stats_panel)

	var stats_title := Label.new()
	stats_title.position = Vector2(6.0, 6.0)
	stats_title.size = Vector2(100.0, 24.0)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.text = "Values"
	stats_panel.add_child(stats_title)

	right_stats_label = RichTextLabel.new()
	right_stats_label.position = Vector2(8.0, 36.0)
	right_stats_label.size = Vector2(96.0, 470.0)
	right_stats_label.bbcode_enabled = true
	right_stats_label.scroll_active = true
	right_stats_label.add_theme_font_size_override("normal_font_size", 13)
	stats_panel.add_child(right_stats_label)

	var items_panel := Panel.new()
	items_panel.position = Vector2(12.0, 446.0)
	items_panel.size = Vector2(620.0, 168.0)
	var items_style := StyleBoxFlat.new()
	items_style.bg_color = Color(0.1, 0.1, 0.14, 0.95)
	items_panel.add_theme_stylebox_override("panel", items_style)
	panel.add_child(items_panel)

	var items_title := Label.new()
	items_title.position = Vector2(10.0, 8.0)
	items_title.text = "Items"
	items_panel.add_child(items_title)

	bottom_items_label = RichTextLabel.new()
	bottom_items_label.position = Vector2(10.0, 34.0)
	bottom_items_label.size = Vector2(600.0, 122.0)
	bottom_items_label.bbcode_enabled = true
	bottom_items_label.scroll_active = true
	bottom_items_label.add_theme_font_size_override("normal_font_size", 17)
	items_panel.add_child(bottom_items_label)

	var weapons_panel := Panel.new()
	weapons_panel.position = Vector2(640.0, 446.0)
	weapons_panel.size = Vector2(368.0, 168.0)
	var weapons_style := StyleBoxFlat.new()
	weapons_style.bg_color = Color(0.1, 0.1, 0.14, 0.95)
	weapons_panel.add_theme_stylebox_override("panel", weapons_style)
	panel.add_child(weapons_panel)

	bottom_weapons_title = Label.new()
	bottom_weapons_title.position = Vector2(10.0, 8.0)
	bottom_weapons_title.text = "Weapons (0/6)"
	weapons_panel.add_child(bottom_weapons_title)

	weapon_slots_container = HBoxContainer.new()
	weapon_slots_container.position = Vector2(10.0, 34.0)
	weapon_slots_container.size = Vector2(348.0, 92.0)
	weapon_slots_container.add_theme_constant_override("separation", 4)
	weapons_panel.add_child(weapon_slots_container)

	for slot_index in range(6):
		var slot_box := VBoxContainer.new()
		slot_box.custom_minimum_size = Vector2(56.0, 92.0)
		slot_box.add_theme_constant_override("separation", 2)
		weapon_slots_container.add_child(slot_box)

		var icon_button := Button.new()
		icon_button.custom_minimum_size = Vector2(54.0, 54.0)
		icon_button.text = ""
		icon_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_button.expand_icon = true
		icon_button.flat = true
		icon_button.focus_mode = Control.FOCUS_NONE
		icon_button.mouse_filter = Control.MOUSE_FILTER_STOP
		icon_button.pressed.connect(_on_weapon_slot_pressed.bind(slot_index))
		slot_box.add_child(icon_button)
		weapon_slot_buttons.append(icon_button)

		var slot_label := Label.new()
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 9)
		slot_label.modulate = Color(0.92, 0.92, 0.92, 1.0)
		slot_label.text = "-"
		slot_box.add_child(slot_label)
		weapon_slot_labels.append(slot_label)

	merge_selected_button = Button.new()
	merge_selected_button.position = Vector2(208.0, 129.0)
	merge_selected_button.size = Vector2(148.0, 30.0)
	merge_selected_button.text = "Merge"
	merge_selected_button.disabled = true
	merge_selected_button.pressed.connect(_on_merge_selected_pressed)
	weapons_panel.add_child(merge_selected_button)

	if reroll_button != null:
		reroll_button.position = Vector2(588.0, 18.0)
		reroll_button.size = Vector2(220.0, 44.0)
		panel.move_child(reroll_button, panel.get_child_count() - 1)

	if continue_button != null:
		continue_button.position = Vector2(1018.0, 560.0)
		continue_button.size = Vector2(122.0, 50.0)
		continue_button.text = "Next Wave"
		panel.move_child(continue_button, panel.get_child_count() - 1)

	for button in offer_buttons:
		panel.move_child(button, panel.get_child_count() - 1)

func _refresh_all() -> void:
	_snapshot = _build_view_snapshot()
	_refresh_top_bar()
	_refresh_offer_cards()
	_refresh_stats_panel()
	_refresh_bottom_sections()

func _build_view_snapshot() -> Dictionary:
	if shop_view_model == null:
		return {}
	return shop_view_model.get_snapshot()

func _refresh_top_bar() -> void:
	if top_wave_label != null:
		top_wave_label.text = str(_snapshot.get("title", "Shop"))
	if top_gold_label != null:
		top_gold_label.text = "Gold: %d" % int(_snapshot.get("gold", 0))
	if reroll_button != null:
		reroll_button.text = "Reroll - %dG" % int(_snapshot.get("reroll_cost", 0))

func _refresh_offer_cards() -> void:
	var cards_variant: Variant = _snapshot.get("offer_cards", [])
	var cards: Array[Dictionary] = []
	if cards_variant is Array:
		for card_variant in cards_variant:
			if card_variant is Dictionary:
				cards.append(card_variant as Dictionary)
	for i in range(4):
		var title := card_title_labels[i]
		var type_label := card_type_labels[i]
		var desc := card_desc_labels[i]
		var button := offer_buttons[i] if i < offer_buttons.size() else null
		if i >= cards.size():
			title.text = "N/A"
			type_label.text = "-"
			desc.text = ""
			if button != null:
				button.text = "N/A"
				button.disabled = true
			continue
		var card: Dictionary = cards[i]
		_apply_card_border(i, str(card.get("kind", "")))
		title.text = str(card.get("title", "Offer"))
		type_label.text = str(card.get("type_label", "-"))
		desc.text = str(card.get("description", ""))
		var block_reason := str(card.get("block_reason", ""))
		if block_reason != "":
			desc.text += "\n[color=#ff7d7d]%s[/color]" % block_reason
		if button != null:
			button.disabled = card.get("button_disabled", false) == true
			button.text = str(card.get("button_text", "Buy"))

func _refresh_stats_panel() -> void:
	if right_stats_label == null:
		return
	right_stats_label.text = str(_snapshot.get("stats_text", "No stats"))

func _refresh_bottom_sections() -> void:
	if bottom_items_label != null:
		bottom_items_label.text = str(_snapshot.get("items_text", "-"))
	if bottom_weapons_title != null:
		bottom_weapons_title.text = "Weapons (%d/6)" % int(_snapshot.get("weapon_count", 0))
	_refresh_weapon_slots()

func _refresh_weapon_slots() -> void:
	var slots: Array[Dictionary] = []
	var slots_variant: Variant = _snapshot.get("weapon_slots", [])
	if slots_variant is Array:
		for slot_variant in slots_variant:
			if slot_variant is Dictionary:
				slots.append(slot_variant as Dictionary)
	for index in range(weapon_slot_buttons.size()):
		var icon_button := weapon_slot_buttons[index]
		var slot_label := weapon_slot_labels[index]
		icon_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if index < slots.size():
			var slot: Dictionary = slots[index]
			icon_button.icon = slot.get("icon", null)
			icon_button.disabled = slot.get("occupied", false) != true
			slot_label.text = str(slot.get("label", "-"))
		else:
			icon_button.icon = null
			icon_button.disabled = true
			slot_label.text = "-"
		if index == selected_weapon_slot:
			icon_button.modulate = Color(1.0, 0.95, 0.60, 1.0)
	if selected_weapon_slot >= slots.size():
		selected_weapon_slot = -1
	_update_merge_button_state()

func _on_weapon_slot_pressed(slot_index: int) -> void:
	selected_weapon_slot = slot_index
	_mark_dirty()
	_refresh_if_needed()

func _on_merge_selected_pressed() -> void:
	if selected_weapon_slot < 0:
		return
	if weapon_loadout == null or not weapon_loadout.has_method("try_merge_slot"):
		return
	var result_variant: Variant = weapon_loadout.call("try_merge_slot", selected_weapon_slot)
	if result_variant is Dictionary:
		var result: Dictionary = result_variant
		print(str(result.get("message", "")))
		if result.get("success", false) == true:
			selected_weapon_slot = -1
	_refresh_all()

func _update_merge_button_state() -> void:
	if merge_selected_button == null:
		return
	if selected_weapon_slot < 0:
		merge_selected_button.disabled = true
		merge_selected_button.text = "Select weapon"
		return
	if shop_view_model != null:
		var state_variant: Variant = shop_view_model.get_merge_slot_state(selected_weapon_slot)
		if state_variant is Dictionary:
			var merge_state: Dictionary = state_variant
			var can_merge: bool = merge_state.get("can_merge", false) == true
			merge_selected_button.disabled = not can_merge
			if can_merge:
				merge_selected_button.text = "Merge selected"
			else:
				merge_selected_button.text = str(merge_state.get("message", "No valid merge"))
			return
	merge_selected_button.disabled = true
	merge_selected_button.text = "No valid merge"

func _apply_card_border(index: int, offer_type: String) -> void:
	if index < 0 or index >= card_panels.size():
		return
	var card := card_panels[index]
	var border := Color(0.08, 0.18, 0.3, 0.95)
	if offer_type == "weapon":
		border = Color(0.26, 0.58, 0.98, 0.95)
	elif offer_type == "item":
		border = Color(0.34, 0.82, 0.52, 0.95)
	elif offer_type == "sold_out":
		border = Color(0.42, 0.42, 0.42, 0.95)
	var style := card.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var cloned := (style as StyleBoxFlat).duplicate() as StyleBoxFlat
		cloned.border_color = border
		card.add_theme_stylebox_override("panel", cloned)
