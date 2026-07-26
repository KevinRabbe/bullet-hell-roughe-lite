extends Node

const ShopViewModelScript = preload("res://scripts/ui/shop_view_model.gd")
const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const StandardChoiceCardScene = preload("res://scenes/ui/components/StandardChoiceCard.tscn")

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
var bottom_items_list: VBoxContainer
var bottom_weapons_title: Label
var weapon_slots_container: HBoxContainer
var weapon_slot_buttons: Array[Button] = []
var weapon_slot_labels: Array[Label] = []
var selected_weapon_slot: int = -1
var merge_selected_button: Button
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
		_connect_signal_if_needed(shop_controller, "offer_purchased", payload_changed_callable)
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

	_build_panel_style()
	_build_top_labels()
	_build_offer_card_layout()
	_build_stats_panel()
	_build_items_panel()
	_build_weapons_panel()

	if reroll_button != null:
		reroll_button.position = Vector2(636.0, 18.0)
		reroll_button.size = Vector2(220.0, 44.0)
		InfernalUiStyleRef.apply_secondary_button(reroll_button)
		panel.move_child(reroll_button, panel.get_child_count() - 1)

	if continue_button != null:
		continue_button.position = Vector2(984.0, 570.0)
		continue_button.size = Vector2(140.0, 48.0)
		continue_button.text = "Next Wave"
		InfernalUiStyleRef.apply_primary_button(continue_button)
		panel.move_child(continue_button, panel.get_child_count() - 1)

	for button in offer_buttons:
		panel.move_child(button, panel.get_child_count() - 1)

func _build_offer_card_layout() -> void:
	var card_width := 236.0
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
	var stats_panel := Panel.new()
	stats_panel.position = Vector2(996.0, 80.0)
	stats_panel.size = Vector2(128.0, 482.0)
	InfernalUiStyleRef.apply_panel(stats_panel, InfernalUiStyleRef.PANEL_CARD)
	panel.add_child(stats_panel)

	var stats_title := Label.new()
	stats_title.position = Vector2(8.0, 8.0)
	stats_title.size = Vector2(112.0, 26.0)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.text = "Values"
	InfernalUiStyleRef.apply_section_title(stats_title)
	stats_panel.add_child(stats_title)

	right_stats_label = RichTextLabel.new()
	right_stats_label.position = Vector2(10.0, 42.0)
	right_stats_label.size = Vector2(108.0, 428.0)
	right_stats_label.bbcode_enabled = true
	right_stats_label.scroll_active = false
	right_stats_label.add_theme_font_size_override("normal_font_size", 12)
	right_stats_label.add_theme_color_override("default_color", InfernalUiStyleRef.COLOR_BONE_HIGHLIGHT.darkened(0.18))
	stats_panel.add_child(right_stats_label)

func _build_items_panel() -> void:
	var items_panel := Panel.new()
	items_panel.position = Vector2(20.0, 446.0)
	items_panel.size = Vector2(600.0, 172.0)
	InfernalUiStyleRef.apply_panel(items_panel, InfernalUiStyleRef.PANEL_CARD)
	panel.add_child(items_panel)

	var items_title := Label.new()
	items_title.position = Vector2(12.0, 10.0)
	items_title.size = Vector2(576.0, 24.0)
	items_title.text = "Items"
	InfernalUiStyleRef.apply_section_title(items_title)
	items_panel.add_child(items_title)

	var items_scroll := ScrollContainer.new()
	items_scroll.position = Vector2(12.0, 40.0)
	items_scroll.size = Vector2(576.0, 120.0)
	items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	items_panel.add_child(items_scroll)

	bottom_items_list = VBoxContainer.new()
	bottom_items_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_items_list.add_theme_constant_override("separation", 6)
	items_scroll.add_child(bottom_items_list)

