class_name Player
extends CharacterBody2D
## Hauptfigur von Lumaria: Kaelen.
## Unterstützt 8-Wege-Bewegung, 4-Wege-Richtungstexturen, lebendige Schritt- und
## Atemanimationen (kein statisches Gleiten!), 3-Stufen-Schlagkombo, aufladbaren
## Rundumschlag (Spin Attack) mit visualisiertem Prisma-Waffen-Trail, Ausweichrolle,
## Schildblock & perfektes Timing-Parry mit Audio- und Trefferfeedback.

signal attacked()
signal rolled()
signal defended(is_parry: bool)
signal camera_shake_requested(trauma: float)

enum State { IDLE, WALK, ATTACK, SPIN_ATTACK, ROLL, BLOCK, PULL_TETHER }

const SPEED := 240.0
const ROLL_SPEED := 520.0
const ROLL_DURATION := 0.25
const ATTACK_DURATION := 0.20
const SPIN_DURATION := 0.28
const COMBO_WINDOW := 0.38
const CHARGE_TIME_REQUIRED := 0.42

const TEX_DOWN: Texture2D = preload("res://assets/characters/player/player_down.png")
const TEX_UP: Texture2D = preload("res://assets/characters/player/player_up.png")
const TEX_RIGHT: Texture2D = preload("res://assets/characters/player/player_right.png")
const TEX_LEFT: Texture2D = preload("res://assets/characters/player/player_left.png")
const TEX_ATTACK: Texture2D = preload("res://assets/characters/player/player_attack.png")

var current_state: State = State.IDLE
var facing_direction: Vector2 = Vector2.DOWN
var is_invulnerable: bool = false
var block_hold_time: float = 0.0

var is_input_locked: bool = false

var combo_step: int = 0
var combo_timer: float = 0.0
var sword_tier: int = 1

var _state_timer: float = 0.0
var _roll_direction: Vector2 = Vector2.DOWN
var _step_phase: float = 0.0
var _idle_phase: float = 0.0

var _attack_button_held_time: float = 0.0
var _is_charged: bool = false
var _charge_pulse: float = 0.0

@export var autoplay: bool = false
var _auto_timer: float = 0.0

@onready var _sword_hitbox: Area2D = $SwordHitbox
@onready var _spin_hitbox: Area2D = $SpinHitbox
@onready var _visuals: Node2D = $Visuals
@onready var _sprite: Sprite2D = %CharacterSprite
@onready var _slash_arc: Sprite2D = %SlashArc
@onready var _shadow: ColorRect = $Shadow


func _ready() -> void:
	if _sword_hitbox:
		_sword_hitbox.monitoring = false
	if _spin_hitbox:
		_spin_hitbox.monitoring = false
	if _slash_arc:
		_slash_arc.visible = false
	_update_texture()

	EventBus.dialogue_started.connect(func(_n: String, _t: String, _p: String) -> void:
		is_input_locked = true
		velocity = Vector2.ZERO
		current_state = State.IDLE
	)
	EventBus.dialogue_ended.connect(func() -> void:
		is_input_locked = false
	)


func _physics_process(delta: float) -> void:
	if is_input_locked:
		velocity = Vector2.ZERO
		current_state = State.IDLE
		move_and_slide()
		return

	# Combo-Zeitfenster verwalten
	if combo_step > 0 and current_state != State.ATTACK:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_step = 0

	match current_state:
		State.IDLE, State.WALK:
			_process_movement(delta)
			_process_combat_inputs(delta)
		State.ROLL:
			_process_roll(delta)
		State.ATTACK:
			_process_attack(delta)
		State.SPIN_ATTACK:
			_process_spin_attack(delta)
		State.BLOCK:
			_process_block(delta)
		State.PULL_TETHER:
			_process_tether_pull(delta)


