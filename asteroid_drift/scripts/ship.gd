class_name Ship
extends CharacterBody2D
## Spielerschiff mit Trägheitsphysik, Schießen, Schild und Hyperspace.

signal fired_bullet(pos: Vector2, vel: Vector2, explosive: bool)
signal took_damage(new_lives: int, shield_val: float)
signal destroyed()
signal hyperspace_used(success: bool)

var thrust_power := Constants.SHIP_THRUST
var turn_speed := Constants.SHIP_TURN_SPEED
var max_speed := Constants.SHIP_MAX_SPEED
var fire_rate := Constants.SHIP_FIRE_RATE

var shield_max := Constants.SHIP_SHIELD_MAX_DEFAULT
var shield_current := 1.0
var shield_recharge_timer := 0.0

var lives := 3
var is_invulnerable := false
var _invulnerable_timer := 0.0
var _fire_cooldown := 0.0

# Upgrades
var has_double_shot := false
var spread_shot_count := 0
var has_explosive_bullets := false
var magnet_radius := 0.0
var fire_rate_mul := 1.0

# Autopilot für Smoke-Tests
var autoplay := false

@onready var ship_poly: Polygon2D = $Visuals/ShipPoly
@onready var wing_left: Polygon2D = $Visuals/WingLeft
@onready var wing_right: Polygon2D = $Visuals/WingRight
@onready var outline: Line2D = $Visuals/Line2D
@onready var thruster_flame: Polygon2D = $Visuals/ThrusterFlame
@onready var shield_bubble: Line2D = $ShieldBubble
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	collision_layer = 1 << 0 # layer 1: player
	collision_mask = (1 << 1) | (1 << 3) # asteroids, enemies

	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)

	shield_current = shield_max
	_update_shield_visual()


func apply_upgrades(acquired_counts: Dictionary) -> void:
	has_double_shot = int(acquired_counts.get("double_shot", 0)) > 0
	spread_shot_count = int(acquired_counts.get("spread_shot", 0))
	has_explosive_bullets = int(acquired_counts.get("explosive_ammo", 0)) > 0

	var rapid_stacks: int = int(acquired_counts.get("rapid_fire", 0))
	fire_rate_mul = pow(0.8, rapid_stacks)

	var shield_stacks: int = int(acquired_counts.get("shield_boost", 0))
	shield_max = Constants.SHIP_SHIELD_MAX_DEFAULT + float(shield_stacks)
	shield_current = minf(shield_current + float(shield_stacks), shield_max)

	var magnet_stacks: int = int(acquired_counts.get("magnet", 0))
	magnet_radius = float(magnet_stacks) * 200.0

	_update_shield_visual()


func _physics_process(delta: float) -> void:
	var turn_input := 0.0
	var is_thrusting := false
	var wants_fire := false

	if autoplay:
		var auto_controls := _compute_autopilot_controls()
		turn_input = auto_controls["turn"]
		is_thrusting = auto_controls["thrust"]
		wants_fire = auto_controls["fire"]
		if auto_controls.get("hyperspace", false):
			trigger_hyperspace()
	else:
		if Input.is_action_pressed("rotate_left"):
			turn_input -= 1.0
		if Input.is_action_pressed("rotate_right"):
			turn_input += 1.0
		if Input.is_action_pressed("thrust"):
			is_thrusting = true
		if Input.is_action_pressed("fire"):
			wants_fire = true
		if Input.is_action_just_pressed("hyperspace"):
			trigger_hyperspace()

	# Drehung
	rotation += turn_input * turn_speed * delta

	# Schub & Dämpfung
	if is_thrusting:
		velocity += Vector2.UP.rotated(rotation) * thrust_power * delta
		thruster_flame.visible = true
	else:
		thruster_flame.visible = false

	velocity *= pow(Constants.SHIP_DAMPING, delta)
	velocity = velocity.limit_length(max_speed)

	# Bewegung
	global_position += velocity * delta
	global_position = ScreenWrap.wrap_position(global_position, Constants.VIEWPORT_RECT)

	# Schießen
	_fire_cooldown -= delta
	if wants_fire and _fire_cooldown <= 0.0:
		_fire()
		_fire_cooldown = fire_rate * fire_rate_mul

	# Schild-Aufladung
	if shield_current < shield_max:
		shield_recharge_timer += delta
		if shield_recharge_timer >= Constants.SHIP_SHIELD_RECHARGE_DELAY:
			shield_current = minf(shield_current + (Constants.SHIP_SHIELD_RECHARGE_RATE * delta), shield_max)
			_update_shield_visual()

	# Unverwundbarkeit & Blinken
	if is_invulnerable:
		_invulnerable_timer -= delta
		visible = int(_invulnerable_timer * 12.0) % 2 == 0
		if _invulnerable_timer <= 0.0:
			is_invulnerable = false
			visible = true


