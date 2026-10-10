class_name Drop
extends Area2D
## Schwebender Energie-Kristall / Drop.

signal collected(drop: Drop)

var velocity := Vector2.ZERO
var lifetime := 14.0
var _age := 0.0
var target_player: Node2D = null
var magnet_radius := 0.0

@onready var poly: Polygon2D = $Polygon2D
@onready var outline: Line2D = $Line2D


func _ready() -> void:
	collision_layer = 1 << 5 # layer 6: pickups
	collision_mask = 1 << 0 # layer 1: player
	var tween := create_tween().set_loops()
	tween.tween_property(poly, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(poly, "scale", Vector2(0.9, 0.9), 0.5)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	if is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		if dist <= magnet_radius and dist > 1.0:
			var pull_speed := 450.0
			var dir := (target_player.global_position - global_position).normalized()
			velocity = velocity.move_toward(dir * pull_speed, 1200.0 * delta)

	global_position += velocity * delta
	global_position = ScreenWrap.wrap_position(global_position, Constants.VIEWPORT_RECT)


func collect() -> void:
	collected.emit(self)
	queue_free()
