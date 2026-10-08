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

	if hud != null and hud.controller != null:
		var p := hud.controller.board.current_player()
		if p == Board.CELL_PLAYER_2:
			col = GameConfig.PALETTE["player2"]

	draw_circle(center, radius, col)
	draw_arc(center, radius, 0.0, TAU, 24, Color(1, 1, 1, 0.4), 2.0)
