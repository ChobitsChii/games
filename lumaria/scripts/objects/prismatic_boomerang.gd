class_name PrismaticBoomerang
extends Area2D
## Fliegender Prisma-Bumerang in Lumaria.
## Fliegt nach vorne, bremst ab, kehrt zum Spieler zurück,
## betäubt Gegner, mäht Gras/Krüge und trägt gefundene Kristalle zum Spieler zurück.

signal caught()

const MAX_DISTANCE := 360.0
const INITIAL_SPEED := 540.0
const RETURN_ACCEL := 920.0

var thrower: Node2D = null
var direction: Vector2 = Vector2.DOWN
var current_speed: float = INITIAL_SPEED
var distance_traveled: float = 0.0
var is_returning: bool = false
var grabbed_items: Array[Node2D] = []

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func launch(from_node: Node2D, dir: Vector2) -> void:
	thrower = from_node
	direction = dir.normalized()
	global_position = from_node.global_position + direction * 24.0
	current_speed = INITIAL_SPEED
	distance_traveled = 0.0
	is_returning = false
	AudioManager.play_sfx("slash", 1.35)


func _physics_process(delta: float) -> void:
	# Schnelle Rotation
	_sprite.rotation += delta * 26.0

	if not is_returning:
		# Hinflug: Bremsen mit steigender Distanz
		var move_step: float = current_speed * delta
		global_position += direction * move_step
		distance_traveled += move_step
		current_speed = maxf(current_speed - delta * 600.0, 80.0)

		if distance_traveled >= MAX_DISTANCE or current_speed <= 100.0:
			is_returning = true
			AudioManager.play_sfx("dash", 1.4)
	else:
		# Rückflug: Beschleunigen zur aktuellen Spielerposition
		if thrower != null and is_instance_valid(thrower):
			var to_player := thrower.global_position - global_position
			var dist := to_player.length()

			if dist < 32.0:
				# Gefangen!
				_on_caught()
				return

			var return_dir := to_player.normalized()
			current_speed = minf(current_speed + RETURN_ACCEL * delta, 680.0)
			global_position += return_dir * (current_speed * delta)
		else:
			queue_free()

	# Mitgeführte Items mitbewegen
	for item in grabbed_items:
		if is_instance_valid(item):
			item.global_position = global_position


func _on_caught() -> void:
	AudioManager.play_sfx("parry", 1.5)
	caught.emit()
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Zerstörbares Gras
	if area is DestructibleGrass:
		area.call_deferred("cut_grass")
		return

	# Kristalle oder Vitalitäts-Splitter aufsammeln und mitnehmen
	if area is LumenCrystal or area is VitalityShard:
		if not grabbed_items.has(area):
			grabbed_items.append(area)
		return


func _on_body_entered(body: Node2D) -> void:
	# Fänger
	if is_returning and body == thrower:
		_on_caught()
		return

	# Zerstörbarer Krug
	if body is DestructiblePot:
		body.call_deferred("break_pot")
		return

	# Gegner treffen: Betäuben und Schaden
	if body is EnemyBase:
		body.take_hit(15, global_position, 180.0)
		body.apply_stun(2.5)
		is_returning = true # Nach Treffer umkehren
