extends Node
class_name PhaseManager

signal phase_changed(new_phase: Phase)

enum Phase {
	INITIAL_PLANNING,
	BATTLE_PLANNING,
	BATTLE,
	CHECKPOINT,
	LEVEL_COMPLETE
}

const MAX_CHECKPOINTS := 2

var current_phase: Phase = Phase.INITIAL_PLANNING
var current_checkpoint: int = 0


func start_level() -> void:
	current_phase = Phase.INITIAL_PLANNING
	current_checkpoint = 0
	phase_changed.emit(current_phase)


func begin_battle_planning() -> void:
	if current_phase != Phase.INITIAL_PLANNING and current_phase != Phase.CHECKPOINT:
		push_warning("Invalid phase transition to BATTLE_PLANNING from %s" % Phase.keys()[current_phase])
		return
	
	current_phase = Phase.BATTLE_PLANNING
	phase_changed.emit(current_phase)


func begin_battle() -> void:
	if current_phase != Phase.BATTLE_PLANNING:
		push_warning("Invalid phase transition to BATTLE from %s" % Phase.keys()[current_phase])
		return
	
	current_phase = Phase.BATTLE
	phase_changed.emit(current_phase)


func reach_checkpoint() -> void:
	if current_phase != Phase.BATTLE:
		push_warning("Invalid phase transition to CHECKPOINT from %s" % Phase.keys()[current_phase])
		return
	
	current_phase = Phase.CHECKPOINT
	current_checkpoint += 1
	phase_changed.emit(current_phase)


func complete_level() -> void:
	if current_phase != Phase.BATTLE:
		push_warning("Invalid phase transition to LEVEL_COMPLETE from %s" % Phase.keys()[current_phase])
		return
	
	current_phase = Phase.LEVEL_COMPLETE
	phase_changed.emit(current_phase)
