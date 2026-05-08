extends Node
class_name UnitRegistry

signal queue_changed
signal upgrade_purchased(unit_type: String, new_level: int)

const UNIT_STATS := {
	"Swarm": { "base_hp": 20, "speed": 100.0, "damage": 5, "cost": 10, "deploy_count": 3 },
	"Tank": { "base_hp": 150, "speed": 50.0, "damage": 15, "cost": 40, "deploy_count": 1 },
	"Speeder": { "base_hp": 40, "speed": 150.0, "damage": 8, "cost": 25, "deploy_count": 1 }
}

const UPGRADE_COSTS := {
	"Swarm": [10, 15],
	"Tank": [40, 60],
	"Speeder": [25, 40]
}

const UPGRADE_MULTIPLIERS := [1.0, 1.3, 1.6]

var unit_queue: Array[String] = []
var dead_units: Array[String] = []
var upgrades: Dictionary = {
	"Tank": 0,
	"Swarm": 0,
	"Speeder": 0
}

const REVIVE_COST := 30
const REVIVE_HP_PERCENT := 0.5


func buy_unit(unit_type: String, economy: Node) -> bool:
	if not UNIT_STATS.has(unit_type):
		return false
	
	var cost: int = UNIT_STATS[unit_type]["cost"]
	if not economy.spend_gold(cost):
		return false
	
	var deploy_count: int = UNIT_STATS[unit_type]["deploy_count"]
	for i in range(deploy_count):
		unit_queue.append(unit_type)
	
	queue_changed.emit()
	return true


func upgrade_unit(unit_type: String, economy: Node) -> bool:
	if not upgrades.has(unit_type):
		return false
	
	var current_level: int = upgrades[unit_type]
	if current_level >= 2:
		return false
	
	var cost: int = UPGRADE_COSTS[unit_type][current_level]
	if not economy.spend_gold(cost):
		return false
	
	upgrades[unit_type] += 1
	upgrade_purchased.emit(unit_type, upgrades[unit_type])
	return true


func get_stats(unit_type: String) -> Dictionary:
	if not UNIT_STATS.has(unit_type):
		return {}
	
	var base_stats: Dictionary = UNIT_STATS[unit_type].duplicate()
	var upgrade_level: int = upgrades.get(unit_type, 0)
	var multiplier: float = UPGRADE_MULTIPLIERS[upgrade_level]
	
	var stats: Dictionary = base_stats.duplicate()
	stats["hp"] = int(base_stats["base_hp"] * multiplier)
	stats["damage"] = int(base_stats["damage"] * multiplier)
	
	return stats


func reorder_queue(new_order: Array[String]) -> void:
	unit_queue = new_order.duplicate()
	queue_changed.emit()


func move_unit_in_queue(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= unit_queue.size():
		return
	if to_index < 0 or to_index >= unit_queue.size():
		return
	if from_index == to_index:
		return
	
	var unit_type: String = unit_queue[from_index]
	unit_queue.remove_at(from_index)
	unit_queue.insert(to_index, unit_type)
	queue_changed.emit()


func remove_from_queue(index: int) -> void:
	if index >= 0 and index < unit_queue.size():
		unit_queue.remove_at(index)
		queue_changed.emit()


func record_death(unit_type: String) -> void:
	dead_units.append(unit_type)
	queue_changed.emit()


func revive_unit(unit_type: String, economy: Node) -> bool:
	var idx := dead_units.find(unit_type)
	if idx < 0:
		return false
	if not economy.spend_mana(REVIVE_COST):
		return false
	dead_units.remove_at(idx)
	unit_queue.append(unit_type)
	queue_changed.emit()
	return true


func reset() -> void:
	unit_queue.clear()
	dead_units.clear()
	upgrades = {
		"Tank": 0,
		"Swarm": 0,
		"Speeder": 0
	}
	queue_changed.emit()
