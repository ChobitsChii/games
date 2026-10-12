class_name SpikeTrap
extends Area2D
## Bodenfalle mit zeitgesteuert ausfahrenden Stachelklingen.
## Zyklen: Eingefahren (sicher, 1.8s) -> Telegraf-Beben (0.4s) -> Ausgefahren (gefährlich, 1.2s).

signal triggered()

@export var cycle_offset: float = 0.0
@export var damage_quarters: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

enum State { LOWERED, TELEGRAPH, RAISED }

var state: State = State.LOWERED
var _timer: float = 0.0
var _shake_timer: float = 0.0


func _ready() -> void:
	_timer = cycle_offset
	body_entered.connect(_on_body_entered)
	_update_appearance()


func _physics_process(delta: float) -> void:
	_timer += delta

	match state:
		State.LOWERED:
			if _timer >= 1.8:
				state = State.TELEGRAPH
				_timer = 0.0
				_update_appearance()
		State.TELEGRAPH:
			_shake_timer += delta * 30.0
			if sprite:
				sprite.position.x = sin(_shake_timer) * 3.0
			if _timer >= 0.4:
				state = State.RAISED
				_timer = 0.0
				_update_appearance()
				AudioManager.play_sfx("hit", 1.4)
				_check_overlapping_bodies()
		State.RAISED:
			if _timer >= 1.2:
				state = State.LOWERED
				_timer = 0.0
				_update_appearance()


func _update_appearance() -> void:
	if sprite == null:
		return
	sprite.position = Vector2.ZERO
	match state:
		State.LOWERED:
			sprite.modulate = Color(0.65, 0.7, 0.75, 0.5)
			sprite.scale = Vector2(0.75, 0.75)
		State.TELEGRAPH:
			sprite.modulate = Color(1.2, 0.8, 0.5, 0.85)
			sprite.scale = Vector2(0.8, 0.8)
		State.RAISED:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			sprite.scale = Vector2(0.85, 0.85)


func _on_body_entered(body: Node2D) -> void:
	if state == State.RAISED:
		_harm_target(body)


func _check_overlapping_bodies() -> void:
	for body in get_overlapping_bodies():
		_harm_target(body)


func _harm_target(body: Node2D) -> void:
	if body is Player:
		var p: Player = body as Player
		if p.current_state != Player.State.ROLL: # Ausweichrolle / Dash kann Stacheln überwinden!
			p.take_damage(damage_quarters, global_position)
			triggered.emit()