func _process_movement(delta: float) -> void:
	var input_vec := Vector2.ZERO
	if autoplay:
		_auto_timer += delta
		var phase: int = int(_auto_timer) % 4
		match phase:
			0: input_vec = Vector2.RIGHT
			1: input_vec = Vector2.DOWN
			2: input_vec = Vector2.LEFT
			3: input_vec = Vector2.UP
		if fmod(_auto_timer, 1.4) < delta:
			start_attack()
		elif fmod(_auto_timer, 2.2) < delta:
			start_roll()
		elif fmod(_auto_timer, 3.2) < delta:
			throw_boomerang()
		elif fmod(_auto_timer, 4.4) < delta:
			fire_tether()
	else:
		input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vec.length_squared() > 0.01:
		input_vec = input_vec.normalized()
		velocity = input_vec * SPEED
		current_state = State.WALK
		_update_facing(input_vec)
		
		# Lebendige Schritt-Animation synchron zur Gehgeschwindigkeit
		_step_phase += delta * (velocity.length() / SPEED) * 14.0
		_visuals.position.y = -52.0 - absf(sin(_step_phase)) * 6.0
		_visuals.rotation = sin(_step_phase) * 0.05 + clampf(velocity.x * 0.0003, -0.06, 0.06)
		_sprite.scale = Vector2(0.46, 0.46)
	else:
		velocity = Vector2.ZERO
		current_state = State.IDLE
		
		# Sanfte Atemanimation im Stillstand
		_idle_phase += delta * 2.8
		_visuals.position.y = -52.0 + sin(_idle_phase) * 1.5
		_visuals.rotation = move_toward(_visuals.rotation, 0.0, delta * 3.0)
		_sprite.scale = Vector2(0.46, 0.46 + sin(_idle_phase) * 0.008)

	move_and_slide()


func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing_direction = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		facing_direction = Vector2.DOWN if dir.y > 0 else Vector2.UP
	
	_update_texture()

	# Schwert-Hitbox vor der Figur ausrichten
	if _sword_hitbox:
		_sword_hitbox.position = facing_direction * 48.0


func _update_texture() -> void:
	if current_state == State.ATTACK or current_state == State.SPIN_ATTACK:
		_sprite.texture = TEX_ATTACK
		_sprite.flip_h = (facing_direction == Vector2.LEFT)
		return

	_sprite.flip_h = false
	if facing_direction == Vector2.UP:
		_sprite.texture = TEX_UP
	elif facing_direction == Vector2.LEFT:
		_sprite.texture = TEX_LEFT
	elif facing_direction == Vector2.RIGHT:
		_sprite.texture = TEX_RIGHT
	else:
		_sprite.texture = TEX_DOWN


func _process_combat_inputs(delta: float) -> void:
	if autoplay:
		return

	# Auflade-Mechanik für Rundumschlag (Attack-Taste gedrückt halten)
	if Input.is_action_pressed("attack"):
		_attack_button_held_time += delta
		if _attack_button_held_time >= CHARGE_TIME_REQUIRED:
			if not _is_charged:
				_is_charged = true
				AudioManager.play_sfx("slash", 1.5)
			# Auflade-Glimmen: Prismatic-Pulsieren
			_charge_pulse += delta * 16.0
			var pulse_val: float = 1.0 + sin(_charge_pulse) * 0.35
			_sprite.modulate = Color(0.8, 1.2 * pulse_val, 1.5 * pulse_val)
	else:
		if _is_charged:
			_sprite.modulate = Color(1.0, 1.0, 1.0)
			_is_charged = false
			_attack_button_held_time = 0.0
			start_spin_attack()
			return
		elif _attack_button_held_time > 0.0:
			_sprite.modulate = Color(1.0, 1.0, 1.0)
			_attack_button_held_time = 0.0
			start_attack()
			return

	if Input.is_action_just_pressed("roll"):
		start_roll()
	elif Input.is_action_pressed("shield"):
		start_block()
	elif Input.is_action_just_pressed("gadget_1"):
		use_gadget(1)
	elif Input.is_action_just_pressed("gadget_2"):
		use_gadget(2)


const BOOMERANG_SCENE: PackedScene = preload("res://scenes/objects/prismatic_boomerang.tscn")
const TETHER_SCENE: PackedScene = preload("res://scenes/objects/kinetic_tether.tscn")
var active_boomerang: PrismaticBoomerang = null
var active_tether: KineticTether = null
var _tether_target_pos: Vector2 = Vector2.ZERO


func use_gadget(slot: int) -> void:
	var gadget_id: String = ""
	if get_parent() is Game:
		var g: Game = get_parent() as Game
		gadget_id = g.inventory.slot_1_gadget if slot == 1 else g.inventory.slot_2_gadget
	elif get_parent().has_node("HUD"):
		gadget_id = "tether" if slot == 2 else "boomerang"
	else:
		gadget_id = "tether" if slot == 2 else "boomerang"

	if gadget_id == "boomerang":
		throw_boomerang()
	elif gadget_id == "tether":
		fire_tether()


func throw_boomerang() -> void:
	if active_boomerang != null and is_instance_valid(active_boomerang):
		return
	active_boomerang = BOOMERANG_SCENE.instantiate()
	get_parent().add_child(active_boomerang)
	active_boomerang.launch(self, facing_direction)
	var lunge := facing_direction * 12.0
	var tween := create_tween()
	tween.tween_property(_visuals, "position", Vector2(lunge.x, -52.0 + lunge.y), 0.08)
	tween.tween_property(_visuals, "position", Vector2(0, -52.0), 0.12)


