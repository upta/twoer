extends Node2D

const LevelScene = preload("res://game/level/level.tscn")
const HarnessStateHelpers = preload("res://addons/agentic_godot_validation/runtime/support/harness_state_helpers.gd")

## Controls the initial game state for the harness.
## "initial" = Tutorial level, INITIAL_PLANNING, no units purchased.
## "with_units" = Tutorial level, INITIAL_PLANNING, one Swarm purchased.
## "battle_planning" = Tutorial level, BATTLE_PLANNING, one Swarm purchased.
## "battle" = Tutorial level, BATTLE phase, one Swarm purchased, deploying to deploy_lane.
@export var setup_mode: String = "initial"

## Lane index for unit deployment (lanes 2 and 3 have no defenses in Tutorial).
@export var deploy_lane: int = 2

var level: Level


func _ready() -> void:
	level = LevelScene.instantiate()
	add_child(level)
	level.setup(LevelData.get_level(1))

	if setup_mode in ["with_units", "battle_planning", "battle"]:
		_buy_initial_units()

	if setup_mode in ["battle_planning", "battle"]:
		level.deployer.current_lane = deploy_lane
		level.game_manager.phases.begin_battle_planning()

	if setup_mode == "battle":
		level.game_manager.phases.begin_battle()


func reset_harness() -> void:
	pass


func _buy_initial_units() -> void:
	level.game_manager.units.buy_unit("Swarm", level.game_manager.economy)


func get_observed_state() -> Dictionary:
	if not level or not is_instance_valid(level):
		return {"nodes": {}, "metrics": {"error": "level_not_ready"}, "signals": {}}

	var gm := level.game_manager
	var alive_deployed: int = 0
	for unit in level.deployer.deployed_units:
		if is_instance_valid(unit) and unit.is_alive:
			alive_deployed += 1

	return {
		"nodes": {
			"level": HarnessStateHelpers.build_node_facts(level),
			"battlefield": HarnessStateHelpers.build_node_facts(level.battlefield),
		},
		"metrics": {
			"phase": PhaseManager.Phase.keys()[gm.phases.current_phase],
			"gold": gm.economy.gold,
			"mana": gm.economy.mana,
			"unit_queue_size": gm.units.unit_queue.size(),
			"unit_queue_contents": ",".join(gm.units.unit_queue),
			"dead_units_count": gm.units.dead_units.size(),
			"deployed_count": level.deployer.deployed_units.size(),
			"alive_deployed_count": alive_deployed,
			"is_deploying": level.deployer.is_deploying,
			"checkpoint_index": level._current_checkpoint_index,
			"deploy_lane": level.deployer.current_lane,
		},
		"signals": {},
	}
