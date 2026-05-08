extends Node2D
class_name Lane

@export var lane_index: int = 0
@export var lane_height: float = 120.0

var checkpoint_positions: Array[float] = [400.0, 800.0]

@onready var defense_container: Node2D = $DefenseContainer
@onready var unit_container: Node2D = $UnitContainer

func add_unit(unit_node: Node2D) -> void:
	unit_container.add_child(unit_node)

func add_defense(defense_node: Node2D, x_position: float) -> void:
	defense_container.add_child(defense_node)
	defense_node.position = Vector2(x_position, lane_height / 2.0)

func get_units() -> Array[Node2D]:
	var units: Array[Node2D] = []
	for child in unit_container.get_children():
		if is_instance_valid(child) and child is CharacterBody2D:
			units.append(child)
	return units

func get_defenses() -> Array[Node2D]:
	var defenses: Array[Node2D] = []
	for child in defense_container.get_children():
		if is_instance_valid(child):
			defenses.append(child)
	return defenses

func get_state() -> Dictionary:
	return {
		"lane_index": lane_index,
		"unit_count": get_units().size(),
		"defense_count": get_defenses().size()
	}
