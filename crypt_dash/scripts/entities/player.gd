class_name Player
extends CharacterBody2D
## Spieler-Charakter für Crypt Dash.
## Steuerung: WASD/Pfeile, Dash mit Space/A, Schuss mit Klick/J.

signal health_changed(current: int, max_hp: int)
signal dash_cooldown_progress(current: float, max_cd: float)
signal player_died

var stats: Dictionary = {}
var items: Array[ItemData] = []
var meta_upgrades: Dictionary = {}

var current_hp: int = 12
var max_hp: int = 12
var move_speed: float = 420.0
var damage: float = 1.0

# Dash Mechanik
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_duration: float = 0.18
var dash_speed: float = 1400.0
var dash_cooldown: float = 0.8
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT

# Angriff
var attack_cooldown: float = 0.3
var attack_timer: float = 0.0

# Autopilot (für Smoke-Test)
var autoplay: bool = false
var autoplay_timer: float = 0.0

var _health: HealthComponent
var _hurtbox: HurtboxComponent
var _facing: Vector2 = Vector2.RIGHT


func _ready() -> void:
	collision_layer = 2 # Spieler (Layer 2)
	collision_mask = 1  # Wände (Layer 1)

	_health = HealthComponent.new()
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	add_child(_health)

	_hurtbox = HurtboxComponent.new()
	_hurtbox.is_player = true
	_hurtbox.hit_received.connect(_on_hit_received)
	var h_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	h_shape.shape = circle
	_hurtbox.add_child(h_shape)
	add_child(_hurtbox)

	var body_col := CollisionShape2D.new()
	body_col.shape = circle
	add_child(body_col)

	recalculate_stats()


func recalculate_stats() -> void:
	stats = PlayerStatsCalculator.calculate_stats(items, meta_upgrades)
	max_hp = int(stats["max_hp"])
	current_hp = mini(current_hp if current_hp > 0 else max_hp, max_hp)
	move_speed = float(stats["speed"])
	damage = float(stats["damage"])
	dash_cooldown = float(stats["dash_cooldown"])
	dash_speed = float(stats["dash_speed"])
	dash_duration = float(stats["dash_duration"])
	attack_cooldown = 1.0 / float(stats["attack_rate"])

	_health.init_health(max_hp)
	_health.current_health = current_hp
	health_changed.emit(current_hp, max_hp)


func _physics_process(delta: float) -> void:
	# Cooldowns herunterzählen
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
		dash_cooldown_progress.emit(dash_cooldown_timer, dash_cooldown)

	if attack_timer > 0.0:
		attack_timer = maxf(0.0, attack_timer - delta)

	if autoplay:
		_handle_autoplay(delta)
	else:
		_handle_player_input(delta)

	queue_redraw()


func _handle_player_input(delta: float) -> void:
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if move_input != Vector2.ZERO:
		_facing = move_input.normalized()

	# Dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		start_dash(_facing)

	if is_dashing:
		dash_timer += delta
		velocity = dash_direction * dash_speed
		move_and_slide()
		if dash_timer >= dash_duration:
			is_dashing = false
			_hurtbox.invulnerable = false
	else:
		velocity = move_input * move_speed
		move_and_slide()

	# Angriff
	if Input.is_action_pressed("attack") and attack_timer <= 0.0:
		var aim_dir := (get_global_mouse_position() - global_position).normalized()
		if aim_dir == Vector2.ZERO:
			aim_dir = _facing
		perform_attack(aim_dir)


func _handle_autoplay(delta: float) -> void:
	autoplay_timer += delta
	# Kreisbewegung oder Raummitte ansteuern
	var move_dir := Vector2(cos(autoplay_timer * 2.0), sin(autoplay_timer * 2.0))
	_facing = move_dir
	velocity = move_dir * move_speed
	move_and_slide()

	# Automatischer Angriff
	if attack_timer <= 0.0:
		perform_attack(Vector2(cos(autoplay_timer * 4.0), sin(autoplay_timer * 4.0)))

	# Gelegentlicher Dash
	if dash_cooldown_timer <= 0.0 and fmod(autoplay_timer, 2.5) < 0.2:
		start_dash(_facing)


func start_dash(dir: Vector2) -> void:
	is_dashing = true
	dash_timer = 0.0
	dash_direction = dir.normalized()
	dash_cooldown_timer = dash_cooldown
	_hurtbox.invulnerable = true


func perform_attack(dir: Vector2) -> void:
	attack_timer = attack_cooldown

	var has_spread := false
	var has_pierce := false
	for it in items:
		if it.special_tag == "spread": has_spread = true
		if it.special_tag == "pierce": has_pierce = true

	var angles := [0.0]
	if has_spread:
		angles = [-0.25, 0.0, 0.25]

	for ang in angles:
		var p := Projectile.new()
		p.global_position = global_position + dir * 24.0
		p.direction = dir.rotated(ang)
		p.damage = int(roundf(damage))
		p.is_player = true
		p.pierce = has_pierce
		get_parent().add_child(p)


func _on_hit_received(dmg: int, _knockback: Vector2, _from_player: bool) -> void:
	if is_dashing:
		return
	_health.take_damage(dmg)
	EventBus.screen_shake_requested.emit(8.0, 0.2)


func _on_health_changed(c: int, m: int) -> void:
	current_hp = c
	max_hp = m
	health_changed.emit(c, m)
	EventBus.player_damaged.emit(c, m)


func _on_died() -> void:
	player_died.emit()
	EventBus.game_over.emit()


func _draw() -> void:
	# Moderner Vektor-Charakter
	var body_color := Color("06b6d4")
	if is_dashing:
		body_color = Color("67e8f9")
		# Dash Nachbild
		draw_circle(-dash_direction * 20.0, 18.0, Color(0.2, 0.8, 0.9, 0.3))

	# Schatten
	draw_circle(Vector2(0, 8), 22.0, Color(0, 0, 0, 0.35))
	# Körper
	draw_circle(Vector2.ZERO, 20.0, body_color)
	draw_circle(Vector2.ZERO, 15.0, Color("0f172a"))
	# Blickrichtung / Augen
	var eye_offset := _facing * 9.0
	draw_circle(eye_offset + Vector2(-4, -2), 3.5, Color("38bdf8"))
	draw_circle(eye_offset + Vector2(4, -2), 3.5, Color("38bdf8"))
