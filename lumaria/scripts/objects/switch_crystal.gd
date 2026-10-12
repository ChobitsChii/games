class_name SwitchCrystal
extends Area2D
## Magischer Kristall-Schalter in Lumaria.
## Kann durch Schwert, Wirbelattacke und insbesondere den Prisma-Bumerang
## über Abgründe hinweg aktiviert werden!

signal toggled(active: bool)

@export var switch_id: String = "switch_chasm"
@export var is_permanent: bool = true

var is_active: bool = false

const TEX_BLUE: Texture2D = preload("res://assets/objects/switch_crystal_blue.png")
const TEX_ORANGE: Texture2D = preload("res://assets/objects/switch_crystal_orange.png")

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 8 # Hurtbox layer for sword/spin and boomerang
	collision_mask = 4  # Hitbox layer
	area_entered.connect(_on_area_entered)
	_update_visuals()


func _on_area_entered(area: Area2D) -> void:
	if area.name == "SwordHitbox" or area.name == "SpinHitbox" or area is PrismaticBoomerang:
		hit_switch()


func hit_switch() -> void:
	if is_active and is_permanent:
		return

	is_active = not is_active
	_update_visuals()

	AudioManager.play_sfx("parry", 1.4)
	if _sprite != null:
		var tween := create_tween()
		if tween:
			tween.tween_property(_sprite, "scale", Vector2(0.48, 0.48), 0.08)
			tween.tween_property(_sprite, "scale", Vector2(0.4, 0.4), 0.12)

	toggled.emit(is_active)


func set_active(active: bool) -> void:
	is_active = active
	_update_visuals()


func _update_visuals() -> void:
	if _sprite:
		_sprite.texture = TEX_ORANGE if is_active else TEX_BLUE
