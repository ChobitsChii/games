class_name NPCBase
extends StaticBody2D
## Basisklasse für freundliche Dorfbewohner in Oakhaven.
## Bietet sanfte Atemanimation, Interaktionsbereich,
## schwebenden Interaktions-Prompt und Blickrichtungs-Anpassung zum Spieler.

signal interacted(npc_id: String)

@export var npc_id: String = "morwen"
@export var sprite_texture: Texture2D
@export var display_name_key: String = "NPC_MORWEN"

var _player_nearby: Player = null
var _phase: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt: PanelContainer = $PromptContainer
@onready var _prompt_label: Label = $PromptContainer/Margin/Label
@onready var _interact_area: Area2D = $InteractArea


func _ready() -> void:
	if sprite_texture:
		_sprite.texture = sprite_texture
	_prompt.visible = false
	_prompt_label.text = tr("PROMPT_INTERACT")
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	# Sanfte Atemanimation
	_phase += delta * 2.6
	_sprite.position.y = -44.0 + sin(_phase) * 1.5

	# Wenn Spieler in Reichweite, auf Taste 'interact' prüfen
	if _player_nearby != null and is_instance_valid(_player_nearby):
		if Input.is_action_just_pressed("interact"):
			trigger_dialogue()


func trigger_dialogue() -> void:
	if _player_nearby != null and is_instance_valid(_player_nearby):
		# Zu Spieler drehen
		_sprite.flip_h = (_player_nearby.global_position.x < global_position.x)
	interacted.emit(npc_id)
	EventBus.interaction_requested.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = body
		_show_prompt(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if _player_nearby == body:
			_player_nearby = null
		_show_prompt(false)


func _show_prompt(show: bool) -> void:
	if show:
		_prompt.visible = true
		_prompt.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_prompt, "modulate:a", 1.0, 0.15)
		tween.parallel().tween_property(_prompt, "position:y", -110.0, 0.15)
	else:
		var tween := create_tween()
		tween.tween_property(_prompt, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func() -> void: _prompt.visible = false)
