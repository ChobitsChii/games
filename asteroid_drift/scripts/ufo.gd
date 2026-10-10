class_name UFO
extends Area2D
## Feindliches UFO (Groß oder Klein) mit Schusslogik.

signal destroyed(ufo: UFO, score: int)
signal shoot_bullet(pos: Vector2, vel: Vector2)

@export var is_small: bool = false

var hp := 1
var score_value := 200
var speed := 130.0
var fire_interval := 2.5
var _fire_timer := 0.0
var target_player: Node2D = null
var move_direction := Vector2.RIGHT

@onready var poly_body: Polygon2D = $BodyPoly
@onready var poly_dome: Polygon2D = $DomePoly
@onready var outline: Line2D = $Line2D


func _ready() -> void:
	collision_layer = 1 << 3 # layer 4: enemies
	collision_mask = (1 << 0) | (1 << 2) # layer 1: player, layer 3: player_bullets

	area_entered.connect(_on_area_entered)
	_setup_stats()


func setup_ufo(small: bool, start_pos: Vector2, dir: Vector2) -> void:
	is_small = small
	global_position = start_pos
	move_direction = dir.normalized()
	_setup_stats()


func _setup_stats() -> void:
	if is_small:
		hp = Constants.UFO_SMALL_HP
		score_value = Constants.UFO_SMALL_SCORE
		speed = Constants.UFO_SMALL_SPEED
		fire_interval = Constants.UFO_SMALL_FIRE_INTERVAL
		scale = Vector2(0.65, 0.65)
	else:
		hp = Constants.UFO_LARGE_HP
		score_value = Constants.UFO_LARGE_SCORE
		speed = Constants.UFO_LARGE_SPEED
		fire_interval = Constants.UFO_LARGE_FIRE_INTERVAL
		scale = Vector2(1.0, 1.0)


func _physics_process(delta: float) -> void:
	global_position += move_direction * speed * delta
	global_position = ScreenWrap.wrap_position(global_position, Constants.VIEWPORT_RECT)

	_fire_timer += delta
	if _fire_timer >= fire_interval:
		_fire_timer = 0.0
		_fire()


func _fire() -> void:
	var bullet_vel := Vector2.ZERO
	var bullet_speed := 450.0

	if is_small and is_instance_valid(target_player):
		# Zielt auf den Spieler
		var dir := (target_player.global_position - global_position).normalized()
		bullet_vel = dir * bullet_speed
	else:
		# Zielt zufällig
		var angle := randf_range(0.0, TAU)
		bullet_vel = Vector2.RIGHT.rotated(angle) * bullet_speed

	shoot_bullet.emit(global_position, bullet_vel)


func take_hit(damage: int) -> void:
	hp -= damage
	var orig_color := outline.default_color
	outline.default_color = Color(1.0, 1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(outline, "default_color", orig_color, 0.1)

	if hp <= 0:
		destroyed.emit(self, score_value)
		queue_free()


func _on_area_entered(other: Area2D) -> void:
	if other is Bullet and not other.is_enemy:
		take_hit(1)
		other.destroy()
