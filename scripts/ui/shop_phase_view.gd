extends Node

const ShopViewModelScript = preload("res://scripts/ui/shop_view_model.gd")
const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const StandardChoiceCardScene = preload("res://scenes/ui/components/StandardChoiceCard.tscn")
const StandardTooltipScene = preload("res://scenes/ui/components/StandardTooltip.tscn")
const ShopStatSheetPanelRef = preload("res://scripts/ui/shop_stat_sheet_panel.gd")
const ShopInventoryDetailRuntimeRef = preload("res://scripts/ui/shop_inventory_detail_runtime.gd")
const InfernalRitualBackdropRef = preload("res://scripts/ui/components/infernal_ritual_backdrop.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")

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
var right_stats_panel: Control
var bottom_items_list: Container
var bottom_weapons_title: Label
var weapon_slots_container: HBoxContainer
var weapon_slot_buttons: Array[Button] = []
var selected_weapon_slot: int = -1
var merge_selected_button: Button
var inventory_tooltip: Control
var shop_view_model: RefCounted
var _snapshot: Dictionary = {}
var _is_dirty: bool = true

func _ready() -> void:
	set("layer", 20)
	_upgrade_offer_buttons_to_standard_cards()
	_resolve_references()
	_init_view_model()
	_build_layout_once()
	_connect_runtime_updates()
	_mark_dirty()
	_refresh_if_needed()

func _upgrade_offer_buttons_to_standard_cards() -> void:
	for path in offer_button_paths:
		var existing: Button = get_node_or_null(path) as Button
		if existing == null or existing.has_method("configure"):
			continue
		var parent: Node = existing.get_parent()
		if parent == null:
			continue
		var insert_index: int = existing.get_index()
		var card: Button = StandardChoiceCardScene.instantiate() as Button
		if card == null:
			continue
		card.name = existing.name
		card.position = existing.position
		card.size = existing.size
		card.visible = existing.visible
		card.disabled = existing.disabled
		parent.remove_child(existing)
		existing.queue_free()
		parent.add_child(card)
		parent.move_child(card, insert_index)

func _resolve_references() -> void:
	shop_controller = get_node_or_null(shop_controller_path)
	player = get_node_or_null(player_path)
	weapon_loadout = get_node_or_null(weapon_loadout_path)
	panel = get_node_or_null(shop_panel_path) as Panel
	title_label = get_node_or_null(title_label_path) as Label
	reroll_button = get_node_or_null(reroll_button_path) as Button
	continue_button = get_node_or_null(continue_button_path) as Button
	for path in offer_button_paths:
		var button: Node = get_node_or_null(path)
		if button is Button:
			offer_buttons.append(button as Button)

func _init_view_model() -> void:
	shop_view_model = ShopViewModelScript.new()
	shop_view_model.configure(shop_controller, player, weapon_loadout)

func _connect_runtime_updates() -> void:
	var state_changed_callable := Callable(self, "_on_shop_state_changed")
	var payload_changed_callable := Callable(self, "_on_shop_payload_changed")
	if shop_controller != null:
		_connect_signal_if_needed(shop_controller, "shop_opened", state_changed_callable)
		_connect_signal_if_needed(shop_controller, "shop_closed", state_changed_callable)
		_connect_signal_if_needed(shop_controller, "offers_changed", payload_changed_callable)
		_connect_signal_if_needed(shop_controller, "reroll_cost_changed", payload_changed_callable)
		_connect_signal_if_needed(shop_controller, "offer_purchased", Callable(self, "_on_offer_purchased"))
	_connect_signal_if_needed(weapon_loadout, "loadout_changed", payload_changed_callable)
	_connect_signal_if_needed(player, "ui_snapshot_changed", payload_changed_callable)

func _connect_signal_if_needed(node: Node, signal_name: StringName, callable: Callable) -> void:
	if node == null:
		return
	if not node.has_signal(signal_name):
		return
	if node.is_connected(signal_name, callable):
		return
	node.connect(signal_name, callable)

func _mark_dirty() -> void:
	_is_dirty = true

func _refresh_if_needed() -> void:
	if panel == null or not _is_dirty:
		return
	_refresh_all()
	_is_dirty = false

