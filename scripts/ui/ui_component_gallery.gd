extends Control

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")

@onready var title_label: Label = $RootMargin/Scroll/Content/Title
@onready var intro_label: Label = $RootMargin/Scroll/Content/Intro
@onready var buttons_title: Label = $RootMargin/Scroll/Content/ButtonsTitle
@onready var cards_title: Label = $RootMargin/Scroll/Content/CardsTitle
@onready var modal_title: Label = $RootMargin/Scroll/Content/ModalTitle
@onready var primary_button: Button = $RootMargin/Scroll/Content/ButtonRow/Primary
@onready var secondary_button: Button = $RootMargin/Scroll/Content/ButtonRow/Secondary
@onready var danger_button: Button = $RootMargin/Scroll/Content/ButtonRow/Danger
@onready var tab_button: Button = $RootMargin/Scroll/Content/ButtonRow/Tab
@onready var disabled_button: Button = $RootMargin/Scroll/Content/ButtonRow/Disabled
@onready var first_card: Button = $RootMargin/Scroll/Content/CardRow/FirstCard
@onready var second_card: Button = $RootMargin/Scroll/Content/CardRow/SecondCard
@onready var modal_shell: PanelContainer = $RootMargin/Scroll/Content/ModalCenter/ModalShell

func _ready() -> void:
	InfernalUiStyleRef.apply_text_role(title_label, InfernalUiStyleRef.TEXT_DISPLAY_TITLE)
	InfernalUiStyleRef.apply_text_role(intro_label, InfernalUiStyleRef.TEXT_MUTED)
	for section_label in [buttons_title, cards_title, modal_title]:
		InfernalUiStyleRef.apply_text_role(section_label, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_button(primary_button, InfernalUiStyleRef.BUTTON_PRIMARY)
	InfernalUiStyleRef.apply_button(secondary_button, InfernalUiStyleRef.BUTTON_SECONDARY)
	InfernalUiStyleRef.apply_button(danger_button, InfernalUiStyleRef.BUTTON_DANGER)
	InfernalUiStyleRef.apply_button(tab_button, InfernalUiStyleRef.BUTTON_TAB)
	InfernalUiStyleRef.apply_button(disabled_button, InfernalUiStyleRef.BUTTON_SECONDARY)
	disabled_button.disabled = true
	_configure_cards()
	_configure_modal()
	primary_button.grab_focus()

func _configure_cards() -> void:
	first_card.call("configure", "Frontier Damage", "A standard selectable card using the shared layout and text roles.", "LEVEL UP", "+10% damage", "Select")
	second_card.call("configure", "Cursed Tempo", "The same component can represent another choice without a new screen-specific card style.", "ASCENSION", "+8% attack speed", "Select")
	first_card.call("set_selected", true)
	first_card.pressed.connect(_select_card.bind(first_card, second_card))
	second_card.pressed.connect(_select_card.bind(second_card, first_card))

func _select_card(selected_card: Button, other_card: Button) -> void:
	selected_card.call("set_selected", true)
	other_card.call("set_selected", false)

func _configure_modal() -> void:
	modal_shell.call("configure", "Standard Modal", "Shared shell, spacing, semantic text, and action hierarchy.")
	var content_container: VBoxContainer = modal_shell.call("get_content_container") as VBoxContainer
	if content_container != null:
		var body := Label.new()
		body.text = "Pause, Results, Level Up, Portal Mutation, and Ascension can reuse this structural shell instead of rebuilding the same frame."
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		InfernalUiStyleRef.apply_text_role(body, InfernalUiStyleRef.TEXT_BODY)
		content_container.add_child(body)
	var actions_container: HBoxContainer = modal_shell.call("get_actions_container") as HBoxContainer
	if actions_container != null:
		var back_button := Button.new()
		back_button.text = "Back"
		InfernalUiStyleRef.apply_button(back_button, InfernalUiStyleRef.BUTTON_SECONDARY)
		actions_container.add_child(back_button)
		var confirm_button := Button.new()
		confirm_button.text = "Confirm"
		InfernalUiStyleRef.apply_button(confirm_button, InfernalUiStyleRef.BUTTON_PRIMARY)
		actions_container.add_child(confirm_button)
