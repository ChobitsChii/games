class_name PrismArrow
extends Area2D
## Fliegender Prisma-Pfeil des Prisma-Bogens in Lumaria.
## Aktiviert Kristallschalter auf Distanz, mäht hohes Gras, zerbricht Krüge und verletzt Gegner.

const SPEED := 680.0
const MAX_DISTANCE := 560.0
const DAMAGE := 25

var thrower: Node2D = null
var direction: Vector2 = Vector2.RIGHT
var _traveled: float = 0.0
var _hit: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func launch(from_node: Node2D, dir: Vector2) -> void:
	thrower = from_node
	direction = dir.normalized() if dir.length_squared() > 0.0 else Vector2.DOWN
	global_position = from_node.global_position + direction * 28.0
	rotation = direction.angle()
	_traveled = 0.0
	_hit = false
	queue_redraw()


func _draw() -> void:
	# Kristallener Leuchtpfeil (hochauflösende Vektorgrafik, kein Pixel-Art)
	draw_line(Vector2(-22.0, 0.0), Vector2(14.0, 0.0), Color(0.22, 0.85, 1.0, 0.42), 8.0, true)
	draw_line(Vector2(-20.0, 0.0), Vector2(14.0, 0.0), Color(0.92, 0.99, 1.0, 1.0), 3.0, true)
	var head := PackedVector2Array([
		Vector2(22.0, 0.0),
		Vector2(8.0, -7.5),
		Vector2(11.5, 0.0),
		Vector2(8.0, 7.5),
	])
	draw_colored_polygon(head, Color(0.35, 0.94, 1.0, 1.0))
	draw_line(Vector2(-20.0, 0.0), Vector2(-26.0, -5.5), Color(0.98, 0.78, 0.28, 0.9), 2.2, true)
	draw_line(Vector2(-20.0, 0.0), Vector2(-26.0, 5.5), Color(0.98, 0.78, 0.28, 0.9), 2.2, true)


func _physics_process(delta: float) -> void:
	if _hit:
		return
	var step := SPEED * delta
	global_position += direction * step
	_traveled += step
	if _traveled >= MAX_DISTANCE:
		_hit = true
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _hit:
		return
	if area is SwitchCrystal:
		area.hit_switch()
		_hit = true
		queue_free()
		return
	if area is DestructibleGrass:
		area.call_deferred("cut_grass")
		return
	if area.name == "Hurtbox" and area.get_parent() is EnemyBase:
		(area.get_parent() as EnemyBase).take_hit(DAMAGE, global_position, 220.0)
		_hit = true
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _hit or body == thrower:
		return
	if body is EnemyBase:
		(body as EnemyBase).take_hit(DAMAGE, global_position, 220.0)
		_hit = true
		queue_free()
		return
	if body is DestructiblePot:
		body.call_deferred("break_pot")
		_hit = true
		queue_free()
		return
	if body is StaticBody2D or body is TileMap or body is TileMapLayer:
		_hit = true
		queue_free()
