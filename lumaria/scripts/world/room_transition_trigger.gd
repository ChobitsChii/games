class_name RoomTransitionTrigger
extends Area2D
## Interaktiver oder automatischer Raum- und Szenenübergang.
## Erlaubt nahtloses Durchlaufen von Straßen und Toren (Walk-Through)
## oder optionales Interagieren per Taste [E].

@export var target_scene_path: String = "res://scenes/world/shrine_roots.tscn"
@export var prompt_key: String = "PROMPT_ENTER_DUNGEON"
@export var requires_interaction: bool = false
@export var entry_point_id: String = ""
@export var trigger_size: Vector2 = Vector2.ZERO

var _player_nearby: bool = false
var _cooldown: float = 0.6
@onready var _label: Label = $PromptLabel
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player layer

	if trigger_size != Vector2.ZERO and _collision_shape:
		var rect := RectangleShape2D.new()
		rect.size = trigger_size
		_collision_shape.shape = rect

	if _label:
		_label.text = tr(prompt_key)
		_label.visible = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		if _cooldown <= 0.0 and _player_nearby and not requires_interaction:
			trigger_transition()


func _unhandled_input(event: InputEvent) -> void:
	if _cooldown <= 0.0 and _player_nearby and requires_interaction and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		trigger_transition()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true
		if _cooldown <= 0.0:
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
	if _cooldown > 0.0:
		return
	_cooldown = 1.0
	_change_scene.call_deferred()


func _change_scene() -> void:
	AudioManager.play_sfx("dash", 1.2)
	if entry_point_id != "":
		Game.spawn_entry_point = entry_point_id
	var err: Error = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("Failed to change scene to: %s (code %d)" % [target_scene_path, err])
