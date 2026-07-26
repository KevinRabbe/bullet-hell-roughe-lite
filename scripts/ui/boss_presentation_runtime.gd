class_name BossPresentationRuntime
extends RefCounted

const EventBannerRuntimeRef = preload("res://scripts/ui/event_banner_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

static func show_gate_beast_spawn(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_spawn", -5.0, 1.0, 400)
	EventBannerRuntimeRef.show(
		owner,
		"WAVE 5 MILESTONE",
		"GATE BEAST",
		"Break the guardian. Claim the Ascension beyond it."
	)

static func show_gate_beast_defeated(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_defeat", -5.0, 1.0, 400)
	EventBannerRuntimeRef.show(
		owner,
		"GUARDIAN BROKEN",
		"THE ASCENSION OPENS",
		"Clear the frontier and choose what the curse becomes."
	)
