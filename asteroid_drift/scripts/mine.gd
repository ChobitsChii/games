class_name Mine
extends Area2D
## Verfolgende Weltraum-Mine mit Annäherungszünder.

signal detonated(mine: Mine, pos: Vector2, radius: float, score: int)

var speed := Constants.MINE_SPEED
var hp := Constants.MINE_HP
var score_value := Constants.MINE_SCORE
var trigger_dist := Constants.MINE_TRIGGER_DIST
var target_player: Node2D = null

var _is_arming := false
var _arm_timer := 0.0

@onready var poly: Polygon2D = $Polygon2D
@onready var outline: Line2D = $Line2D


func _ready() -> void:
	collision_layer = 1 << 3 # layer 4: enemies
	collision_mask = (1 << 0) | (1 << 2) # layer 1: player, layer 3: player_bullets
	area_entered.connect(_on_area_entered)

	var tween := create_tween().set_loops()
	tween.tween_property(poly, "color", Color(1.0, 0.4, 0.1, 1.0), 0.4)
	tween.tween_property(poly, "color", Color(0.9, 0.1, 0.2, 1.0), 0.4)


func _physics_process(delta: float) -> void:
	if is_instance_valid(target_player):
		var dir := (target_player.global_position - global_position).normalized()
		global_position += dir * speed * delta
		var dist := global_position.distance_to(target_player.global_position)
		if dist <= trigger_dist and not _is_arming:
			_start_detonation()

	global_position = ScreenWrap.wrap_position(global_position, Constants.VIEWPORT_RECT)
	rotation += 2.0 * delta

	if _is_arming:
		_arm_timer += delta
		if _arm_timer >= 0.8:
			explode()


func _start_detonation() -> void:
	_is_arming = true
	var flash := create_tween().set_loops(4)
	flash.tween_property(poly, "scale", Vector2(1.3, 1.3), 0.1)
	flash.tween_property(poly, "scale", Vector2(1.0, 1.0), 0.1)


func take_hit(damage: int) -> void:
	hp -= damage
	if hp <= 0:
		explode()


func explode() -> void:
	detonated.emit(self, global_position, trigger_dist * 1.2, score_value)
	queue_free()


func _on_area_entered(other: Area2D) -> void:
	if other is Bullet and not other.is_enemy:
		take_hit(1)
		other.destroy()
