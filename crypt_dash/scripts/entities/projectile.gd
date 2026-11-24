class_name Projectile
extends Area2D
## Universelles Projektil für Spieler und Gegner mit geformter Silhouette, Schweif-Spur und Einschlagsfunken.

@export var speed: float = 650.0
@export var damage: int = 1
@export var is_player: bool = true
@export var pierce: bool = false
@export var life_time: float = 3.0
@export var radius_scale: float = 1.0
@export var tint: Color = Color("22d3ee")
@export var visual_style: String = "dagger"

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0
var _hitbox: HitboxComponent
var _trail: Line2D
var _trail_points: PackedVector2Array = PackedVector2Array()
var _light: PointLight2D
var _destroyed: bool = false


func _ready() -> void:
	z_index = 12
	collision_layer = 0
	collision_mask = 1 # Wände (Layer 1)
	body_entered.connect(_on_body_entered)

	_hitbox = HitboxComponent.new()
	_hitbox.damage = damage
	_hitbox.is_player = is_player
	_hitbox.source_node = self
	_hitbox.hit_landed.connect(func(_target: Node2D) -> void:
		if _destroyed:
			return
		var col := tint if is_player else Color("f87171")
		CryptVfx.spawn_burst(get_parent(), global_position, col, 6, 140.0, 3.2)
		if not pierce:
			_destroy()
	)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0 * radius_scale
	shape.shape = circle
	_hitbox.add_child(shape)
	add_child(_hitbox)

	var base_col := tint if is_player else Color("f87171")
	_trail = Line2D.new()
	_trail.top_level = true
	_trail.z_index = 11
	_trail.width = 5.5 * radius_scale
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(base_col.r, base_col.g, base_col.b, 0.0), Color(base_col.r, base_col.g, base_col.b, 0.72)])
	_trail.gradient = grad
	var w_curve := Curve.new()
	w_curve.add_point(Vector2(0.0, 0.15))
	w_curve.add_point(Vector2(1.0, 1.0))
	_trail.width_curve = w_curve
	add_child(_trail)
	_trail_points.append(global_position)

	if is_player or visual_style == "boss_bolt":
		_light = PointLight2D.new()
		_light.texture = CryptAssets.get_radial_light_texture()
		_light.color = base_col
		_light.energy = 0.52
		_light.texture_scale = 0.65 * radius_scale
		add_child(_light)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta

	_trail_points.append(global_position)
	if _trail_points.size() > 7:
		_trail_points.remove_at(0)
	if _trail != null:
		_trail.points = _trail_points

	# Verhindert Projektile außerhalb der Raumwände
	if global_position.x < 48.0 or global_position.x > float(CryptDashConfig.ROOM_PIXEL_WIDTH) - 48.0 \
			or global_position.y < 48.0 or global_position.y > float(CryptDashConfig.ROOM_PIXEL_HEIGHT) - 48.0:
		var col := tint if is_player else Color("f87171")
		CryptVfx.spawn_burst(get_parent(), global_position, col, 6, 120.0, 3.0)
		_destroy()
		return

	if _time_alive >= life_time:
		_destroy()
		return

	queue_redraw()


func _draw() -> void:
	var color := tint if is_player else Color("f87171")
	var ang := direction.angle()
	var sc := radius_scale

	match visual_style:
		"arcane_orb":
			draw_circle(Vector2.ZERO, 13.0 * sc, Color(color.r, color.g, color.b, 0.28))
			draw_circle(Vector2.ZERO, 8.5 * sc, color)
			draw_arc(Vector2.ZERO, 10.5 * sc, _time_alive * 8.0, _time_alive * 8.0 + PI * 1.4, 14, Color("f5d0fe"), 2.0)
			draw_circle(Vector2.ZERO, 4.0 * sc, Color.WHITE)
		"twin_fang":
			var p := PackedVector2Array([
				Vector2(13.0 * sc, 0.0).rotated(ang),
				Vector2(-4.0 * sc, -5.5 * sc).rotated(ang),
				Vector2(-10.0 * sc, 0.0).rotated(ang),
				Vector2(-4.0 * sc, 5.5 * sc).rotated(ang),
			])
			draw_circle(Vector2.ZERO, 10.0 * sc, Color(color.r, color.g, color.b, 0.28))
			draw_colored_polygon(p, color)
			draw_line(Vector2(-7.0 * sc, 0.0).rotated(ang), Vector2(11.0 * sc, 0.0).rotated(ang), Color.WHITE, 2.0)
		"enemy_arrow":
			var tail := Vector2(-13.0 * sc, 0.0).rotated(ang)
			var tip := Vector2(12.0 * sc, 0.0).rotated(ang)
			draw_line(tail, tip, Color("fed7aa"), 2.6 * sc)
			var head := PackedVector2Array([
				Vector2(15.0 * sc, 0.0).rotated(ang),
				Vector2(4.0 * sc, -4.5 * sc).rotated(ang),
				Vector2(6.0 * sc, 0.0).rotated(ang),
				Vector2(4.0 * sc, 4.5 * sc).rotated(ang),
			])
			draw_colored_polygon(head, Color("f97316"))
			draw_circle(tip, 4.5 * sc, Color(0.98, 0.45, 0.09, 0.38))
		"boss_bolt":
			var bolt := PackedVector2Array([
				Vector2(13.0 * sc, 0.0).rotated(ang),
				Vector2(0.0, -6.5 * sc).rotated(ang),
				Vector2(-10.0 * sc, -3.0 * sc).rotated(ang),
				Vector2(-10.0 * sc, 3.0 * sc).rotated(ang),
				Vector2(0.0, 6.5 * sc).rotated(ang),
			])
			draw_circle(Vector2.ZERO, 12.0 * sc, Color(0.94, 0.27, 0.27, 0.35))
			draw_colored_polygon(bolt, Color("ef4444"))
			draw_circle(Vector2(2.0 * sc, 0.0).rotated(ang), 3.2 * sc, Color("fef08a"))
		_:
			# "dagger" (Standard-Schattendolch)
			var blade := PackedVector2Array([
				Vector2(14.0 * sc, 0.0).rotated(ang),
				Vector2(-2.0 * sc, -4.8 * sc).rotated(ang),
				Vector2(-11.0 * sc, 0.0).rotated(ang),
				Vector2(-2.0 * sc, 4.8 * sc).rotated(ang),
			])
			draw_circle(Vector2.ZERO, 11.0 * sc, Color(color.r, color.g, color.b, 0.3))
			draw_colored_polygon(blade, color)
			draw_line(Vector2(-6.0 * sc, 0.0).rotated(ang), Vector2(12.0 * sc, 0.0).rotated(ang), Color.WHITE, 2.0)


func _on_body_entered(_body: Node2D) -> void:
	if _destroyed:
		return
	var col := tint if is_player else Color("f87171")
	CryptVfx.spawn_burst(get_parent(), global_position, col, 7, 145.0, 3.2)
	_destroy()


func _destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	set_deferred("monitoring", false)
	if _hitbox != null and is_instance_valid(_hitbox):
		_hitbox.set_deferred("monitoring", false)
		_hitbox.set_deferred("monitorable", false)
	queue_free()
