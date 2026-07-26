class_name BossPresentationRuntime
extends RefCounted

const EventBannerRuntimeRef = preload("res://scripts/ui/event_banner_runtime.gd")

static func show_gate_beast_spawn(owner: Node) -> void:
	EventBannerRuntimeRef.show(
		owner,
		"WAVE 5 MILESTONE",
		"GATE BEAST",
		"Break the guardian. Claim the Ascension beyond it."
	)

static func show_gate_beast_defeated(owner: Node) -> void:
	EventBannerRuntimeRef.show(
		owner,
		"GUARDIAN BROKEN",
		"THE ASCENSION OPENS",
		"Clear the frontier and choose what the curse becomes."
	)
