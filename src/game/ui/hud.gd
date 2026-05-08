extends Control
class_name HUD

@onready var gold_label: Label = $Panel/HBoxContainer/GoldLabel
@onready var mana_label: Label = $Panel/HBoxContainer/ManaLabel
@onready var phase_label: Label = $Panel/HBoxContainer/PhaseLabel
@onready var queue_label: Label = $Panel/HBoxContainer/QueueLabel
@onready var lane_label: Label = $Panel/HBoxContainer/LaneLabel

var economy: EconomyManager
var phases: PhaseManager
var units: UnitRegistry
var deployer: UnitDeployer


func setup(p_economy: EconomyManager, p_phases: PhaseManager, p_units: UnitRegistry, p_deployer: UnitDeployer) -> void:
	economy = p_economy
	phases = p_phases
	units = p_units
	deployer = p_deployer
	
	economy.gold_changed.connect(_on_gold_changed)
	economy.mana_changed.connect(_on_mana_changed)
	phases.phase_changed.connect(_on_phase_changed)
	units.queue_changed.connect(_on_queue_changed)
	
	_update_all()


func _update_all() -> void:
	_on_gold_changed(economy.gold)
	_on_mana_changed(economy.mana)
	_on_phase_changed(phases.current_phase)
	_on_queue_changed()


func _on_gold_changed(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount


func _on_mana_changed(amount: int) -> void:
	mana_label.text = "Mana: %d" % amount


func _on_phase_changed(phase: PhaseManager.Phase) -> void:
	var phase_names := {
		PhaseManager.Phase.INITIAL_PLANNING: "INITIAL_PLANNING",
		PhaseManager.Phase.BATTLE_PLANNING: "BATTLE_PLANNING",
		PhaseManager.Phase.BATTLE: "BATTLE",
		PhaseManager.Phase.CHECKPOINT: "CHECKPOINT",
		PhaseManager.Phase.LEVEL_COMPLETE: "LEVEL_COMPLETE"
	}
	phase_label.text = "Phase: %s" % phase_names.get(phase, "UNKNOWN")


func _on_queue_changed() -> void:
	queue_label.text = "Queue: %d units" % units.unit_queue.size()
	if deployer and deployer.current_lane >= 0:
		lane_label.text = "Lane: %d" % (deployer.current_lane + 1)
	else:
		lane_label.text = "Lane: -"
