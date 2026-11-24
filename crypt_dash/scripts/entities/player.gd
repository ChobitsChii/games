class_name Player
extends CharacterBody2D
## Spieler-Charakter für Crypt Dash mit hochauflösendem Sprite-Rig, sichtbarer Startwaffe, Licht & Dash-Nachbildern.

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
var _aim_dir: Vector2 = Vector2.RIGHT
var _equipped_weapon_id: String = "daggers"
var touch_aim_dir: Vector2 = Vector2.ZERO
var touch_aim_active: bool = false

var _visual: EntityVisual
var _weapon_sprite: Sprite2D
var _player_light: PointLight2D
var _afterimage_timer: float = 0.0
var _weapon_recoil: float = 0.0


func _ready() -> void:
	z_index = 10
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
	var h_circle := CircleShape2D.new()
	h_circle.radius = 20.0
	h_shape.shape = h_circle
	_hurtbox.add_child(h_shape)
	add_child(_hurtbox)

	var body_col := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 20.0
	body_col.shape = body_circle
	add_child(body_col)

	_visual = EntityVisual.new()
	_visual.setup(CryptAssets.get_texture("res://assets/sprites/player_rogue.png"), 80.0, Vector2(0.55, 0.45), false, 0.0, 1.0)
	add_child(_visual)

	_weapon_sprite = Sprite2D.new()
	_weapon_sprite.z_index = 2
	_weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_weapon_sprite)

	_player_light = PointLight2D.new()
	_player_light.texture = CryptAssets.get_radial_light_texture()
	_player_light.color = Color("bfefff")
	_player_light.energy = 0.85
	_player_light.texture_scale = 2.6
	add_child(_player_light)

	recalculate_stats()


func recalculate_stats() -> void:
	_equipped_weapon_id = WeaponCatalog.get_equipped_id()
	stats = PlayerStatsCalculator.calculate_stats(items, meta_upgrades)
	stats = WeaponCatalog.apply_weapon_to_stats(stats, _equipped_weapon_id)
	max_hp = int(stats["max_hp"])
	current_hp = mini(current_hp if current_hp > 0 else max_hp, max_hp)
	move_speed = float(stats["speed"])
	damage = float(stats["damage"])
	dash_cooldown = float(stats["dash_cooldown"])
	dash_speed = float(stats["dash_speed"])
	dash_duration = float(stats["dash_duration"])
	attack_cooldown = 1.0 / float(stats["attack_rate"])

	if _weapon_sprite != null:
		var w_tex := CryptAssets.get_texture(CryptAssets.get_weapon_sprite_path(_equipped_weapon_id))
		_weapon_sprite.texture = w_tex
		if w_tex != null and w_tex.get_size().x > 0.0:
			var sc := 34.0 / maxf(w_tex.get_size().x, w_tex.get_size().y)
			_weapon_sprite.scale = Vector2(sc, sc)

	_health.init_health(max_hp)
	_health.current_health = current_hp
	health_changed.emit(current_hp, max_hp)


func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
		dash_cooldown_progress.emit(dash_cooldown_timer, dash_cooldown)

	if attack_timer > 0.0:
		attack_timer = maxf(0.0, attack_timer - delta)

	if _weapon_recoil > 0.0:
		_weapon_recoil = maxf(0.0, _weapon_recoil - delta * 42.0)

	if autoplay:
		_handle_autoplay(delta)
	else:
		_handle_player_input(delta)

	if is_dashing:
		_afterimage_timer -= delta
		if _afterimage_timer <= 0.0:
			_afterimage_timer = 0.042
			if _visual != null and _visual.main_sprite != null:
				CryptVfx.spawn_dash_afterimage(
					get_parent(),
					global_position,
					_visual.main_sprite.texture,
					80.0,
					_visual.main_sprite.flip_h
				)

	if _visual != null:
		_visual.update_motion(delta, velocity, _aim_dir if _aim_dir != Vector2.ZERO else _facing)
		if is_dashing:
			_visual.set_tint(Color(0.65, 0.95, 1.0, 0.85))
		else:
			_visual.set_tint(Color.WHITE)

	if _weapon_sprite != null:
		var aim := _aim_dir.normalized() if _aim_dir != Vector2.ZERO else _facing
		_weapon_sprite.position = aim * (24.0 + _weapon_recoil) + Vector2(0.0, 4.0)
		_weapon_sprite.rotation = aim.angle()
		_weapon_sprite.flip_v = aim.x < 0.0