func _on_shop_state_changed(_value: Variant = null) -> void:
	_mark_dirty()
	_refresh_if_needed()

func _on_shop_payload_changed(_arg0: Variant = null, _arg1: Variant = null) -> void:
	_mark_dirty()
	_refresh_if_needed()

func _on_offer_purchased(index: int, _offer: Dictionary) -> void:
	_mark_dirty()
	_refresh_if_needed()
	if index < 0 or index >= offer_buttons.size():
		return
	MenuAnimationRuntimeRef.pulse_focus(offer_buttons[index], 1.035)

func _build_layout_once() -> void:
	if panel == null:
		return
	_build_panel_style()
	_build_ritual_backdrop()
	_build_top_labels()
	_build_offer_card_layout()
	_build_stats_panel()
	_build_items_panel()
	_build_weapons_panel()
	_build_inventory_tooltip()

	if reroll_button != null:
		reroll_button.position = Vector2(636.0, 18.0)
		reroll_button.size = Vector2(220.0, 44.0)
		InfernalUiStyleRef.apply_secondary_button(reroll_button)
		panel.move_child(reroll_button, panel.get_child_count() - 1)

	if continue_button != null:
		continue_button.position = Vector2(984.0, 570.0)
		continue_button.size = Vector2(140.0, 48.0)
		continue_button.text = "NEXT WAVE"
		InfernalUiStyleRef.apply_primary_button(continue_button)
		panel.move_child(continue_button, panel.get_child_count() - 1)

	for button in offer_buttons:
		panel.move_child(button, panel.get_child_count() - 1)

func _build_ritual_backdrop() -> void:
	if panel.get_node_or_null("RitualBackdrop") != null:
		return
	var backdrop := InfernalRitualBackdropRef.new()
	backdrop.name = "RitualBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(backdrop)
	panel.move_child(backdrop, 0)

func _build_offer_card_layout() -> void:
	var card_width := 229.0
	var card_height := 350.0
	var start_x := 20.0
	var gap := 8.0
	var start_y := 80.0
	for index in range(offer_buttons.size()):
		var button: Button = offer_buttons[index]
		button.position = Vector2(start_x + (card_width + gap) * index, start_y)
		button.size = Vector2(card_width, card_height)
		button.text = ""
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		if button.has_method("set_selected"):
			button.call("set_selected", false)

func _build_stats_panel() -> void:
	right_stats_panel = ShopStatSheetPanelRef.new()
	right_stats_panel.position = Vector2(976.0, 80.0)
	right_stats_panel.size = Vector2(148.0, 482.0)
	panel.add_child(right_stats_panel)
	right_stats_panel.call("configure", player)

func _build_items_panel() -> void:
	var items_panel := Panel.new()
	items_panel.position = Vector2(20.0, 446.0)
	items_panel.size = Vector2(600.0, 172.0)
	InfernalUiStyleRef.apply_panel(items_panel, InfernalUiStyleRef.PANEL_CARD)
	panel.add_child(items_panel)

	var items_title := Label.new()
	items_title.position = Vector2(12.0, 10.0)
	items_title.size = Vector2(576.0, 24.0)
	items_title.text = "ITEMS"
	InfernalUiStyleRef.apply_section_title(items_title)
	items_panel.add_child(items_title)

	var items_scroll := ScrollContainer.new()
	items_scroll.position = Vector2(12.0, 40.0)
	items_scroll.size = Vector2(576.0, 120.0)
	items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	items_panel.add_child(items_scroll)

	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	items_scroll.add_child(flow)
	bottom_items_list = flow

