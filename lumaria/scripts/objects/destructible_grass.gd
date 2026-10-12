class_name DestructibleGrass
extends Area2D
## Zerschneidbares Grasbüschel in Lumaria.
## Zerschneidbar mit der Prisma-Klinge oder dem Rundumschlag.
## Droppt mit Chance Lumen-Kristalle oder Vitalitäts-Splitter.

const CRYSTAL_SCENE: PackedScene = preload("res://scenes/objects/lumen_crystal.tscn")
const VITALITY_SCENE: PackedScene = preload("res://scenes/objects/vitality_shard.tscn")

var _cut: bool = false
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if _cut:
		return
	if area.name == "SwordHitbox" or area.name == "SpinHitbox" or area.collision_layer & 4 != 0:
		call_deferred("cut_grass")


func cut_grass() -> void:
	if _cut:
		return
	_cut = true
	$CollisionShape2D.set_deferred("disabled", true)
	AudioManager.play_sfx("slash", 1.25 + randf() * 0.2) # Saftiger Schnitt-Sound

	# Drop-Chance: 45% Kristall, 15% Heilung, 40% nichts
	var roll := randf()
	if roll < 0.45:
		var crystal: Node2D = CRYSTAL_SCENE.instantiate()
		crystal.global_position = global_position
		get_parent().add_child(crystal)
	elif roll < 0.60:
		var shard: Node2D = VITALITY_SCENE.instantiate()
		shard.global_position = global_position
		get_parent().add_child(shard)

	# Schnitt-Animation (Blätter wirbeln zur Seite und schrumpfen)
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(_sprite.scale.x * 1.3, _sprite.scale.y * 0.2), 0.08)
	tween.parallel().tween_property(_sprite, "modulate", Color(1.3, 1.8, 1.0, 0.0), 0.12)
	tween.tween_callback(queue_free)
