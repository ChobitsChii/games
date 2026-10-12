class_name Player
extends CharacterBody2D
## Hauptfigur von Lumaria: Kaelen / Lyra.
## Unterstützt 8-Wege-Bewegung, 4 Blickrichtungen, Schwertkampf, Ausweichrolle,
## Schild-Block & Parry sowie Autopilot für Tests.

signal attacked()
signal rolled()
signal defended(is_parry: bool)

enum State { IDLE, WALK, ATTACK, ROLL, BLOCK }

const SPEED := 240.0
const ROLL_SPEED := 520.0
const ROLL_DURATION := 0.25
const ATTACK_DURATION := 0.22

var current_state: State = State.IDLE
var facing_direction: Vector2 = Vector2.DOWN
var is_invulnerable: bool = false
var block_hold_time: float = 0.0

var _state_timer: float = 0.0
var _roll_direction: Vector2 = Vector2.DOWN

@export var autoplay: bool = false
var _auto_timer: float = 0.0

@onready var _sword_hitbox: Area2D = $SwordHitbox
@onready var _visuals: Node2D = $Visuals
@onready var _shadow: ColorRect = $Shadow


func _ready() -> void:
	if _sword_hitbox:
		_sword_hitbox.monitoring = false


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE, State.WALK:
			_process_movement(delta)
			_process_combat_inputs()
		State.ROLL:
			_process_roll(delta)
		State.ATTACK:
			_process_attack(delta)
		State.BLOCK:
			_process_block(delta)


func _process_movement(_delta: float) -> void:
	var input_vec := Vector2.ZERO
	if autoplay:
		_auto_timer += _delta
		# Autopilot: läuft zyklisch im Kreis und attackiert periodisch
		var phase: int = int(_auto_timer) % 4
		match phase:
			0: input_vec = Vector2.RIGHT
			1: input_vec = Vector2.DOWN
			2: input_vec = Vector2.LEFT
			3: input_vec = Vector2.UP
		if fmod(_auto_timer, 1.5) < _delta:
			start_attack()
		elif fmod(_auto_timer, 2.3) < _delta:
			start_roll()
	else:
		input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vec.length_squared() > 0.01:
		input_vec = input_vec.normalized()
		velocity = input_vec * SPEED
		current_state = State.WALK
		_update_facing(input_vec)
		
		# Prozeduraler Neigungswinkel in Laufrichtung
		_visuals.rotation = clampf(velocity.x * 0.0003, -0.08, 0.08)
	else:
		velocity = Vector2.ZERO
		current_state = State.IDLE
		_visuals.rotation = 0.0

	move_and_slide()


func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing_direction = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		facing_direction = Vector2.DOWN if dir.y > 0 else Vector2.UP
	
	# Schwert-Hitbox in Blickrichtung ausrichten
	if _sword_hitbox:
		_sword_hitbox.position = facing_direction * 36.0


func _process_combat_inputs() -> void:
	if autoplay:
		return

	if Input.is_action_just_pressed("attack"):
		start_attack()
	elif Input.is_action_just_pressed("roll"):
		start_roll()
	elif Input.is_action_pressed("shield"):
		start_block()


func start_attack() -> void:
	current_state = State.ATTACK
	_state_timer = ATTACK_DURATION
	velocity = Vector2.ZERO
	if _sword_hitbox:
		_sword_hitbox.monitoring = true
	attacked.emit()
	
	# Optischer Angriffsschwung
	var tween := create_tween()
	tween.tween_property(_visuals, "scale", Vector2(1.2, 0.85), 0.08)
	tween.tween_property(_visuals, "scale", Vector2(1.0, 1.0), 0.12)


func _process_attack(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		if _sword_hitbox:
			_sword_hitbox.monitoring = false
		current_state = State.IDLE


func start_roll() -> void:
	current_state = State.ROLL
	_state_timer = ROLL_DURATION
	_roll_direction = facing_direction if velocity.length_squared() < 0.01 else velocity.normalized()
	velocity = _roll_direction * ROLL_SPEED
	is_invulnerable = true
	rolled.emit()
	
	# Visueller Roll-Squash
	var tween := create_tween()
	tween.tween_property(_visuals, "scale", Vector2(0.7, 0.7), 0.1)
	tween.tween_property(_visuals, "scale", Vector2(1.0, 1.0), 0.15)


func _process_roll(delta: float) -> void:
	_state_timer -= delta
	move_and_slide()
	if _state_timer <= 0.0:
		is_invulnerable = false
		current_state = State.IDLE


func start_block() -> void:
	current_state = State.BLOCK
	block_hold_time = 0.0
	velocity = Vector2.ZERO


func _process_block(delta: float) -> void:
	block_hold_time += delta
	if not autoplay and not Input.is_action_pressed("shield"):
		current_state = State.IDLE
		return
	if autoplay and block_hold_time > 0.4:
		current_state = State.IDLE


func take_hit(incoming_damage: int, attacker_pos: Vector2) -> Dictionary:
	if is_invulnerable:
		return {"absorbed": true, "damage": 0, "parried": false}
	
	var is_blocking: bool = (current_state == State.BLOCK)
	var resolution: Dictionary = CombatCalculator.resolve_defense(incoming_damage, is_blocking, block_hold_time)
	
	if resolution["parried"]:
		defended.emit(true)
		EventBus.player_healed.emit(12, 12) # Visuelles Signal
		return resolution
	
	if resolution["blocked"]:
		defended.emit(false)
		velocity = CombatCalculator.calculate_knockback(attacker_pos, global_position, 180.0)
		move_and_slide()
		return resolution
	
	# Nicht geblockter Treffer: Rückstoß & Schaden
	velocity = CombatCalculator.calculate_knockback(attacker_pos, global_position, 320.0)
	move_and_slide()
	return resolution
