class_name CrackedWall
extends StaticBody2D
## Brüchige Felswand, die mit einer Schall-Bombe aufgesprengt werden kann.
## Öffnet Geheimgänge und Abkürzungen auf der Oberwelt und in Dungeons.

signal shattered()

@export var wall_id: String = "cracked_wall_1"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_shattered: bool = false


func _ready() -> void:
	add_to_group("cracked_walls")


func shatter() -> void:
	if is_shattered:
		return
	is_shattered = true
	shattered.emit()

	AudioManager.play_sfx("break", 1.2)

	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	if sprite:
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.2, 0.1), 0.15)
		tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)
	else:
		queue_free()
