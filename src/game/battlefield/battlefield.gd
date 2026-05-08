extends Node2D
class_name Battlefield

@onready var lane1: Lane = $Lane1
@onready var lane2: Lane = $Lane2
@onready var lane3: Lane = $Lane3
@onready var lane4: Lane = $Lane4

var tower_scene: PackedScene = preload("res://game/entities/tower.tscn")
var wall_scene: PackedScene = preload("res://game/entities/wall.tscn")

func setup(level_data: Dictionary) -> void:
	clear()
	
	var lanes_data: Array = level_data.get("lanes", [])
	for i in range(min(lanes_data.size(), 4)):
		var lane_data: Dictionary = lanes_data[i]
		var defenses_data: Array = lane_data.get("defenses", [])
		var lane_node: Lane = get_lane(i)
		
		if not lane_node:
			continue
		
		for defense_entry in defenses_data:
			var defense_type: String = defense_entry.get("type", "")
			var x_pos: float = defense_entry.get("x", 0.0)
			
			var defense_node: Node2D = null
			
			if defense_type == "Wall":
				defense_node = wall_scene.instantiate()
			elif defense_type in ["AoE", "RapidFire", "Sniper"]:
				defense_node = tower_scene.instantiate()
			
			if defense_node:
				lane_node.add_defense(defense_node, x_pos)
				# initialize after adding to tree so @onready vars are available
				if defense_type == "Wall":
					defense_node.initialize()
				else:
					defense_node.initialize(defense_type)

func get_lane(index: int) -> Lane:
	match index:
		0: return lane1
		1: return lane2
		2: return lane3
		3: return lane4
		_: return null

func get_all_units() -> Array[Node2D]:
	var all_units: Array[Node2D] = []
	for i in range(4):
		var lane := get_lane(i)
		if lane:
			all_units.append_array(lane.get_units())
	return all_units

func get_all_defenses() -> Array[Node2D]:
	var all_defenses: Array[Node2D] = []
	for i in range(4):
		var lane := get_lane(i)
		if lane:
			all_defenses.append_array(lane.get_defenses())
	return all_defenses

func clear() -> void:
	for i in range(4):
		var lane := get_lane(i)
		if not lane:
			continue
		
		for unit in lane.get_units():
			if is_instance_valid(unit):
				unit.queue_free()
		
		for defense in lane.get_defenses():
			if is_instance_valid(defense):
				defense.queue_free()

func get_state() -> Dictionary:
	var lanes_state: Array[Dictionary] = []
	for i in range(4):
		var lane := get_lane(i)
		if lane:
			lanes_state.append(lane.get_state())
	
	return {
		"total_units": get_all_units().size(),
		"total_defenses": get_all_defenses().size(),
		"lanes": lanes_state
	}
