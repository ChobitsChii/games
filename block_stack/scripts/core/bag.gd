class_name Bag
extends RefCounted
## 7-Bag Zufallsgenerator nach Tetris-Guideline.
## Garantiert, dass in jedem Block aus 7 Steinen jede Form genau einmal vorkommt.

var rng: RandomNumberGenerator
var _queue: Array[String] = []


func _init(random_generator: RandomNumberGenerator = null) -> void:
	if random_generator != null:
		rng = random_generator
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	_refill()


func _refill() -> void:
	var bag: Array[String] = ["I", "J", "L", "O", "S", "T", "Z"]
	# Fisher-Yates Shuffle
	for i in range(bag.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := bag[i]
		bag[i] = bag[j]
		bag[j] = temp
	_queue.append_array(bag)


func pop() -> String:
	while _queue.size() < 7:
		_refill()
	return _queue.pop_front()


func peek(count: int) -> Array[String]:
	while _queue.size() < count + 7:
		_refill()
	var result: Array[String] = []
	for i in range(count):
		result.append(_queue[i])
	return result
