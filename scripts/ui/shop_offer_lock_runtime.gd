extends Node

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")

const LOCK_ROW_Y := 406.0
const LOCK_BUTTON_HEIGHT := 32.0
const OFFER_CARD_HEIGHT := 320.0

var _shop_controller: Node
var _panel: Control
var _offer_buttons: Array[Button] = []
var _lock_buttons: Array[Button] = []
var _initialized: bool = false

func configure(shop_controller: Node, panel: Control, offer_buttons: Array) -> void:
	_shop_controller = shop_controller
	_panel = panel
	_offer_buttons.clear()
	for button_variant in offer_buttons:
		if button_variant is Button:
			_offer_buttons.append(button_variant as Button)

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	if _initialized or _shop_controller == null or _panel == null:
		return
	_initialized = true
	_build_controls()
	_connect_runtime_updates()
	_refresh_controls()

func _build_controls() -> void:
	for index in range(_offer_buttons.size()):
		var offer_button := _offer_buttons[index]
		offer_button.size.y = OFFER_CARD_HEIGHT

		var lock_button := Button.new()
		lock_button.name = "OfferLock%d" % (index + 1)
		lock_button.position = Vector2(offer_button.position.x, LOCK_ROW_Y)
		lock_button.size = Vector2(offer_button.size.x, LOCK_BUTTON_HEIGHT)
		lock_button.text = "LOCK OFFER"
		lock_button.focus_mode = Control.FOCUS_ALL
		InfernalUiStyleRef.apply_secondary_button(lock_button)
		lock_button.pressed.connect(_on_lock_pressed.bind(index))
		_panel.add_child(lock_button)
		_lock_buttons.append(lock_button)

		offer_button.focus_neighbor_bottom = offer_button.get_path_to(lock_button)
		lock_button.focus_neighbor_top = lock_button.get_path_to(offer_button)

	_wire_horizontal_focus()

func _wire_horizontal_focus() -> void:
	for index in range(_lock_buttons.size()):
		if index > 0:
			var current := _lock_buttons[index]
			var previous := _lock_buttons[index - 1]
			current.focus_neighbor_left = current.get_path_to(previous)
			previous.focus_neighbor_right = previous.get_path_to(current)

func _connect_runtime_updates() -> void:
	_connect_signal_if_needed("offers_changed", Callable(self, "_refresh_controls"))
	_connect_signal_if_needed("shop_opened", Callable(self, "_on_shop_state_changed"))
	_connect_signal_if_needed("shop_closed", Callable(self, "_on_shop_state_changed"))
	_connect_signal_if_needed("offer_lock_changed", Callable(self, "_on_offer_lock_changed"))

func _connect_signal_if_needed(signal_name: StringName, callable: Callable) -> void:
	if _shop_controller == null or not _shop_controller.has_signal(signal_name):
		return
	if _shop_controller.is_connected(signal_name, callable):
		return
	_shop_controller.connect(signal_name, callable)

func _on_shop_state_changed(_arg0: Variant = null) -> void:
	_refresh_controls()

func _on_offer_lock_changed(_index: int, _locked: bool) -> void:
	_refresh_controls()

func _refresh_controls() -> void:
	if not _initialized or _shop_controller == null:
		return
	var offers: Array = []
	if _shop_controller.has_method("get_active_offers"):
		var offers_variant: Variant = _shop_controller.call("get_active_offers")
		if offers_variant is Array:
			offers = offers_variant
	for index in range(_lock_buttons.size()):
		var lock_button := _lock_buttons[index]
		var lockable := false
		if index < offers.size() and offers[index] is Dictionary:
			lockable = str((offers[index] as Dictionary).get("type", "")) != "sold_out"
		var locked := lockable and _is_offer_locked(index)
		lock_button.disabled = not lockable
		lock_button.text = "LOCKED · KEEP" if locked else "LOCK OFFER"
		if locked:
			InfernalUiStyleRef.apply_primary_button(lock_button)
		else:
			InfernalUiStyleRef.apply_secondary_button(lock_button)

func _is_offer_locked(index: int) -> bool:
	if _shop_controller == null or not _shop_controller.has_method("is_offer_locked"):
		return false
	return _shop_controller.call("is_offer_locked", index) == true

func _on_lock_pressed(index: int) -> void:
	if _shop_controller == null or not _shop_controller.has_method("toggle_offer_lock"):
		return
	_shop_controller.call("toggle_offer_lock", index)
	if index >= 0 and index < _lock_buttons.size():
		MenuAnimationRuntimeRef.pulse_focus(_lock_buttons[index], 1.035)
