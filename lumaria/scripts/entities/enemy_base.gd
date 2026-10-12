class_name EnemyBase
extends CharacterBody2D
## Basisklasse für alle Gegner in Lumaria.
## Verwaltet Lebenspunkte, Treffer-Reaktion, Taumeln, Betäubung (Stun)
## durch den Prisma-Bumerang und Belohnungs-Drops.

signal died()
signal damaged(amount: int)

@export var max_health: int = 40
@export var speed: float = 140.0
@export var contact_damage: int = 1
@export var knockback_resistance: float = 0.0

var current_health: int = 40
var is_stunned: bool = false
var stun_timer: float = 0.0
var is_invulnerable: bool = false
var invuln_timer: float = 0.0
var facing_direction: Vector2 = Vector2.DOWN

const CRYSTAL_SCENE: PackedScene = preload("res://scenes/objects/lumen_crystal.tscn")

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	current_health = max_health
	if _hurtbox:
		_hurtbox.area_entered.connect(_on_hurtbox_area_entered)


func _physics_process(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta
		if invuln_timer <= 0.0:
			is_invulnerable = false

	if is_stunned:
		stun_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, delta * 500.0)
		move_and_slide()
		if stun_timer <= 0.0:
			is_stunned = false
			_sprite.modulate = Color.WHITE
		return

	# Subklassen überschreiben das Verhalten in _process_ai(delta)
	_process_ai(delta)


func _process_ai(_delta: float) -> void:
	pass


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_invulnerable:
		return
	if area.name == "SwordHitbox":
		var p: Node2D = area.get_parent()
		var dmg: int = CombatCalculator.calculate_sword_damage(1)
		take_hit(dmg, p.global_position, 340.0)
	elif area.name == "SpinHitbox":
		var p: Node2D = area.get_parent()
		var dmg: int = CombatCalculator.calculate_sword_damage(1, true)
		take_hit(dmg, p.global_position, 480.0)


func take_hit(damage: int, attacker_pos: Vector2, force: float = 340.0) -> void:
	if is_invulnerable or current_health <= 0:
		return

	current_health -= damage
	damaged.emit(damage)
	AudioManager.play_sfx("hit", 1.05 + randf() * 0.1)

	# Rückstoß
	velocity = CombatCalculator.calculate_knockback(attacker_pos, global_position, force, knockback_resistance)

	# Trefferblitz & Unverwundbarkeit
	is_invulnerable = true
	invuln_timer = 0.22
	if _sprite != null:
		var tween := create_tween()
		if tween:
			tween.tween_property(_sprite, "modulate", Color(2.5, 0.5, 0.5), 0.06)
			tween.tween_property(_sprite, "modulate", Color.WHITE, 0.14)

	if current_health <= 0:
		die()


func apply_stun(duration: float) -> void:
	is_stunned = true
	stun_timer = duration
	if _sprite != null:
		_sprite.modulate = Color(1.3, 1.3, 0.4) # Gelber Stun-Farbton


func die() -> void:
	died.emit()
	AudioManager.play_sfx("break", 1.3)

	# 65% Chance auf Lumen-Kristall Drop
	if randf() < 0.65 and get_parent() != null:
		var crystal: Node2D = CRYSTAL_SCENE.instantiate()
		crystal.global_position = global_position
		get_parent().call_deferred("add_child", crystal)

	# Zerfall-Animation
	if _sprite != null:
		var tween := create_tween()
		if tween:
			tween.tween_property(_sprite, "scale", Vector2(_sprite.scale.x * 1.3, 0.0), 0.15)
			tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.15)
			tween.tween_callback(queue_free)
			return
	queue_free()
