extends Node2D
class_name Level

@onready var game_manager: GameManager = $GameManager
@onready var battlefield: Battlefield = $Battlefield
@onready var deployer: UnitDeployer = $UnitDeployer
@onready var ai_defender: AIDefender = $AIDefender
@onready var ui: CanvasLayer = $UI
@onready var win_label: Label = $WinLabel
@onready var lose_label: Label = $LoseLabel

var level_data: Dictionary
var checkpoint_x_positions: Array[int] = [400, 800]


func _ready() -> void:
	win_label.visible = false
	lose_label.visible = false


func setup(p_level_data: Dictionary) -> void:
	level_data = p_level_data
	
	game_manager.setup_level(level_data)
	battlefield.setup(level_data)
	deployer.setup(game_manager.units, battlefield)
	ai_defender.setup(battlefield)
	ui.setup(game_manager, deployer)
	
	game_manager.economy.reset_mana(50)
	
	game_manager.phases.phase_changed.connect(_on_phase_changed)
	deployer.unit_deployed.connect(_on_unit_deployed)
	deployer.deployment_complete.connect(_on_deployment_complete)
	ai_defender.ai_action_complete.connect(_on_ai_action_complete)
	
	game_manager.phases.start_level()


func _on_phase_changed(phase: PhaseManager.Phase) -> void:
	if phase == PhaseManager.Phase.BATTLE:
		deployer.start_deployment()
	elif phase == PhaseManager.Phase.CHECKPOINT:
		deployer.pause_deployment()
		ai_defender.execute_between_waves()


func _on_unit_deployed(unit: Node2D, _lane_index: int) -> void:
	unit.reached_end.connect(_on_unit_reached_end.bind(unit))
	unit.unit_died.connect(_on_unit_died.bind(unit))


func _on_unit_reached_end(unit: Node2D) -> void:
	_trigger_win()


func _on_unit_died(unit: Node2D) -> void:
	if deployer.deployed_units.has(unit):
		deployer.deployed_units.erase(unit)
	_check_lose_condition()


func _on_deployment_complete() -> void:
	_check_lose_condition()


func _on_ai_action_complete() -> void:
	game_manager.economy.add_mana(15)
	
	if game_manager.phases.current_checkpoint < game_manager.phases.MAX_CHECKPOINTS:
		game_manager.phases.begin_battle_planning()
	else:
		_check_lose_condition()


func _check_lose_condition() -> void:
	if not deployer.is_deploying and deployer.deployed_units.is_empty():
		_trigger_lose()


func _trigger_win() -> void:
	game_manager.phases.complete_level()
	deployer.pause_deployment()
	win_label.visible = true
	win_label.text = "Victory! You breached the defenses!"
	get_tree().paused = true


func _trigger_lose() -> void:
	game_manager.phases.current_phase = PhaseManager.Phase.LEVEL_COMPLETE
	deployer.pause_deployment()
	lose_label.visible = true
	lose_label.text = "Defeat! All units were destroyed."
	get_tree().paused = true
