extends Node2D
## Hauptszene von Block Stack (Platzhalter für M0).

@export var autoplay := false

var score := 0
var lines := 0
var level := 1
var is_game_over := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	_init_seed()


func _init_seed() -> void:
	rng.randomize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			rng.seed = arg.trim_prefix("--seed=").to_int()
	print("Block Stack – Seed: %d" % rng.seed)
