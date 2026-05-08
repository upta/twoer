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
var _current_checkpoint_index: int = 0


func _ready() -> void:
	win_label.visible = false
	lose_label.visible = false


func _physics_process(_delta: float) -> void:
	if game_manager.phases.current_phase != PhaseManager.Phase.BATTLE:
		return
	
	if _current_checkpoint_index >= game_manager.phases.MAX_CHECKPOINTS:
		return
	
	# Need at least one deployed unit alive to trigger checkpoint
	var alive_units: Array[Node2D] = []
	for unit in deployer.deployed_units:
		if is_instance_valid(unit):
			alive_units.append(unit)
	
	if alive_units.is_empty():
		return
	
	# Check if ALL alive units have passed the current checkpoint x-position
	var checkpoint_x: float = battlefield.get_lane(0).checkpoint_positions[_current_checkpoint_index]
	var all_past: bool = true
	for unit in alive_units:
		if unit.global_position.x < checkpoint_x:
			all_past = false
			break
	
	if all_past:
		_current_checkpoint_index += 1
		game_manager.phases.reach_checkpoint()


func setup(p_level_data: Dictionary) -> void:
	level_data = p_level_data
	_current_checkpoint_index = 0
	
	game_manager.setup_level(level_data)
	battlefield.setup(level_data)
	deployer.setup(game_manager.units, battlefield)
	ai_defender.setup(battlefield)
	ui.setup(game_manager, deployer)
	
	game_manager.economy.reset_mana(50)
	
	game_manager.phases.phase_changed.connect(_on_phase_changed)
	deployer.unit_deployed.connect(_on_unit_deployed)
	deployer.deployment_complete.connect(_on_deployment_complete)
	
	game_manager.phases.start_level()


func _on_phase_changed(phase: PhaseManager.Phase) -> void:
	if phase == PhaseManager.Phase.BATTLE:
		battlefield.process_mode = Node.PROCESS_MODE_INHERIT
		deployer.start_deployment()
	elif phase == PhaseManager.Phase.CHECKPOINT:
		battlefield.process_mode = Node.PROCESS_MODE_DISABLED
		deployer.pause_deployment()
		# CHECKPOINT is transient: AI acts, +15 mana, then immediately to BATTLE_PLANNING
		ai_defender.execute_between_waves()
		game_manager.economy.add_mana(15)
		game_manager.phases.begin_battle_planning()
	else:
		battlefield.process_mode = Node.PROCESS_MODE_DISABLED


func _on_unit_deployed(unit: Node2D, _lane_index: int) -> void:
	unit.reached_end.connect(_on_unit_reached_end)
	unit.unit_died.connect(_on_unit_died)


func _on_unit_reached_end(_unit: Node2D) -> void:
	_trigger_win()


func _on_unit_died(_unit: Node2D) -> void:
	# deployer already removes from its array
	_check_lose_condition()


func _on_deployment_complete() -> void:
	_check_lose_condition()


func _check_lose_condition() -> void:
	# Lose when: no units left in queue AND no alive deployed units
	var alive_count := 0
	for unit in deployer.deployed_units:
		if is_instance_valid(unit):
			alive_count += 1
	
	if game_manager.units.unit_queue.is_empty() and alive_count == 0:
		_trigger_lose()


func _trigger_win() -> void:
	game_manager.phases.complete_level()
	deployer.pause_deployment()
	win_label.visible = true
	win_label.text = "Victory! You breached the defenses!"
	game_manager.level_won.emit()
	get_tree().paused = true


func _trigger_lose() -> void:
	game_manager.phases.complete_level()
	deployer.pause_deployment()
	lose_label.visible = true
	lose_label.text = "Defeat! All units were destroyed."
	game_manager.level_lost.emit()
	get_tree().paused = true