func _build_weapons_panel() -> void:
	var weapons_panel := Panel.new()
	weapons_panel.position = Vector2(628.0, 446.0)
	weapons_panel.size = Vector2(348.0, 172.0)
	InfernalUiStyleRef.apply_panel(weapons_panel, InfernalUiStyleRef.PANEL_CARD)
	panel.add_child(weapons_panel)

	bottom_weapons_title = Label.new()
	bottom_weapons_title.position = Vector2(12.0, 10.0)
	bottom_weapons_title.size = Vector2(324.0, 24.0)
	bottom_weapons_title.text = "ARSENAL (0/6)"
	InfernalUiStyleRef.apply_section_title(bottom_weapons_title)
	weapons_panel.add_child(bottom_weapons_title)

	weapon_slots_container = HBoxContainer.new()
	weapon_slots_container.position = Vector2(12.0, 42.0)
	weapon_slots_container.size = Vector2(324.0, 58.0)
	weapon_slots_container.add_theme_constant_override("separation", 2)
	weapons_panel.add_child(weapon_slots_container)

	for slot_index in range(6):
		var icon_button := Button.new()
		icon_button.custom_minimum_size = Vector2(52.0, 58.0)
		icon_button.text = ""
		icon_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_button.expand_icon = true
		icon_button.flat = false
		icon_button.focus_mode = Control.FOCUS_ALL
		icon_button.mouse_filter = Control.MOUSE_FILTER_STOP
		InfernalUiStyleRef.apply_card_button(icon_button)
		icon_button.pressed.connect(_on_weapon_slot_pressed.bind(slot_index))
		icon_button.mouse_entered.connect(_show_weapon_detail.bind(slot_index, icon_button))
		icon_button.mouse_exited.connect(_hide_inventory_tooltip)
		icon_button.focus_entered.connect(_show_weapon_detail.bind(slot_index, icon_button))
		icon_button.focus_exited.connect(_hide_inventory_tooltip)
		weapon_slots_container.add_child(icon_button)
		weapon_slot_buttons.append(icon_button)

	merge_selected_button = Button.new()
	merge_selected_button.position = Vector2(174.0, 116.0)
	merge_selected_button.size = Vector2(162.0, 40.0)
	merge_selected_button.text = "SELECT WEAPON"
	merge_selected_button.disabled = true
	InfernalUiStyleRef.apply_secondary_button(merge_selected_button)
	merge_selected_button.pressed.connect(_on_merge_selected_pressed)
	weapons_panel.add_child(merge_selected_button)

func _build_inventory_tooltip() -> void:
	var tooltip_variant: Variant = StandardTooltipScene.instantiate()
	if not (tooltip_variant is Control):
		return
	inventory_tooltip = tooltip_variant as Control
	inventory_tooltip.name = "InventoryTooltip"
	inventory_tooltip.visible = false
	add_child(inventory_tooltip)

func _build_panel_style() -> void:
	InfernalUiStyleRef.apply_panel(panel, InfernalUiStyleRef.PANEL_SHELL)
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	panel.offset_right = 1144.0
	panel.offset_bottom = 640.0

func _build_top_labels() -> void:
	if title_label != null:
		title_label.visible = false
	top_wave_label = Label.new()
	top_wave_label.position = Vector2(16.0, 12.0)
	top_wave_label.size = Vector2(420.0, 34.0)
	top_wave_label.add_theme_font_size_override("font_size", 22)
	InfernalUiStyleRef.apply_title(top_wave_label)
	panel.add_child(top_wave_label)

	top_gold_label = Label.new()
	top_gold_label.position = Vector2(468.0, 14.0)
	top_gold_label.size = Vector2(220.0, 30.0)
	top_gold_label.add_theme_font_size_override("font_size", 20)
	InfernalUiStyleRef.apply_section_title(top_gold_label)
	panel.add_child(top_gold_label)

func _refresh_all() -> void:
	_snapshot = _build_view_snapshot()
	_hide_inventory_tooltip()
	_refresh_top_bar()
	_refresh_offer_cards()
	_refresh_stats_panel()
	_refresh_bottom_sections()

func _build_view_snapshot() -> Dictionary:
	if shop_view_model == null:
		return {}
	return shop_view_model.get_snapshot()

func _refresh_top_bar() -> void:
	var wave_index := maxi(int(_snapshot.get("wave_index", 1)), 1)
	if top_wave_label != null:
		top_wave_label.text = "FRONTIER CACHE — WAVE %02d" % wave_index
	if top_gold_label != null:
		top_gold_label.text = "GOLD %d" % int(_snapshot.get("gold", 0))
	if reroll_button != null:
		reroll_button.text = "REROLL · %dG" % int(_snapshot.get("reroll_cost", 0))

