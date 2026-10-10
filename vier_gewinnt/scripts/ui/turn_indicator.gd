class_name TurnIndicator
extends Control
## Zeigt ein Symbol/Diskus des Spielers an, der aktuell am Zug ist.

var hud: HUD


func _ready() -> void:
	custom_minimum_size = Vector2(40, 40)


func _draw() -> void:
	var center := size * 0.5
	var radius := 16.0
	var col := GameConfig.PALETTE["player1"]
	var p := Board.CELL_PLAYER_1

	if hud != null and hud.controller != null:
		if hud.controller.state == GameController.State.GAME_OVER and hud.controller.board.has_won():
			p = hud.controller.board.last_player()
		else:
			p = hud.controller.board.current_player()
		if p == Board.CELL_PLAYER_2:
			col = GameConfig.PALETTE["player2"]

	draw_circle(center, radius, col)
	draw_arc(center, radius, 0.0, TAU, 24, Color(1, 1, 1, 0.4), 2.0)
	draw_circle(center + Vector2(-radius * 0.28, -radius * 0.28), radius * 0.35, Color(1, 1, 1, 0.35))

	if hud != null and hud.controller != null and hud.controller.colorblind_mode:
		var sym_col := Color(1, 1, 1, 0.9)
		if p == Board.CELL_PLAYER_1:
			draw_arc(center, radius * 0.45, 0.0, TAU, 20, sym_col, 2.5)
		else:
			var sz := radius * 0.45
			draw_line(center - Vector2(sz, 0), center + Vector2(sz, 0), sym_col, 2.5)
			draw_line(center - Vector2(0, sz), center + Vector2(0, sz), sym_col, 2.5)
