extends Node2D

const LevelScene = preload("res://game/level/level.tscn")
const HarnessStateHelpers = preload("res://addons/agentic_godot_validation/runtime/support/harness_state_helpers.gd")

## Controls the initial game state for the harness.
## "initial" = Tutorial level, INITIAL_PLANNING, no units purchased.
## "with_units" = Tutorial level, INITIAL_PLANNING, one Swarm purchased.
## "battle_planning" = Tutorial level, BATTLE_PLANNING, one Swarm purchased.
## "battle_planning_with_dead" = Tutorial level, BATTLE_PLANNING, 1 unit in queue, 2 dead units, 80 mana.
## "battle" = Tutorial level, BATTLE phase, one Swarm purchased, deploying to deploy_lane.
@export var setup_mode: String = "initial"

## Lane index for unit deployment (lanes 2 and 3 have no defenses in Tutorial).
@export var deploy_lane: int = 2

var level: Level


func _ready() -> void:
	level = LevelScene.instantiate()
	add_child(level)
	level.setup(LevelData.get_level(1))

	if setup_mode in ["with_units", "battle_planning", "battle", "battle_planning_with_dead"]:
		_buy_initial_units()

	if setup_mode in ["battle_planning", "battle", "battle_planning_with_dead"]:
		level.deployer.current_lane = deploy_lane
		level.game_manager.phases.begin_battle_planning()

	if setup_mode == "battle_planning_with_dead":
		_setup_dead_units()

	if setup_mode == "battle":
		level.game_manager.phases.begin_battle()


func reset_harness() -> void:
	pass


func _buy_initial_units() -> void:
	level.game_manager.units.buy_unit("Swarm", level.game_manager.economy)


func _setup_dead_units() -> void:
	# Set mana to 80 for resurrection testing
	level.game_manager.economy.reset_mana(80)
	# Record 2 dead units for revive testing
	level.game_manager.units.record_death("Swarm")
	level.game_manager.units.record_death("Tank")


func get_observed_state() -> Dictionary:
	if not level or not is_instance_valid(level):
		return {"nodes": {}, "metrics": {"error": "level_not_ready"}, "signals": {}}

	var gm := level.game_manager
	var alive_deployed: int = 0
	for unit in level.deployer.deployed_units:
		if is_instance_valid(unit) and unit.is_alive:
			alive_deployed += 1

	# UI state extraction
	var ui_state := _get_ui_state()

	return {
		"nodes": {
			"level": HarnessStateHelpers.build_node_facts(level),
			"battlefield": HarnessStateHelpers.build_node_facts(level.battlefield),
			"planning_panel": ui_state.planning_panel_facts,
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
			"shop_section_visible": ui_state.shop_section_visible,
			"lane_section_visible": ui_state.lane_section_visible,
			"deploy_button_visible": ui_state.deploy_button_visible,
			"deploy_button_disabled": ui_state.deploy_button_disabled,
			"revive_section_visible": ui_state.revive_section_visible,
			"revive_button_count": ui_state.revive_button_count,
			"heal_button_visible": ui_state.heal_button_visible,
		},
		"signals": {},
	}


func _get_ui_state() -> Dictionary:
	var result := {
		"planning_panel_facts": {"visible": false},
		"shop_section_visible": false,
		"lane_section_visible": false,
		"deploy_button_visible": false,
		"deploy_button_disabled": true,
		"revive_section_visible": false,
		"revive_button_count": 0,
		"heal_button_visible": false,
	}

	var ui_node = level.get_node_or_null("UI")
	if not ui_node:
		return result

	var planning_panel = ui_node.get_node_or_null("PlanningPanel")
	if not planning_panel:
		return result

	result.planning_panel_facts = HarnessStateHelpers.build_node_facts(planning_panel)

	# Shop section visibility
	var shop_section = planning_panel.get_node_or_null("VBoxContainer/ShopSection")
	if shop_section:
		result.shop_section_visible = shop_section.visible

	# Lane section visibility
	var lane_section = planning_panel.get_node_or_null("VBoxContainer/LaneSection")
	if lane_section:
		result.lane_section_visible = lane_section.visible

	# Deploy/Start button
	var start_button = planning_panel.get_node_or_null("VBoxContainer/StartBattleButton")
	if start_button:
		result.deploy_button_visible = start_button.visible
		result.deploy_button_disabled = start_button.disabled

	# Revive section — check if mana action nodes exist in the planning panel
	var mana_action_nodes = planning_panel.get("_mana_action_nodes")
	if mana_action_nodes != null and mana_action_nodes.size() > 0:
		var revive_button_count := 0
		var heal_button_visible := false
		for node in mana_action_nodes:
			if is_instance_valid(node) and node is Button:
				if node.text.begins_with("Heal"):
					heal_button_visible = true
				elif node.text.begins_with("Revive"):
					revive_button_count += 1
		result.revive_button_count = revive_button_count
		result.revive_section_visible = revive_button_count > 0
		result["heal_button_visible"] = heal_button_visible

	return result
