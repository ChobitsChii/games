class_name LaserShot
extends Node2D
## Ein Laser-Schuss. Fliegt senkrecht nach oben und trifft den ersten Block auf dem Weg.
## Die Prüfung läuft über einen Strahl zwischen alter und neuer Position, damit auch
## bei hohem Tempo nichts übersprungen wird.

const SPEED := 1500.0
const BRICK_MASK := 8

var top_y := 0.0


func _physics_process(delta: float) -> void:
	var from := global_position
	var to := from + Vector2(0.0, -SPEED * delta)
	var query := PhysicsRayQueryParameters2D.create(from, to, BRICK_MASK)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var brick := hit["collider"] as Brick
		global_position = hit["position"]
		if brick != null:
			brick.hit()
		Burst.spawn(get_parent(), global_position, PowerUps.COLORS[PowerUps.Kind.LASER], FxSettings.scaled(8), 260.0, 0.3, Vector2.UP, 160.0, 0.7)
		queue_free()
		return
	global_position = to
	if to.y < top_y:
		queue_free()


func _draw() -> void:
	var laser: Color = PowerUps.COLORS[PowerUps.Kind.LASER]
	draw_line(Vector2(0, 0), Vector2(0, 46), Color(laser, 0.25), 14.0, true)
	draw_line(Vector2(0, 0), Vector2(0, 40), Color(laser.r * 1.6, laser.g * 1.6, laser.b * 1.6, 1.0), 5.0, true)
