extends Node
class_name AIDefender

signal ai_action_complete

var _battlefield: Battlefield
var last_actions: Array[String] = []

func setup(battlefield: Battlefield) -> void:
	_battlefield = battlefield

func execute_between_waves() -> void:
	last_actions.clear()
	
	var all_defenses: Array[Node2D] = _battlefield.get_all_defenses()
	
	for defense in all_defenses:
		if defense.is_in_group("wall") and defense.has_method("repair"):
			defense.repair()
			last_actions.append("Repaired wall at position " + str(defense.global_position))
	
	var towers: Array[Node2D] = []
	for defense in all_defenses:
		if defense.is_in_group("tower"):
			towers.append(defense)
	
	if towers.is_empty():
		ai_action_complete.emit()
		return
	
	var best_tower: Node2D = null
	var highest_damage: int = 0
	
	for tower in towers:
		if tower.has_method("get_state"):
			var tower_state: Dictionary = tower.get_state()
			var damage_dealt: int = tower_state.get("total_damage_dealt", 0)
			if damage_dealt > highest_damage:
				highest_damage = damage_dealt
				best_tower = tower
	
	if best_tower and best_tower.has_method("upgrade"):
		var tower_state: Dictionary = best_tower.get_state()
		var current_level: int = tower_state.get("upgrade_level", 0)
		
		if current_level < 2:
			best_tower.upgrade()
			var tower_type: String = tower_state.get("tower_type", "Unknown")
			last_actions.append("Upgraded " + tower_type + " tower at position " + str(best_tower.global_position))
	
	ai_action_complete.emit()

func get_state() -> Dictionary:
	return {
		"last_actions": last_actions
	}
