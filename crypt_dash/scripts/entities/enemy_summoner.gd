class_name EnemySummoner
extends BaseEnemy
## Beschwörer / Nekromant: Ruft regelmäßig kleine Skelette herbei.

var summon_timer: float = 3.5
var summon_cooldown: float = 4.0


func _init() -> void:
	max_health = 6
	move_speed = 90.0
	souls_value = 3
	contact_damage = 1


func _update_ai(delta: float) -> void:
	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)
	var dir := (player.global_position - global_position).normalized()

	# Hält großen Abstand
	if dist < 400.0:
		velocity = -dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	summon_timer -= delta
	if summon_timer <= 0.0:
		summon_timer = summon_cooldown
		_summon()


func _summon() -> void:
	var skel := EnemySkeleton.new()
	skel.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	get_parent().call_deferred("add_child", skel)


func _draw() -> void:
	super._draw()
	# Dunkelviolette Magierrobe
	draw_circle(Vector2.ZERO, 18.0, Color("6b21a8"))
	draw_circle(Vector2.ZERO, 12.0, Color("a855f7"))
	draw_circle(Vector2(0, 0), 6.0, Color("facc15")) # Magisches Amulett
