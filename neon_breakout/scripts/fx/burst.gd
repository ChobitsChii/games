class_name Burst
extends CPUParticles2D
## Einmaliger Partikelausbruch (Funken). Räumt sich nach dem Ende selbst auf.
## CPUParticles2D statt GPUParticles2D: im Web zuverlässiger und für diese
## Mengen schnell genug.

## Weicher runder Punkt für die Funken. Wird von FxSettings einmal erzeugt und geteilt
## (kein statischer Zwischenspeicher, damit beim Beenden nichts übrig bleibt).
static func make_glow_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	return texture


## `amount` bereits an die Effektqualität angepasst übergeben. `size` skaliert die Funken.
static func spawn(
		parent: Node,
		pos: Vector2,
		color: Color,
		amount: int = 18,
		speed: float = 360.0,
		lifetime: float = 0.55,
		direction: Vector2 = Vector2.ZERO,
		spread_degrees: float = 180.0,
		size: float = 1.0) -> Burst:
	var burst := Burst.new()
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.amount = maxi(amount, 1)
	burst.lifetime = lifetime
	burst.lifetime_randomness = 0.4
	burst.local_coords = false
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 6.0
	burst.direction = direction
	burst.spread = spread_degrees
	burst.gravity = Vector2(0.0, 520.0)
	burst.initial_velocity_min = speed * 0.35
	burst.initial_velocity_max = speed
	burst.damping_min = 120.0
	burst.damping_max = 220.0
	burst.scale_amount_min = 0.12 * size
	burst.scale_amount_max = 0.38 * size
	burst.texture = FxSettings.get_glow_texture()
	# Werte über 1 lassen die Funken im Glow-Effekt leuchten.
	burst.color = Color(color.r * 1.6, color.g * 1.6, color.b * 1.6, 1.0)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	burst.color_ramp = fade
	burst.position = pos
	burst.z_index = 5
	parent.add_child(burst)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)
	return burst
