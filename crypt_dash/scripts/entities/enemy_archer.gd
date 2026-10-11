class_name EnemyArcher
extends BaseEnemy
## Bogenschütze: Hält Abstand zum Spieler und schießt Pfeile.

var shoot_cooldown: float = 2.0
var shoot_timer: float = 1.0


func _init() -> void:
	max_health = 3
	move_speed = 140.0
	souls_value = 2
	contact_damage = 1


func _update_ai(delta: float) -> void:
	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)
	var dir := (player.global_position - global_position).normalized()

	# Abstand halten (Kiting)
	if dist < 260.0:
		velocity = -dir * move_speed
		move_and_slide()
	elif dist > 420.0:
		velocity = dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	shoot_timer -= delta
	if shoot_timer <= 0.0 and dist <= 600.0:
		shoot_timer = shoot_cooldown
		_shoot(dir)


func _shoot(dir: Vector2) -> void:
	var p := Projectile.new()
	p.global_position = global_position + dir * 20.0
	p.direction = dir
	p.damage = 1
	p.is_player = false
	p.speed = 420.0
	get_parent().add_child(p)


func _draw() -> void:
	super._draw()
	# Grüner Schützen-Umhang
	draw_circle(Vector2.ZERO, 16.0, Color("15803d"))
	draw_circle(Vector2(0, -2), 11.0, Color("e2e8f0"))
	draw_circle(Vector2(-3, -2), 2.5, Color("dc2626")) # Rote Scharfschützen-Augen
	draw_circle(Vector2(3, -2), 2.5, Color("dc2626"))
