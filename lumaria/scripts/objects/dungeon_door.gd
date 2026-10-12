class_name DungeonDoor
extends StaticBody2D
## Dungeon-Tor in Lumaria:
## Kann ein normales Schloss (kleiner Schlüssel), ein Boss-Tor (Boss-Schlüssel)
## oder ein Schalter-Gatter (durch Kristallschalter geöffnet) sein.

signal opened()

@export var door_id: String = "door_1"
@export var is_boss_door: bool = false
@export var requires_switch: bool = false
@export var linked_switch_id: String = ""
@export var is_open: bool = false

const TEX_NORMAL: Texture2D = preload("res://assets/objects/dungeon_gate.png")
const TEX_BOSS: Texture2D = preload("res://assets/objects/boss_gate.png")

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var _trigger: Area2D = $TriggerArea


func _ready() -> void:
	if is_boss_door:
		_sprite.texture = TEX_BOSS
		_sprite.scale = Vector2(0.52, 0.52)
	else:
		_sprite.texture = TEX_NORMAL
		_sprite.scale = Vector2(0.55, 0.55)

	if _trigger:
		_trigger.body_entered.connect(_on_trigger_body_entered)

	if is_open:
		_set_open_immediate()


func _on_trigger_body_entered(body: Node2D) -> void:
	if is_open or not (body is Player):
		return

	if requires_switch:
		return

	# Prüfen, ob Tür über DungeonState geöffnet werden kann
	var d_state: DungeonState = null
	if is_inside_tree():
		var tree := get_tree()
		if tree != null and tree.current_scene != null and tree.current_scene.has_node("DungeonController"):
			d_state = tree.current_scene.get_node("DungeonController").dungeon_state
		elif get_parent() != null and get_parent().get("dungeon_state") != null:
			d_state = get_parent().dungeon_state

	if d_state == null:
		# Fallback falls ohne Controller getestet
		open_door()
		return

	if d_state.can_unlock_door(door_id, is_boss_door):
		if d_state.unlock_door(door_id, is_boss_door):
			open_door()
	else:
		AudioManager.play_sfx("hit", 0.7)
		var msg_key: String = "MSG_BOSS_DOOR_LOCKED" if is_boss_door else "MSG_DOOR_LOCKED"
		EventBus.show_toast_requested.emit(tr(msg_key))


func open_door() -> void:
	if is_open:
		return
	is_open = true
	if _collider != null:
		_collider.set_deferred("disabled", true)
	AudioManager.play_sfx("parry", 0.9)

	if _sprite != null:
		var tween := create_tween()
		if tween:
			tween.tween_property(_sprite, "modulate:a", 0.0, 0.35)
			tween.parallel().tween_property(_sprite, "position:y", _sprite.position.y - 30.0, 0.35)
	opened.emit()


func _set_open_immediate() -> void:
	is_open = true
	if _collider != null:
		_collider.set_deferred("disabled", true)
	if _sprite != null:
		_sprite.modulate.a = 0.0