func _refresh_offer_cards() -> void:
	var cards := _get_snapshot_cards()
	for index in range(offer_buttons.size()):
		var button: Button = offer_buttons[index]
		if index >= cards.size():
			_clear_offer_card(button)
			continue
		_apply_offer_card(cards[index], button)

func _refresh_stats_panel() -> void:
	if right_stats_panel == null:
		return
	right_stats_panel.call("refresh", _snapshot)

func _refresh_bottom_sections() -> void:
	_refresh_owned_items()
	if bottom_weapons_title != null:
		bottom_weapons_title.text = "ARSENAL (%d/6)" % int(_snapshot.get("weapon_count", 0))
	_refresh_weapon_slots()

func _refresh_owned_items() -> void:
	if bottom_items_list == null:
		return
	for child in bottom_items_list.get_children():
		child.queue_free()
	var entries_variant: Variant = _snapshot.get("item_entries", [])
	if not (entries_variant is Array) or entries_variant.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items yet."
		empty_label.add_theme_font_size_override("font_size", 15)
		InfernalUiStyleRef.apply_body_text(empty_label)
		bottom_items_list.add_child(empty_label)
		return
	for entry_variant in entries_variant:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var item_id := str(entry.get("id", ""))
		var icon_button := Button.new()
		icon_button.custom_minimum_size = Vector2(58.0, 58.0)
		icon_button.text = ""
		icon_button.icon = entry.get("icon", null)
		icon_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_button.expand_icon = true
		icon_button.focus_mode = Control.FOCUS_ALL
		icon_button.mouse_filter = Control.MOUSE_FILTER_STOP
		InfernalUiStyleRef.apply_card_button(icon_button)
		icon_button.mouse_entered.connect(_show_item_detail.bind(item_id, icon_button))
		icon_button.mouse_exited.connect(_hide_inventory_tooltip)
		icon_button.focus_entered.connect(_show_item_detail.bind(item_id, icon_button))
		icon_button.focus_exited.connect(_hide_inventory_tooltip)
		icon_button.pressed.connect(_show_item_detail.bind(item_id, icon_button))
		bottom_items_list.add_child(icon_button)

func _refresh_weapon_slots() -> void:
	var slots := _get_snapshot_weapon_slots()
	for index in range(weapon_slot_buttons.size()):
		var icon_button := weapon_slot_buttons[index]
		icon_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		InfernalUiStyleRef.apply_card_button(icon_button, index == selected_weapon_slot)
		if index < slots.size():
			var slot: Dictionary = slots[index]
			icon_button.icon = slot.get("icon", null)
			icon_button.disabled = slot.get("occupied", false) != true
		else:
			icon_button.icon = null
			icon_button.disabled = true
		if index == selected_weapon_slot:
			icon_button.modulate = Color(1.0, 0.95, 0.60, 1.0)
	if selected_weapon_slot >= slots.size():
		selected_weapon_slot = -1
	_update_merge_button_state()

func _show_item_detail(item_id: String, source: Control) -> void:
	if item_id == "" or inventory_tooltip == null:
		return
	var detail := ShopInventoryDetailRuntimeRef.build_item_detail(item_id)
	_show_inventory_tooltip(detail, source)

func _show_weapon_detail(slot_index: int, source: Control) -> void:
	if inventory_tooltip == null:
		return
	var slots := _get_snapshot_weapon_slots()
	if slot_index < 0 or slot_index >= slots.size():
		_hide_inventory_tooltip()
		return
	var slot: Dictionary = slots[slot_index]
	if slot.get("occupied", false) != true:
		_hide_inventory_tooltip()
		return
	var detail := ShopInventoryDetailRuntimeRef.build_weapon_detail(
		str(slot.get("id", "")),
		str(slot.get("rarity", "common"))
	)
	_show_inventory_tooltip(detail, source)