func _fire() -> void:
	var fwd := Vector2.UP.rotated(rotation)
	var right_vec := Vector2.RIGHT.rotated(rotation)
	var bullet_speed := Constants.SHIP_BULLET_SPEED
	var base_bullet_vel := (fwd * bullet_speed) + (velocity * 0.4)

	if has_double_shot:
		# Zwei parallele Schüsse
		fired_bullet.emit(global_position + (right_vec * 14.0) + (fwd * 15.0), base_bullet_vel, has_explosive_bullets)
		fired_bullet.emit(global_position - (right_vec * 14.0) + (fwd * 15.0), base_bullet_vel, has_explosive_bullets)
	else:
		# Ein zentraler Schuss
		fired_bullet.emit(global_position + (fwd * 25.0), base_bullet_vel, has_explosive_bullets)

	# Streuschuss
	for i in range(spread_shot_count):
		var angle_off := deg_to_rad(18.0 * float(i + 1))
		var vel_left := base_bullet_vel.rotated(-angle_off)
		var vel_right := base_bullet_vel.rotated(angle_off)
		fired_bullet.emit(global_position + (fwd * 20.0), vel_left, has_explosive_bullets)
		fired_bullet.emit(global_position + (fwd * 20.0), vel_right, has_explosive_bullets)


func trigger_hyperspace() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Neuer zufälliger Ort
	var new_pos := Vector2(
		rng.randf_range(100.0, Constants.VIEWPORT_WIDTH - 100.0),
		rng.randf_range(100.0, Constants.VIEWPORT_HEIGHT - 100.0)
	)
	global_position = new_pos
	velocity = Vector2.ZERO

	# 15% Fehlschlagrisiko
	var failed: bool = rng.randf() < Constants.SHIP_HYPERSPACE_FAIL_CHANCE
	if failed:
		if shield_current >= 1.0:
			shield_current = 0.0
			shield_recharge_timer = 0.0
			_update_shield_visual()
		else:
			take_damage()
		hyperspace_used.emit(false)
	else:
		hyperspace_used.emit(true)


func take_damage() -> void:
	if is_invulnerable:
		return

	if shield_current >= 1.0:
		shield_current -= 1.0
		shield_recharge_timer = 0.0
		_update_shield_visual()
		took_damage.emit(lives, shield_current)
		return

	lives -= 1
	took_damage.emit(lives, shield_current)

	if lives <= 0:
		destroyed.emit()
		visible = false
		set_physics_process(false)
	else:
		respawn()


func respawn() -> void:
	global_position = Vector2(Constants.VIEWPORT_WIDTH * 0.5, Constants.VIEWPORT_HEIGHT * 0.5)
	velocity = Vector2.ZERO
	rotation = 0.0
	is_invulnerable = true
	_invulnerable_timer = Constants.SHIP_INVULNERABILITY_TIME
	visible = true


func repair_shield(amount: float) -> void:
	shield_current = minf(shield_current + amount, shield_max)
	_update_shield_visual()


func _update_shield_visual() -> void:
	if not shield_bubble:
		return
	if shield_current >= 1.0:
		shield_bubble.visible = true
		shield_bubble.modulate.a = clampf(shield_current / shield_max, 0.4, 1.0)
	else:
		shield_bubble.visible = false


func _on_hitbox_area_entered(other: Area2D) -> void:
	if is_invulnerable:
		return
	if other is Asteroid or other is UFO or other is Mine or (other is Bullet and other.is_enemy):
		take_hit_from_source(other)


func take_hit_from_source(source: Area2D) -> void:
	take_damage()
	if source is Bullet:
		source.destroy()
	elif source is Mine:
		source.explode()


func _compute_autopilot_controls() -> Dictionary:
	var turn := 0.0
	var thrust := false
	var fire := true

	# Finde nächsten Asteroiden oder Feind
	var nearest_target: Node2D = null
	var min_dist := 999999.0
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if (child is Asteroid or child is UFO or child is Mine) and is_instance_valid(child):
				var d := global_position.distance_to(child.global_position)
				if d < min_dist:
					min_dist = d
					nearest_target = child

	if nearest_target:
		var target_dir := (nearest_target.global_position - global_position).normalized()
		var ship_dir := Vector2.UP.rotated(rotation)
		var angle_diff := ship_dir.angle_to(target_dir)

		if angle_diff > 0.15:
			turn = 1.0
		elif angle_diff < -0.15:
			turn = -1.0

		# Wenn Feind/Asteroid zu nah ist, Abstand gewinnen oder schießen
		if min_dist < 180.0:
			thrust = true
		elif absf(angle_diff) < 0.3:
			thrust = (velocity.length() < 220.0)
	else:
		# Langsames Drehen zum Erkunden
		turn = 0.5
		thrust = (velocity.length() < 150.0)

	return {
		"turn": turn,
		"thrust": thrust,
		"fire": fire,
		"hyperspace": false
	}
