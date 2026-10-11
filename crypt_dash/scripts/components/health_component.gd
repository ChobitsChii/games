class_name HealthComponent
extends Node
## Verwaltung von Lebenspunkten und Unverwundbarkeit.

signal health_changed(current: int, max_hp: int)
signal died

@export var max_health: int = 12
var current_health: int = 12


func init_health(p_max: int) -> void:
	max_health = p_max
	current_health = p_max
	health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()


func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func is_dead() -> bool:
	return current_health <= 0
