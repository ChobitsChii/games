class_name VitalityShard
extends Area2D
## Heilender Vitalitäts-Splitter in Lumaria.
## Stellt beim Aufsammeln Lebensenergie (Vitalitäts-Sphären) wieder her.

@export var quarters_to_heal: int = 4
var _collected: bool = false
var _phase: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_phase += delta * 4.5
	_sprite.position.y = sin(_phase) * 4.0
	_sprite.scale = Vector2(0.18 + sin(_phase * 0.8) * 0.015, 0.18 + sin(_phase * 0.8) * 0.015)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player):
		return
	_collected = true
	AudioManager.play_sfx("parry", 1.4) # Helles magisches Klirren
	EventBus.vitality_collected.emit(quarters_to_heal)

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 40.0, 0.28)
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.28)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.28)
	tween.tween_callback(queue_free)
