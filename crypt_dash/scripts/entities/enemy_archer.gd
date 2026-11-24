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


func get_sprite_path() -> String:
	return "res://assets/sprites/enemy_archer.png"


func get_sprite_size() -> float:
	return 70.0


func get_death_color() -> Color:
	return Color("34d399")


func _update_ai(delta: float) -> void:
	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)
	var dir := (player.global_position - global_position).normalized()

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
	p.global_position = global_position + dir * 22.0
	p.direction = dir
	p.damage = 1
	p.is_player = false
	p.speed = 420.0
	p.visual_style = "enemy_arrow"
	p.tint = Color("f97316")
	get_parent().add_child(p)