func _handle_player_input(delta: float) -> void:
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if move_input != Vector2.ZERO:
		_facing = move_input.normalized()

	if touch_aim_active or OS.has_feature("android"):
		if touch_aim_dir != Vector2.ZERO:
			_aim_dir = touch_aim_dir.normalized()
		else:
			_aim_dir = _find_nearest_enemy_dir()
	else:
		var m_dir := get_global_mouse_position() - global_position
		if m_dir.length_squared() > 4.0:
			_aim_dir = m_dir.normalized()
		else:
			_aim_dir = _facing

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
		var aim_dir := _aim_dir if _aim_dir != Vector2.ZERO else _facing
		perform_attack(aim_dir)


func _find_nearest_enemy_dir() -> Vector2:
	if not is_inside_tree():
		return _facing
	var best_dist := INF
	var best_dir := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node) and not node.is_queued_for_deletion():
			var n2d := node as Node2D
			var d := global_position.distance_squared_to(n2d.global_position)
			if d > 1.0 and d < best_dist:
				best_dist = d
				best_dir = (n2d.global_position - global_position).normalized()
	return best_dir if best_dir != Vector2.ZERO else _facing


func _handle_autoplay(delta: float) -> void:
	autoplay_timer += delta
	var move_dir := Vector2(cos(autoplay_timer * 2.0), sin(autoplay_timer * 2.0))
	_facing = move_dir
	_aim_dir = Vector2(cos(autoplay_timer * 4.0), sin(autoplay_timer * 4.0))
	velocity = move_dir * move_speed
	move_and_slide()

	if attack_timer <= 0.0:
		perform_attack(_aim_dir)

	if dash_cooldown_timer <= 0.0 and fmod(autoplay_timer, 2.5) < 0.2:
		start_dash(_facing)


func start_dash(dir: Vector2) -> void:
	is_dashing = true
	dash_timer = 0.0
	_afterimage_timer = 0.0
	dash_direction = dir.normalized()
	dash_cooldown_timer = dash_cooldown
	_hurtbox.invulnerable = true
	CryptAudio.play_dash()
	CryptVfx.spawn_burst(get_parent(), global_position, Color("38bdf8"), 10, 190.0, 4.0)


func perform_attack(dir: Vector2) -> void:
	attack_timer = attack_cooldown
	_weapon_recoil = 8.0
	CryptAudio.play_shoot()
	var weapon := WeaponCatalog.get_weapon(_equipped_weapon_id)

	var has_spread := false
	var has_pierce := false
	for it in items:
		if it.special_tag == "spread": has_spread = true
		if it.special_tag == "pierce": has_pierce = true

	var style := "dagger"
	if _equipped_weapon_id == "twin_fangs":
		style = "twin_fang"
	elif _equipped_weapon_id == "arcane_staff":
		style = "arcane_orb"

	var angles := [0.0]
	if has_spread:
		angles = [-0.25, 0.0, 0.25]

	for ang in angles:
		var p := Projectile.new()
		p.global_position = global_position + dir * 24.0
		p.direction = dir.rotated(ang)
		p.damage = int(roundf(damage))
		p.speed = float(weapon.get("speed", 650.0))
		p.is_player = true
		p.pierce = has_pierce or bool(weapon.get("pierce", false))
		p.radius_scale = float(weapon.get("radius_scale", 1.0))
		p.tint = weapon.get("color", Color("22d3ee"))
		p.visual_style = style
		get_parent().add_child(p)


func _on_hit_received(dmg: int, _knockback: Vector2, _from_player: bool) -> void:
	if is_dashing:
		return
	CryptAudio.play_hit()
	if _visual != null:
		_visual.flash_hit(Color("ff6b6b"), 0.18)
	CryptVfx.spawn_burst(get_parent(), global_position, Color("ef4444"), 10, 175.0, 4.0)
	_health.take_damage(dmg)
	EventBus.screen_shake_requested.emit(8.0, 0.2)


func _on_health_changed(c: int, m: int) -> void:
	current_hp = c
	max_hp = m
	health_changed.emit(c, m)
	EventBus.player_damaged.emit(c, m)


func _on_died() -> void:
	player_died.emit()
	EventBus.game_over.emit.call_deferred()
