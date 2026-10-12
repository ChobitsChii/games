class_name RoomTransitionTrigger
extends Area2D
## Interaktiver oder automatischer Raum- und Szenenübergang.
## Verbindet Oakhaven mit dem Wurzel-Schrein und umgekehrt.

@export var target_scene_path: String = "res://scenes/world/shrine_roots.tscn"
@export var prompt_key: String = "PROMPT_ENTER_DUNGEON"
@export var requires_interaction: bool = true

var _player_nearby: bool = false
@onready var _label: Label = $PromptLabel


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player layer
	if _label:
		_label.text = tr(prompt_key)
		_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and requires_interaction and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		trigger_transition()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true
		if requires_interaction and _label:
			_label.visible = true
		elif not requires_interaction:
			trigger_transition()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		if _label:
			_label.visible = false


func trigger_transition() -> void:
	AudioManager.play_sfx("dash", 1.2)
	get_tree().change_scene_to_file(target_scene_path)
