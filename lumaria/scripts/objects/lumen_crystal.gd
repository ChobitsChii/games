class_name LumenCrystal
extends Area2D
## Sammelbarer Lumen-Kristall in Lumaria.

@export var value: int = 1
var _collected: bool = false
var _phase: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_phase += delta * 4.0
	_sprite.position.y = sin(_phase) * 3.0


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player):
		return
	_collected = true
	AudioManager.play_sfx("lumen_collect", 1.0 + randf() * 0.15)
	EventBus.lumen_collected.emit(value)

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 32.0, 0.25)
	tween.parallel().tween_property(self, "scale", Vector2(1.4, 1.4), 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