func fire_tether() -> void:
	if active_tether != null and is_instance_valid(active_tether):
		return
	active_tether = TETHER_SCENE.instantiate()
	get_parent().add_child(active_tether)
	active_tether.launch(self, facing_direction)
	var lunge := facing_direction * 10.0
	var tween := create_tween()
	tween.tween_property(_visuals, "position", Vector2(lunge.x, -52.0 + lunge.y), 0.08)
	tween.tween_property(_visuals, "position", Vector2(0, -52.0), 0.12)


func pull_to_target(target_pos: Vector2, tether: KineticTether) -> void:
	_tether_target_pos = target_pos
	active_tether = tether
	current_state = State.PULL_TETHER
	is_invulnerable = true
	var t := create_tween()
	t.tween_property(self, "is_invulnerable", false, 0.4)


func _process_tether_pull(delta: float) -> void:
	var to_target := _tether_target_pos - global_position
	var dist := to_target.length()
	var step := 700.0 * delta
	if dist <= 48.0 or step >= dist:
		global_position = _tether_target_pos - to_target.normalized() * 36.0
		current_state = State.IDLE
		if active_tether and is_instance_valid(active_tether):
			active_tether.on_player_pull_finished()
	else:
		global_position += to_target.normalized() * step


func start_attack() -> void:
	current_state = State.ATTACK
	_state_timer = ATTACK_DURATION
	velocity = Vector2.ZERO
	_update_texture()

	# 3-Stufen Kombo-Logik
	combo_step = (combo_step % 3) + 1
	combo_timer = COMBO_WINDOW

	if _sword_hitbox:
		_sword_hitbox.monitoring = true

	attacked.emit()

	var lunge_dist: float = 22.0
	var sfx_pitch: float = 1.0
	var arc_rotation: float = facing_direction.angle()

	match combo_step:
		1:
			lunge_dist = 22.0
			sfx_pitch = 1.05
			_show_slash_arc(arc_rotation, false, 1.0)
		2:
			lunge_dist = 28.0
			sfx_pitch = 1.25
			_show_slash_arc(arc_rotation, true, 1.1)
		3:
			lunge_dist = 40.0
			sfx_pitch = 0.82
			_show_slash_arc(arc_rotation, false, 1.35)
			camera_shake_requested.emit(0.2)
			combo_step = 0 # Finisher schließt die Kombo ab

	AudioManager.play_sfx("slash", sfx_pitch)

	# Kraftvoller Ausfallschritt nach vorne beim Schlagen
	var attack_lunge := facing_direction * lunge_dist
	var tween := create_tween()
	tween.tween_property(_visuals, "position", Vector2(attack_lunge.x, -52.0 + attack_lunge.y), 0.07)
	tween.parallel().tween_property(_sprite, "scale", Vector2(0.52, 0.44), 0.07)
	tween.tween_property(_visuals, "position", Vector2(0, -52.0), 0.12)
	tween.parallel().tween_property(_sprite, "scale", Vector2(0.46, 0.46), 0.12)


func start_spin_attack() -> void:
	current_state = State.SPIN_ATTACK
	_state_timer = SPIN_DURATION
	velocity = Vector2.ZERO
	_update_texture()

	if _spin_hitbox:
		_spin_hitbox.monitoring = true

	attacked.emit()
	AudioManager.play_sfx("slash", 0.72)
	AudioManager.play_sfx("dash", 1.2)
	camera_shake_requested.emit(0.35)

	# Radialer Rundumschlag-Effekt
	_show_spin_arc()

	# 360-Grad Wirbelwind-Drehung
	var tween := create_tween()
	tween.tween_property(_visuals, "rotation", TAU, SPIN_DURATION)
	tween.parallel().tween_property(_sprite, "scale", Vector2(0.55, 0.55), SPIN_DURATION * 0.5)
	tween.tween_property(_sprite, "scale", Vector2(0.46, 0.46), SPIN_DURATION * 0.5)


func _show_slash_arc(rot: float, flip_v: bool, scale_mul: float) -> void:
	if not _slash_arc:
		return
	_slash_arc.visible = true
	_slash_arc.rotation = rot
	_slash_arc.flip_v = flip_v
	_slash_arc.position = facing_direction * 28.0 + Vector2(0, -32.0)
	_slash_arc.scale = Vector2(0.18, 0.18) * scale_mul
	_slash_arc.modulate = Color(1.3, 1.4, 1.8, 0.95)

	var tween := create_tween()
	tween.tween_property(_slash_arc, "scale", Vector2(0.24, 0.24) * scale_mul, 0.12)
	tween.parallel().tween_property(_slash_arc, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func() -> void: _slash_arc.visible = false)


