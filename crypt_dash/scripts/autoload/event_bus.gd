class_name EventBusService
extends Node
## Zentraler Event-Bus für Crypt Dash zur losen Kopplung.

signal enemy_died(enemy: Node2D, souls: int)
signal enemy_damaged(enemy: Node2D, amount: int)
signal player_damaged(current_hp: int, max_hp: int)
signal player_healed(current_hp: int, max_hp: int)
signal room_entered(coords: Vector2i)
signal room_cleared(coords: Vector2i)
signal item_collected(item_id: String)
signal souls_changed(total_souls: int)
signal floor_completed(floor_num: int)
signal game_won
signal game_over
signal screen_shake_requested(intensity: float, duration: float)
