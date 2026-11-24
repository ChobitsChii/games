class_name EnemySummoner
extends BaseEnemy
## Beschwörer / Nekromant: Ruft regelmäßig kleine Skelette herbei.

var summon_timer: float = 3.5
var summon_cooldown: float = 4.0
var _aura_light: PointLight2D


func _init() -> void:
	max_health = 6
	move_speed = 90.0
	souls_value = 3
	contact_damage = 1


func _ready() -> void:
	super._ready()
	_aura_light = PointLight2D.new()
	_aura_light.texture = CryptAssets.get_radial_light_texture()
	_aura_light.color = Color("a855f7")
	_aura_light.energy = 0.72
	_aura_light.texture_scale = 1.15
	add_child(_aura_light)


func get_sprite_path() -> String:
	return "res://assets/sprites/enemy_summoner.png"


func get_sprite_size() -> float:
	return 68.0


func get_death_color() -> Color:
	return Color("c084fc")


func _update_ai(delta: float) -> void:
	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)
	var dir := (player.global_position - global_position).normalized()

	if dist < 400.0:
		velocity = -dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	summon_timer -= delta
	if summon_timer <= 0.65:
		queue_redraw()
	if summon_timer <= 0.0:
		summon_timer = summon_cooldown
		_summon()


func _summon() -> void:
	CryptVfx.spawn_burst(get_parent(), global_position, Color("c084fc"), 10, 150.0, 3.8)
	var skel := EnemySkeleton.new()
	skel.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	get_parent().call_deferred("add_child", skel)


func _draw() -> void:
	if summon_timer <= 0.65 and summon_timer > 0.0:
		var t := 1.0 - (summon_timer / 0.65)
		draw_arc(Vector2.ZERO, 24.0 + t * 14.0, 0.0, TAU, 24, Color(0.75, 0.45, 1.0, 0.65 * (1.0 - t * 0.4)), 2.5)
