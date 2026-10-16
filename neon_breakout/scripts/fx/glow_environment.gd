class_name GlowEnvironment
extends WorldEnvironment
## Leuchteffekt (Bloom) für das 2D-Spiel. Folgt der Einstellung in FxSettings.
## Helle Farben (Werte über 1, siehe Ball, Funken) leuchten besonders stark.


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_intensity = 0.8
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 0.75
	env.glow_hdr_scale = 1.5
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 0.6)
	env.set_glow_level(2, 1.0)
	env.set_glow_level(3, 1.0)
	env.set_glow_level(4, 0.6)
	env.set_glow_level(5, 0.0)
	env.set_glow_level(6, 0.0)
	environment = env
	FxSettings.changed.connect(_apply)
	_apply()


func _apply() -> void:
	environment.glow_enabled = FxSettings.glow_enabled()
