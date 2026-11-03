class_name Transition
extends RefCounted
## Weiche Überblendung beim Szenenwechsel (dunkles Ein- und Ausblenden).
## In Tests tut sie nichts, damit keine Tweens übrig bleiben.

const DURATION := 0.28
const COLOR := Color("0a0b1a")

static var _busy := false


## Blendet beim Start einer Szene von Dunkel auf. `parent` ist die neue Szene.
static func fade_in(parent: Node) -> void:
	if SaveService.is_test_mode:
		return
	var layer := _make_layer(parent, 1.0)
	var tween := parent.create_tween().set_ignore_time_scale(true)
	tween.tween_property(layer.get_child(0), "color:a", 0.0, DURATION)
	tween.tween_callback(layer.queue_free)


## Blendet aus, wechselt die Szene und lässt die neue Szene durch fade_in erscheinen.
static func change_scene(tree: SceneTree, path: String) -> void:
	if SaveService.is_test_mode:
		tree.change_scene_to_file(path)
		return
	if _busy:
		return
	_busy = true
	var layer := _make_layer(tree.root, 0.0)
	var tween := tree.create_tween().set_ignore_time_scale(true)
	tween.tween_property(layer.get_child(0), "color:a", 1.0, DURATION)
	await tween.finished
	tree.change_scene_to_file(path)
	layer.queue_free()
	_busy = false


static func _make_layer(parent: Node, start_alpha: float) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(COLOR, start_alpha)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	parent.add_child(layer)
	return layer