func _show_spin_arc() -> void:
	if not _slash_arc:
		return
	_slash_arc.visible = true
	_slash_arc.position = Vector2(0, -36.0)
	_slash_arc.scale = Vector2(0.28, 0.28)
	_slash_arc.modulate = Color(1.5, 1.6, 2.0, 1.0)

	var tween := create_tween()
	tween.tween_property(_slash_arc, "rotation", TAU * 1.5, SPIN_DURATION)
	tween.parallel().tween_property(_slash_arc, "scale", Vector2(0.34, 0.34), SPIN_DURATION)
	tween.parallel().tween_property(_slash_arc, "modulate:a", 0.0, SPIN_DURATION)
	tween.tween_callback(func() -> void: _slash_arc.visible = false)


func _process_attack(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		if _sword_hitbox:
			_sword_hitbox.monitoring = false
		current_state = State.IDLE
		_update_texture()


func _process_spin_attack(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		if _spin_hitbox:
			_spin_hitbox.monitoring = false
		_visuals.rotation = 0.0
		current_state = State.IDLE
		_update_texture()


func start_roll() -> void:
	current_state = State.ROLL
	_state_timer = ROLL_DURATION
	_roll_direction = facing_direction if velocity.length_squared() < 0.01 else velocity.normalized()
	velocity = _roll_direction * ROLL_SPEED
	is_invulnerable = true
	rolled.emit()
	AudioManager.play_sfx("dash", 1.0)

	# Ausweichrolle: 360-Grad-Drehung und Verkleinern mit Aufprallfederung
	var roll_sign: float = -1.0 if _roll_direction.x < 0 else 1.0
	var tween := create_tween()
	tween.tween_property(_visuals, "rotation", roll_sign * TAU, ROLL_DURATION)
	tween.parallel().tween_property(_sprite, "scale", Vector2(0.34, 0.34), ROLL_DURATION * 0.5)
	tween.tween_property(_sprite, "scale", Vector2(0.46, 0.46), ROLL_DURATION * 0.5)


func _process_roll(delta: float) -> void:
	_state_timer -= delta
	move_and_slide()
	if _state_timer <= 0.0:
		is_invulnerable = false
		current_state = State.IDLE
		_visuals.rotation = 0.0
		_update_texture()


func start_block() -> void:
	current_state = State.BLOCK
	block_hold_time = 0.0
	velocity = Vector2.ZERO
	_visuals.position.y = -46.0 # Schildhaltung: tiefere kompakte Silhouette


func _process_block(delta: float) -> void:
	block_hold_time += delta
	if not autoplay and not Input.is_action_pressed("shield"):
		current_state = State.IDLE
		_visuals.position.y = -52.0
		return
	if autoplay and block_hold_time > 0.35:
		current_state = State.IDLE
		_visuals.position.y = -52.0


func take_hit(incoming_damage: int, attacker_pos: Vector2) -> Dictionary:
	if is_invulnerable:
		return {"absorbed": true, "damage": 0, "parried": false}

	var is_blocking: bool = (current_state == State.BLOCK)
	var resolution: Dictionary = CombatCalculator.resolve_defense(incoming_damage, is_blocking, block_hold_time)

	if resolution["parried"]:
		defended.emit(true)
		AudioManager.play_sfx("parry", 1.1)
		camera_shake_requested.emit(0.35)
		_flash_sprite(Color(2.0, 2.0, 2.0)) # Weißer Blitz bei Parade
		EventBus.player_healed.emit(1, 12)
		return resolution

	if resolution["blocked"]:
		defended.emit(false)
		AudioManager.play_sfx("hit", 1.3) # Gedämpfter Schildtreffer
		camera_shake_requested.emit(0.15)
		velocity = CombatCalculator.calculate_knockback(attacker_pos, global_position, 180.0)
		move_and_slide()
		return resolution

	# Ungeblockter Treffer
	AudioManager.play_sfx("hit", 0.9)
	camera_shake_requested.emit(0.3)
	_flash_sprite(Color(1.8, 0.4, 0.4)) # Roter Trefferblitz
	_start_invulnerability(0.65)
	velocity = CombatCalculator.calculate_knockback(attacker_pos, global_position, 340.0)
	move_and_slide()
	return resolution


func _flash_sprite(color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", color, 0.05)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)


func _start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	var tween := create_tween()
	# Flimmern während der Unverwundbarkeit
	for i in range(5):
		tween.tween_property(_sprite, "modulate:a", 0.35, duration / 10.0)
		tween.tween_property(_sprite, "modulate:a", 1.0, duration / 10.0)
	tween.tween_callback(func() -> void: is_invulnerable = false)
