class_name KineticTether
extends Node2D
## Visuelle Repräsentation und Node-Interaktion des Kinetischen Fangseils.
## Nutzt TetherModel für die Berechnungen.
## Zieht Kaelen an Pfähle heran, zieht Items an, löst Schalter aus
## und entreißt Feinden Schilde.

signal post_latched(anchor_pos: Vector2)
signal finished()

@onready var line: Line2D = $Line2D
@onready var hook_sprite: Sprite2D = $HookSprite
@onready var tip_area: Area2D = $TipArea

var model: TetherModel
var player_ref: Node2D = null
var _grabbed_item: Node2D = null


func _ready() -> void:
	model = TetherModel.new()
	tip_area.area_entered.connect(_on_tip_area_entered)
	tip_area.body_entered.connect(_on_tip_body_entered)


func launch(player: Node2D, direction: Vector2) -> void:
	player_ref = player
	global_position = player.global_position
	model.launch(global_position, direction)
	
	if hook_sprite:
		hook_sprite.rotation = direction.angle() + PI * 0.5
	_update_visuals()
	AudioManager.play_sfx("dash", 1.4)


func _physics_process(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		queue_free()
		return

	model.origin_pos = player_ref.global_position

	match model.current_state:
		TetherModel.State.EXTENDING:
			var tip := model.update_extension(delta)
			_set_tip_position(tip)

		TetherModel.State.RETRACTING:
			var tip := model.update_retraction(delta)
			_set_tip_position(tip)
			if model.current_state == TetherModel.State.IDLE:
				_finish_and_free()

		TetherModel.State.ATTACHED_POST:
			# Der Spieler wird in Player._physics_process gezogen
			_set_tip_position(model.target_anchor_pos)

		TetherModel.State.PULLING_ITEM:
			if _grabbed_item and is_instance_valid(_grabbed_item):
				var res := model.update_item_pull(_grabbed_item.global_position, player_ref.global_position, delta)
				_grabbed_item.global_position = res.pos
				_set_tip_position(res.pos)
				if res.finished:
					_grabbed_item = null
					_finish_and_free()
			else:
				model.current_state = TetherModel.State.RETRACTING

		TetherModel.State.STRIPPING_SHIELD, TetherModel.State.STUNNING_BOSS:
			# Kurze Haltephase (0.15s), dann Rückzug
			model.current_state = TetherModel.State.RETRACTING

		TetherModel.State.IDLE:
			_finish_and_free()


func _set_tip_position(pos: Vector2) -> void:
	if hook_sprite:
		hook_sprite.global_position = pos
	if tip_area:
		tip_area.global_position = pos
	_update_visuals()


func _update_visuals() -> void:
	if line and player_ref:
		line.clear_points()
		var start_local := to_local(player_ref.global_position)
		var end_local := to_local(hook_sprite.global_position) if hook_sprite else Vector2.ZERO
		line.add_point(start_local)
		line.add_point(end_local)


func _on_tip_area_entered(area: Area2D) -> void:
	if model.current_state != TetherModel.State.EXTENDING:
		return

	# 1. Ankerpfahl getroffen?
	if area.is_in_group("tether_anchors"):
		var post: Node2D = area.get_parent()
		var anchor_pos: Vector2 = post.global_position
		if post.has_method("get_anchor_position"):
			anchor_pos = post.get_anchor_position()
		if model.attach_to_post(anchor_pos, str(post.get_instance_id())):
			AudioManager.play_sfx("parry", 1.4)
			post_latched.emit(anchor_pos)
			if player_ref.has_method("pull_to_target"):
				player_ref.pull_to_target(anchor_pos, self)
			return

	# 2. Sammelbare Items?
	var parent_node := area.get_parent()
	if parent_node != null and (parent_node is LumenCrystal or parent_node is VitalityShard):
		if model.attach_to_item(parent_node.global_position, str(parent_node.get_instance_id())):
			_grabbed_item = parent_node
			AudioManager.play_sfx("lumen_collect", 1.3)
			return


func _on_tip_body_entered(body: Node2D) -> void:
	if model.current_state != TetherModel.State.EXTENDING:
		return

	# Ignoriere den Spieler selbst
	if body == player_ref:
		return

	# 1. Kristallschalter auslösen
	if body is SwitchCrystal:
		var sw: SwitchCrystal = body as SwitchCrystal
		sw.toggle()
		AudioManager.play_sfx("hit", 1.5)
		model.current_state = TetherModel.State.RETRACTING
		return

	# 2. Knochen-Krieger: Schild entreißen!
	if body is BoneWarrior:
		var warrior: BoneWarrior = body as BoneWarrior
		warrior.take_hit(10, global_position, 150.0)
		warrior.apply_stun(2.5)
		AudioManager.play_sfx("break", 1.3)
		model.strip_shield(str(warrior.get_instance_id()))
		return

	# 3. Boss Carapax: Panzer durchschlagen und umwerfen!
	if body.has_method("tether_hook_hit"):
		body.tether_hook_hit()
		AudioManager.play_sfx("break", 1.1)
		model.stun_boss(str(body.get_instance_id()))
		return

	# 4. Standard-Gegner betäuben
	if body is EnemyBase:
		var enemy: EnemyBase = body as EnemyBase
		enemy.take_hit(8, global_position, 100.0)
		enemy.apply_stun(1.8)
		AudioManager.play_sfx("hit", 1.3)
		model.current_state = TetherModel.State.RETRACTING
		return

	# 5. Feste Wände / Barrieren: Sofortiger Rückzug
	if body is StaticBody2D or body is TileMap:
		AudioManager.play_sfx("hit", 0.9)
		model.current_state = TetherModel.State.RETRACTING


func on_player_pull_finished() -> void:
	_finish_and_free()


func _finish_and_free() -> void:
	finished.emit()
	queue_free()
