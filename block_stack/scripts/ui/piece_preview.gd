class_name PiecePreview
extends Control
## Zeigt einen Tetromino zentriert an (für HOLD und NEXT-Vorschau).

@export var cell_size: float = 28.0
var piece_type: String = ""


func set_piece(type: String) -> void:
	piece_type = type
	queue_redraw()


func _draw() -> void:
	if piece_type == "":
		return

	var cells := Piece.get_cells(piece_type, 0)
	if cells.is_empty():
		return

	var min_c := 99
	var max_c := -99
	var min_r := 99
	var max_r := -99

	for c in cells:
		min_c = mini(min_c, c.x)
		max_c = maxi(max_c, c.x)
		min_r = mini(min_r, c.y)
		max_r = maxi(max_r, c.y)

	var w := (max_c - min_c + 1) * cell_size
	var h := (max_r - min_r + 1) * cell_size
	var offset := (size - Vector2(w, h)) * 0.5
	var color := Piece.get_color(piece_type)

	for c in cells:
		var x := offset.x + (c.x - min_c) * cell_size
		var y := offset.y + (c.y - min_r) * cell_size
		var block_rect := Rect2(x + 2, y + 2, cell_size - 4, cell_size - 4)

		draw_rect(block_rect, Color(color.r, color.g, color.b, 0.88))
		var shine := Rect2(block_rect.position.x + 1, block_rect.position.y + 1, block_rect.size.x - 2, block_rect.size.y * 0.35)
		draw_rect(shine, Color(1.0, 1.0, 1.0, 0.35))
		draw_rect(block_rect, Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 0.95), false, 1.5)
