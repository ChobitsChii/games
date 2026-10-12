class_name RootSpike
extends Area2D
## Bodenbrechende Dornen-Ranke von Boss Floragorg.
## Telegrafiert die Stelle auf dem Boden, bevor sie emporbricht.

@export var damage: int = 20

var _is_erupted: bool = false
var _timer: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shadow: ColorRect = $Shadow
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitoring = false
	_sprite.visible = false
	_shadow.color = Color(1.8, 0.3, 0.3, 0.45) # Rotes Gefahren-Vorfeld
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_timer += delta

	if not _is_erupted:
		# Warnphase: 0.65 Sekunden
		_shadow.scale = Vector2.ONE * (1.0 + sin(_timer * 18.0) * 0.15)
		if _timer >= 0.65:
			_erupt()
	else:
		if _timer >= 1.4:
			# Zurückziehen
			var tween := create_tween()
			tween.tween_property(_sprite, "scale:y", 0.0, 0.15)
			tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.15)
			tween.tween_callback(queue_free)


func _erupt() -> void:
	_is_erupted = true
	_sprite.visible = true
	_sprite.scale = Vector2(0.4, 0.0)
	monitoring = true
	AudioManager.play_sfx("break", 1.2)

	var tween := create_tween()
	tween.tween_property(_sprite, "scale:y", 0.42, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "scale:y", 0.38, 0.08)


func _on_body_entered(body: Node2D) -> void:
	if _is_erupted and body is Player:
		body.take_hit(damage, global_position)
