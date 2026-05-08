extends CanvasLayer
class_name GameUI

@onready var hud: HUD = $HUD
@onready var planning_panel: PlanningPanel = $PlanningPanel
@onready var tactical_panel: TacticalPanel = $TacticalPanel

var game_manager: GameManager


func setup(p_game_manager: GameManager, deployer: UnitDeployer) -> void:
	game_manager = p_game_manager
	
	hud.setup(game_manager.economy, game_manager.phases, game_manager.units, deployer)
	planning_panel.setup(game_manager.economy, game_manager.units, deployer, game_manager.phases)
	tactical_panel.visible = false
	
	game_manager.phases.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(game_manager.phases.current_phase)


func _on_phase_changed(phase: PhaseManager.Phase) -> void:
	# Tactical panel never shows (removed from game flow)
	tactical_panel.visible = false
	
	match phase:
		PhaseManager.Phase.INITIAL_PLANNING:
			planning_panel.visible = true
		PhaseManager.Phase.BATTLE_PLANNING:
			planning_panel.visible = true
		PhaseManager.Phase.BATTLE:
			planning_panel.visible = false
		PhaseManager.Phase.CHECKPOINT:
			planning_panel.visible = false
		PhaseManager.Phase.LEVEL_COMPLETE:
			planning_panel.visible = false
