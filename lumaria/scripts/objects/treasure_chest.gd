class_name TreasureChest
extends StaticBody2D
## Schatztruhe in Lumaria:
## Enthält Dungeon-Schlüssel, Boss-Schlüssel, das Sonnen-Prisma oder Lumen.
## Reagiert auf die Interaktionstaste [E] bei Annäherung.

signal opened(chest_id: String, item_type: String)

@export var chest_id: String = "chest_1"
@export var item_type: String = "small_key"
@export var is_opened: bool = false

const TEX_CLOSED: Texture2D = preload("res://assets/objects/chest_closed.png")
const TEX_OPEN: Texture2D = preload("res://assets/objects/chest_open.png")
const TEX_SMALL_KEY: Texture2D = preload("res://assets/objects/dungeon_small_key.png")
const TEX_BOSS_KEY: Texture2D = preload("res://assets/objects/dungeon_boss_key.png")
const TEX_SUN_PRISM: Texture2D = preload("res://assets/objects/sun_prism.png")
const TEX_TIDE_PRISM: Texture2D = preload("res://assets/objects/tide_prism.png")
const TEX_STORM_PRISM: Texture2D = preload("res://assets/objects/storm_prism.png")
const TEX_ETERNAL_PRISM: Texture2D = preload("res://assets/objects/eternal_prism.png")
const TEX_TETHER: Texture2D = preload("res://assets/objects/tether_hook.png")
const TEX_BOMB: Texture2D = preload("res://assets/objects/sonic_bomb.png")
const TEX_VITALITY: Texture2D = preload("res://assets/objects/vitality_shard.png")
const TEX_LUMEN: Texture2D = preload("res://assets/objects/lumen_crystal.png")

var _player_nearby: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt: Label = $PromptLabel
@onready var _interact_area: Area2D = $InteractArea


func _ready() -> void:
	if _prompt:
		_prompt.text = tr("PROMPT_CHEST_OPEN")
		_prompt.visible = false

	if _interact_area:
		_interact_area.body_entered.connect(_on_body_entered)
		_interact_area.body_exited.connect(_on_body_exited)

	if is_opened:
		_set_open_immediate()
	else:
		_sprite.texture = TEX_CLOSED


func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby or is_opened:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		open_chest()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_opened:
		_player_nearby = true
		if _prompt:
			_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		if _prompt:
			_prompt.visible = false


func open_chest() -> void:
	if is_opened:
		return
	is_opened = true
	_player_nearby = false
	if _prompt:
		_prompt.visible = false

	if _sprite:
		_sprite.texture = TEX_OPEN
	AudioManager.play_sfx("parry", 1.5)

	# Belohnungs-Animation (Item schwebt empor)
	_spawn_floating_reward()

	# DungeonState und EventBus aktualisieren
	if is_inside_tree():
		var tree := get_tree()
		var d_state: DungeonState = null
		if tree != null and tree.current_scene != null and tree.current_scene.has_node("DungeonController"):
			d_state = tree.current_scene.get_node("DungeonController").dungeon_state
		elif get_parent() != null and get_parent().get("dungeon_state") != null:
			d_state = get_parent().dungeon_state

		if d_state != null:
			d_state.open_chest(chest_id, item_type)

	_grant_rewards()
	opened.emit(chest_id, item_type)


func _grant_rewards() -> void:
	match item_type:
		"small_key":
			EventBus.show_toast_requested.emit(tr("MSG_FOUND_SMALL_KEY"))
			EventBus.key_count_changed.emit(1, false)
		"boss_key":
			EventBus.show_toast_requested.emit(tr("MSG_FOUND_BOSS_KEY"))
			EventBus.key_count_changed.emit(1, true)
		"sun_prism":
			EventBus.show_toast_requested.emit(tr("MSG_FOUND_SUN_PRISM"))
			EventBus.prism_collected.emit("sun_prism")
		"tide_prism":
			EventBus.show_toast_requested.emit(tr("MSG_FOUND_TIDE_PRISM"))
			EventBus.prism_collected.emit("tide_prism")
		"storm_prism":
			EventBus.show_toast_requested.emit(tr("MSG_FOUND_STORM_PRISM"))
			EventBus.prism_collected.emit("storm_prism")
		"eternal_prism":
			EventBus.show_toast_requested.emit(tr("MSG_FOUND_ETERNAL_PRISM"))
			EventBus.prism_collected.emit("eternal_prism")
		"tether":
			EventBus.show_toast_requested.emit(tr("MSG_FOUND_TETHER"))
			# Gadget freischalten
			if is_inside_tree():
				var players := get_tree().get_nodes_in_group("player")
				if players.size() > 0 and players[0].get_parent() != null and players[0].get_parent().get("inventory") != null:
					players[0].get_parent().inventory.unlock_gadget("tether")
		"bombs":
			EventBus.show_toast_requested.emit(tr("MSG_FOUND_BOMBS"))
			# Gadget freischalten
			if is_inside_tree():
				var players := get_tree().get_nodes_in_group("player")
				if players.size() > 0 and players[0].get_parent() != null and players[0].get_parent().get("inventory") != null:
					players[0].get_parent().inventory.unlock_gadget("bombs")
		"vitality_shard":
			EventBus.vitality_collected.emit(4)
		"lumen_50":
			EventBus.lumen_collected.emit(50)


func _spawn_floating_reward() -> void:
	if not is_inside_tree():
		return
	var item_sprite := Sprite2D.new()
	match item_type:
		"small_key":
			item_sprite.texture = TEX_SMALL_KEY
			item_sprite.scale = Vector2(0.35, 0.35)
		"boss_key":
			item_sprite.texture = TEX_BOSS_KEY
			item_sprite.scale = Vector2(0.4, 0.4)
		"sun_prism":
			item_sprite.texture = TEX_SUN_PRISM
			item_sprite.scale = Vector2(0.45, 0.45)
		"tide_prism":
			item_sprite.texture = TEX_TIDE_PRISM
			item_sprite.scale = Vector2(0.45, 0.45)
		"storm_prism":
			item_sprite.texture = TEX_STORM_PRISM
			item_sprite.scale = Vector2(0.45, 0.45)
		"eternal_prism":
			item_sprite.texture = TEX_ETERNAL_PRISM
			item_sprite.scale = Vector2(0.5, 0.5)
		"tether":
			item_sprite.texture = TEX_TETHER
			item_sprite.scale = Vector2(0.5, 0.5)
		"bombs":
			item_sprite.texture = TEX_BOMB
			item_sprite.scale = Vector2(0.5, 0.5)
		"vitality_shard":
			item_sprite.texture = TEX_VITALITY
			item_sprite.scale = Vector2(0.3, 0.3)
		_:
			item_sprite.texture = TEX_LUMEN
			item_sprite.scale = Vector2(0.35, 0.35)

	item_sprite.position = Vector2(0, -20)
	add_child(item_sprite)

	var tween := create_tween()
	tween.tween_property(item_sprite, "position:y", -70.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(item_sprite, "scale", item_sprite.scale * 1.3, 0.6)
	tween.tween_interval(0.4)
	tween.tween_property(item_sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(item_sprite.queue_free)


func _set_open_immediate() -> void:
	is_opened = true
	_sprite.texture = TEX_OPEN
	if _prompt:
		_prompt.visible = false
