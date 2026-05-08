extends Node
class_name GameManager

signal level_won
signal level_lost
signal checkpoint_reached(checkpoint_index: int)

var economy: EconomyManager
var phases: PhaseManager
var units: UnitRegistry


func _ready() -> void:
	economy = EconomyManager.new()
	economy.name = "EconomyManager"
	add_child(economy)
	
	phases = PhaseManager.new()
	phases.name = "PhaseManager"
	add_child(phases)
	
	units = UnitRegistry.new()
	units.name = "UnitRegistry"
	add_child(units)
	
	phases.phase_changed.connect(_on_phase_changed)


func setup_level(level_data: Dictionary) -> void:
	var starting_gold: int = level_data.get("starting_gold", 100)
	economy.setup(starting_gold)
	units.reset()
	phases.start_level()


func _on_phase_changed(new_phase: PhaseManager.Phase) -> void:
	if new_phase == PhaseManager.Phase.CHECKPOINT:
		checkpoint_reached.emit(phases.current_checkpoint)


func check_win_condition() -> void:
	pass


func check_lose_condition() -> void:
	pass
