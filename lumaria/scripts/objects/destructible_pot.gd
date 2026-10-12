class_name DestructiblePot
extends StaticBody2D
## Zerstörbarer Tonkrug in Lumaria.
## Zerspringt bei Schwerthieb oder Wurf in Scherben und droppt Lumen-Kristalle.

@export var drops_crystal: bool = true
const CRYSTAL_SCENE: PackedScene = preload("res://scenes/objects/lumen_crystal.tscn")

var _broken: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	_hurtbox.area_entered.connect(_on_hurtbox_area_entered)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if _broken:
		return
	if area.name == "SwordHitbox" or area.name == "SpinHitbox" or area.collision_layer & 4 != 0:
		call_deferred("break_pot")


func break_pot() -> void:
	if _broken:
		return
	_broken = true
	$CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	AudioManager.play_sfx("break", 0.95 + randf() * 0.1)

	# Kristall oder Vitalität spawnen
	if drops_crystal:
		var roll := randf()
		if roll < 0.25:
			var shard_scene: PackedScene = load("res://scenes/objects/vitality_shard.tscn")
			var shard: Node2D = shard_scene.instantiate()
			shard.global_position = global_position
			get_parent().add_child(shard)
		else:
			var crystal: Node2D = CRYSTAL_SCENE.instantiate()
			crystal.global_position = global_position
			get_parent().add_child(crystal)

	# Zerberst-Animation
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.3, 0.4), 0.08)
	tween.parallel().tween_property(_sprite, "modulate", Color(1.4, 1.2, 0.8, 0.0), 0.12)
	tween.tween_callback(queue_free)
