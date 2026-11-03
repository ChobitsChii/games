class_name ScorePopup
extends Node2D
## Aufsteigende Punktezahl an der Stelle eines zerstörten Blocks. Die Farbe wird mit
## dem Combo-Multiplikator wärmer, bei hoher Combo auch größer.

const LIFETIME := 0.9
const RISE := 70.0

var text := ""
var color := Color.WHITE
var font_size := 34


## Erzeugt ein Popup. `multiplier` (1 bis 4) bestimmt Farbe und Größe.
static func spawn(parent: Node, pos: Vector2, points: int, multiplier: float) -> ScorePopup:
	var popup := ScorePopup.new()
	popup.text = "+%d" % points
	popup.color = color_for(multiplier)
	popup.font_size = size_for(multiplier)
	popup.position = pos
	popup.z_index = 6
	parent.add_child(popup)
	return popup


## Weiß bei einfachem Wert, über Gelb zu Magenta beim Maximum.
static func color_for(multiplier: float) -> Color:
	var t := clampf((multiplier - 1.0) / (PowerUps.MAX_COMBO_MULTIPLIER - 1.0), 0.0, 1.0)
	var base: Color = BreakoutConfig.PALETTE["text"]
	if t < 0.5:
		return base.lerp(BreakoutConfig.PALETTE["warn"], t * 2.0)
	return Color(BreakoutConfig.PALETTE["warn"]).lerp(BreakoutConfig.PALETTE["accent_alt"], (t - 0.5) * 2.0)


static func size_for(multiplier: float) -> int:
	return int(round(lerpf(32.0, 54.0, clampf((multiplier - 1.0) / (PowerUps.MAX_COMBO_MULTIPLIER - 1.0), 0.0, 1.0))))


func _ready() -> void:
	scale = Vector2.ONE * 0.6
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - RISE, LIFETIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME * 0.5).set_delay(LIFETIME * 0.5)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var font := BreakoutStyle.FONT_BOLD
	var bright := Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 1.0)
	var origin := Vector2(-100.0, font_size * 0.35)
	# Dunkler Schatten sorgt für Lesbarkeit auf hellen Blöcken.
	font.draw_string(get_canvas_item(), origin + Vector2(2, 3), text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, font_size, Color(0, 0, 0, 0.6))
	font.draw_string(get_canvas_item(), origin, text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, font_size, bright)
