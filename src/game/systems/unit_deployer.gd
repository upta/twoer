extends Node
class_name UnitDeployer

signal unit_deployed(unit_node: Node2D, lane_index: int)
signal deployment_complete

var deploy_interval: float = 3.0
var current_lane: int = 0
var is_held: bool = false
var is_deploying: bool = false
var deploy_timer: float = 0.0
var deployed_units: Array[Node2D] = []

var _unit_registry: UnitRegistry
var _battlefield: Battlefield

var unit_scene: PackedScene = preload("res://game/entities/unit.tscn")

func setup(unit_registry: UnitRegistry, battlefield: Battlefield) -> void:
	_unit_registry = unit_registry
	_battlefield = battlefield

func start_deployment() -> void:
	is_deploying = true
	deploy_timer = 0.0

func pause_deployment() -> void:
	is_deploying = false

func redirect_lane(new_lane: int) -> void:
	if new_lane >= 0 and new_lane < 4:
		current_lane = new_lane

func hold() -> void:
	is_held = true

func release_hold() -> void:
	is_held = false

func _process(delta: float) -> void:
	if not is_deploying or is_held:
		return
	
	deploy_timer += delta
	
	if deploy_timer >= deploy_interval:
		deploy_timer = 0.0
		_deploy_next_unit()

func _deploy_next_unit() -> void:
	if _unit_registry.unit_queue.is_empty():
		deployment_complete.emit()
		is_deploying = false
		return
	
	var unit_type: String = _unit_registry.unit_queue[0]
	_unit_registry.unit_queue.remove_at(0)
	_unit_registry.queue_changed.emit()
	
	var stats: Dictionary = _unit_registry.get_stats(unit_type)
	
	var lane: Lane = _battlefield.get_lane(current_lane)
	if not lane:
		return
	
	var unit: Node2D = unit_scene.instantiate()
	
	lane.add_unit(unit)
	# initialize after adding to tree so @onready vars are available
	unit.initialize(unit_type, stats, lane)
	unit.global_position = Vector2(50, lane.global_position.y + lane.lane_height / 2.0)
	
	if unit.has_signal("unit_died"):
		unit.unit_died.connect(_on_unit_died)
	if unit.has_signal("reached_end"):
		unit.reached_end.connect(_on_unit_reached_end)
	
	deployed_units.append(unit)
	
	unit_deployed.emit(unit, current_lane)
	
	if _unit_registry.unit_queue.is_empty():
		deployment_complete.emit()
		is_deploying = false

func _on_unit_died(unit: Node2D) -> void:
	var idx := deployed_units.find(unit)
	if idx >= 0:
		deployed_units.remove_at(idx)
	if unit.has_method("get_state"):
		var unit_type: String = unit.get_state().get("unit_type", "")
		if unit_type != "" and _unit_registry:
			_unit_registry.record_death(unit_type)

func _on_unit_reached_end(unit: Node2D) -> void:
	var idx := deployed_units.find(unit)
	if idx >= 0:
		deployed_units.remove_at(idx)

func get_state() -> Dictionary:
	return {
		"is_deploying": is_deploying,
		"is_held": is_held,
		"current_lane": current_lane,
		"deployed_count": deployed_units.size(),
		"remaining_in_queue": _unit_registry.unit_queue.size()
	}
