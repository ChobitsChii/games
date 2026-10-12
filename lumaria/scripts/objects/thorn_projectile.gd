class_name ThornProjectile
extends Area2D
## Gift-Dornen-Projektil des Dornen-Spuckers in Lumaria.
## Kann durch perfektes Schild-Parry zurückgeworfen werden,
## um den Angreifer selbst zu vernichten!

const SPEED := 320.0

var direction: Vector2 = Vector2.DOWN
var is_reflected: bool = false
var lifetime: float = 4.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func launch(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle() + PI / 2.0


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	global_position += direction * (SPEED * delta)


func _on_body_entered(body: Node2D) -> void:
	if not is_reflected and body is Player:
		var res: Dictionary = body.take_hit(15, global_position)
		if res.get("parried", false):
			reflect()
		else:
			queue_free()
	elif is_reflected and body is EnemyBase:
		body.take_hit(35, global_position)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Reflektieren durch Schwerthieb oder Wirbelattacke
	if not is_reflected and (area.name == "SwordHitbox" or area.name == "SpinHitbox"):
		reflect()


func reflect() -> void:
	is_reflected = true
	direction = -direction
	rotation = direction.angle() + PI / 2.0
	AudioManager.play_sfx("parry", 1.3)
	if _sprite != null:
		_sprite.modulate = Color(1.8, 1.8, 2.5) # Leuchtet blau/weiß reflektiert