func _show_inventory_tooltip(detail: Dictionary, source: Control) -> void:
	if inventory_tooltip == null or source == null:
		return
	var title := str(detail.get("title", "DETAIL"))
	var body := str(detail.get("body", ""))
	if inventory_tooltip.has_method("configure"):
		inventory_tooltip.call("configure", title, body)
	var anchor := source.get_global_rect().position + Vector2(source.size.x, 0.0)
	if inventory_tooltip.has_method("show_at"):
		inventory_tooltip.call("show_at", anchor, Vector2(8.0, 0.0))
	else:
		inventory_tooltip.position = anchor + Vector2(8.0, 0.0)
		inventory_tooltip.visible = true

func _hide_inventory_tooltip() -> void:
	if inventory_tooltip == null:
		return
	if inventory_tooltip.has_method("hide_tooltip"):
		inventory_tooltip.call("hide_tooltip")
	else:
		inventory_tooltip.visible = false

func _get_snapshot_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var cards_variant: Variant = _snapshot.get("offer_cards", [])
	if cards_variant is Array:
		for card_variant in cards_variant:
			if card_variant is Dictionary:
				cards.append(card_variant as Dictionary)
	return cards

func _clear_offer_card(button: Button) -> void:
	if button == null:
		return
	button.text = ""
	button.disabled = true
	if button.has_method("configure"):
		button.call("configure", "N/A", "No offer available.", "SHOP", "", "", null)

func _apply_offer_card(card: Dictionary, button: Button) -> void:
	if button == null:
		return
	var disabled: bool = card.get("button_disabled", false) == true
	var kind := str(card.get("kind", ""))
	var hint := "BUY"
	if kind == "sold_out":
		hint = "PURCHASED"
	elif disabled:
		hint = "BLOCKED"
	var body := _build_card_body(card)
	button.text = ""
	button.disabled = disabled
	if button.has_method("configure"):
		button.call(
			"configure",
			str(card.get("title", "Offer")),
			body,
			str(card.get("type_label", "Offer")).to_upper(),
			str(card.get("button_text", "Buy")),
			hint,
			card.get("icon", null)
		)
	if button.has_method("set_selected"):
		button.call("set_selected", false)

func _build_card_body(card: Dictionary) -> String:
	var plain_description := _strip_bbcode(str(card.get("description", "")))
	var all_lines: Array[String] = []
	for raw_line in plain_description.split("\n", false):
		var line := str(raw_line).strip_edges()
		if line != "":
			all_lines.append(line)
	var body_lines: Array[String] = []
	for prefix in ["Rarity:", "DMG ", "CD ", "Range ", "Matches loadout tags:", "Boosts current loadout:"]:
		for line in all_lines:
			if line.begins_with(prefix) and line not in body_lines:
				body_lines.append(line)
				break
		if body_lines.size() >= 5:
			break
	if body_lines.size() < 4:
		for line in all_lines:
			if line in body_lines:
				continue
			body_lines.append(line)
			if body_lines.size() >= 4:
				break
	var block_reason := str(card.get("block_reason", "")).strip_edges()
	if block_reason != "":
		body_lines.append("Blocked: %s" % block_reason)
	return "\n".join(body_lines)

func _strip_bbcode(value: String) -> String:
	var regex := RegEx.new()
	if regex.compile("\\[[^\\]]*\\]") != OK:
		return value
	return regex.sub(value, "", true)

func _get_snapshot_weapon_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var slots_variant: Variant = _snapshot.get("weapon_slots", [])
	if slots_variant is Array:
		for slot_variant in slots_variant:
			if slot_variant is Dictionary:
				slots.append(slot_variant as Dictionary)
	return slots

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
		merge_selected_button.text = "SELECT WEAPON"
		return
	if shop_view_model != null:
		var state_variant: Variant = shop_view_model.get_merge_slot_state(selected_weapon_slot)
		if state_variant is Dictionary:
			var merge_state: Dictionary = state_variant
			var can_merge: bool = merge_state.get("can_merge", false) == true
			merge_selected_button.disabled = not can_merge
			if can_merge:
				merge_selected_button.text = "MERGE SELECTED"
			else:
				merge_selected_button.text = str(merge_state.get("message", "No valid merge")).to_upper()
			return
	merge_selected_button.disabled = true
	merge_selected_button.text = "NO VALID MERGE"
