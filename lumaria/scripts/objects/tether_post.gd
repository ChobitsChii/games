class_name TetherPost
extends StaticBody2D
## Ankerpfahl für das Kinetische Fangseil.
## Erlaubt es Kaelen, sich über Abgründe oder Wasserflächen
## direkt an diesen Pfahl heranzuziehen.

@export var post_id: String = "post_1"

@onready var anchor_area: Area2D = $AnchorArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var glow_ring: Node2D = get_node_or_null("GlowRing")

var _pulse_phase: float = 0.0


func _ready() -> void:
	add_to_group("tether_posts")


func _process(delta: float) -> void:
	_pulse_phase += delta * 3.5
	if glow_ring:
		glow_ring.modulate.a = 0.6 + sin(_pulse_phase) * 0.35


func get_anchor_position() -> Vector2:
	return global_position + Vector2(0, -12)


func highlight_anchor(active: bool) -> void:
	if sprite:
		var target_col := Color(1.3, 1.4, 1.6) if active else Color(1.0, 1.0, 1.0)
		create_tween().tween_property(sprite, "modulate", target_col, 0.15)
