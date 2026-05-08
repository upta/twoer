extends StaticBody2D
class_name Wall

signal wall_destroyed(wall: Node2D)

var max_hp: int = 200
var current_hp: int = 200

@onready var visual: ColorRect = $ColorRect
@onready var health_bar: ProgressBar = $HealthBar

func initialize() -> void:
	max_hp = 200
	current_hp = 200
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	
	add_to_group("wall")

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	
	if health_bar:
		health_bar.value = current_hp
	
	if current_hp <= 0:
		wall_destroyed.emit(self)
		queue_free()

func repair() -> void:
	current_hp = max_hp
	
	if health_bar:
		health_bar.value = current_hp

func get_state() -> Dictionary:
	return {
		"max_hp": max_hp,
		"current_hp": current_hp,
		"position": global_position
	}