func _build_weapons_panel() -> void:
	var weapons_panel := Panel.new()
	weapons_panel.position = Vector2(628.0, 446.0)
	weapons_panel.size = Vector2(348.0, 172.0)
	InfernalUiStyleRef.apply_panel(weapons_panel, InfernalUiStyleRef.PANEL_CARD)
	panel.add_child(weapons_panel)

	bottom_weapons_title = Label.new()
	bottom_weapons_title.position = Vector2(12.0, 10.0)
	bottom_weapons_title.size = Vector2(324.0, 24.0)
	bottom_weapons_title.text = "Weapons (0/6)"
	InfernalUiStyleRef.apply_section_title(bottom_weapons_title)
	weapons_panel.add_child(bottom_weapons_title)

	weapon_slots_container = HBoxContainer.new()
	weapon_slots_container.position = Vector2(12.0, 40.0)
	weapon_slots_container.size = Vector2(324.0, 86.0)
	weapon_slots_container.add_theme_constant_override("separation", 2)
	weapons_panel.add_child(weapon_slots_container)

	for slot_index in range(6):
		var slot_box := VBoxContainer.new()
		slot_box.custom_minimum_size = Vector2(52.0, 84.0)
		slot_box.add_theme_constant_override("separation", 2)
		weapon_slots_container.add_child(slot_box)

		var icon_button := Button.new()
		icon_button.custom_minimum_size = Vector2(50.0, 50.0)
		icon_button.text = ""
		icon_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_button.expand_icon = true
		icon_button.flat = false
		icon_button.focus_mode = Control.FOCUS_NONE
		icon_button.mouse_filter = Control.MOUSE_FILTER_STOP
		InfernalUiStyleRef.apply_card_button(icon_button)
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
	merge_selected_button.position = Vector2(188.0, 132.0)
	merge_selected_button.size = Vector2(148.0, 30.0)
	merge_selected_button.text = "Merge"
	merge_selected_button.disabled = true
	InfernalUiStyleRef.apply_secondary_button(merge_selected_button)
	merge_selected_button.pressed.connect(_on_merge_selected_pressed)
	weapons_panel.add_child(merge_selected_button)

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
	var cards := _get_snapshot_cards()
	for index in range(offer_buttons.size()):
		var button: Button = offer_buttons[index]
		if index >= cards.size():
			_clear_offer_card(button)
			continue
		_apply_offer_card(cards[index], button)

func _refresh_stats_panel() -> void:
	if right_stats_label == null:
		return
	right_stats_label.text = str(_snapshot.get("stats_text", "No stats"))

func _refresh_bottom_sections() -> void:
	_refresh_owned_items()
	if bottom_weapons_title != null:
		bottom_weapons_title.text = "Weapons (%d/6)" % int(_snapshot.get("weapon_count", 0))
	_refresh_weapon_slots()

func _refresh_owned_items() -> void:
	if bottom_items_list == null:
		return
	for child in bottom_items_list.get_children():
		child.queue_free()
	var entries_variant: Variant = _snapshot.get("item_entries", [])
	if not (entries_variant is Array) or entries_variant.is_empty():
		var empty_label := Label.new()
		empty_label.text = "None"
		empty_label.add_theme_font_size_override("font_size", 17)
		InfernalUiStyleRef.apply_body_text(empty_label)
		bottom_items_list.add_child(empty_label)
		return
	for entry_variant in entries_variant:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 34)
		row.add_theme_constant_override("separation", 8)
		bottom_items_list.add_child(row)

		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(30, 30)
		icon_rect.texture = entry.get("icon", null)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon_rect)

		var name_label := Label.new()
		name_label.text = str(entry.get("name", "Item"))
		name_label.add_theme_font_size_override("font_size", 17)
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		InfernalUiStyleRef.apply_body_text(name_label)
		row.add_child(name_label)

func _refresh_weapon_slots() -> void:
	var slots := _get_snapshot_weapon_slots()
	for index in range(weapon_slot_buttons.size()):
		var icon_button := weapon_slot_buttons[index]
		var slot_label := weapon_slot_labels[index]
		icon_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		InfernalUiStyleRef.apply_card_button(icon_button, index == selected_weapon_slot)
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
	var hint := "Buy"
	if kind == "sold_out":
		hint = "Purchased"
	elif disabled:
		hint = "Blocked"
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
	var body_lines: Array[String] = []
	for raw_line in plain_description.split("\n", false):
		var line := str(raw_line).strip_edges()
		if line == "":
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
