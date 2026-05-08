extends Node2D

const LevelScene = preload("res://game/level/level.tscn")
const HarnessStateHelpers = preload("res://addons/agentic_godot_validation/runtime/support/harness_state_helpers.gd")

## Win screen harness: starts a battle and teleports a unit near the end of the lane
## so that win triggers within a few frames. Validates the win overlay state.

@export var deploy_lane: int = 2

var level: Level
var _win_setup_done := false
var _frames_waited := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	level = LevelScene.instantiate()
	add_child(level)
	level.setup(LevelData.get_level(1))

	# Buy a Swarm and start battle (deploys after 3s timer)
	level.game_manager.units.buy_unit("Swarm", level.game_manager.economy)
	level.deployer.current_lane = deploy_lane
	level.game_manager.phases.begin_battle_planning()
	level.game_manager.phases.begin_battle()


func _physics_process(_delta: float) -> void:
	if _win_setup_done:
		return
	_frames_waited += 1
	# Wait for deployment timer (3s = 180 frames at 60fps) + buffer
	if _frames_waited >= 190:
		if level.deployer.deployed_units.size() > 0:
			var unit = level.deployer.deployed_units[0]
			if is_instance_valid(unit) and unit.is_alive:
				# Place unit just before the win threshold (1150px)
				unit.global_position.x = 1145.0
				_win_setup_done = true


func reset_harness() -> void:
	pass


func get_observed_state() -> Dictionary:
	if not level or not is_instance_valid(level):
		return {"nodes": {}, "metrics": {"error": "level_not_ready"}, "signals": {}}

	var gm := level.game_manager
	var phase_name: String = PhaseManager.Phase.keys()[gm.phases.current_phase]
	var is_paused: bool = get_tree().paused

	# ResultOverlay state (CanvasLayer with layer=10)
	var result_overlay = level.get_node_or_null("ResultOverlay")
	var overlay_visible := false
	var overlay_layer := 0
	var result_label_text := ""

	if result_overlay:
		overlay_visible = result_overlay.visible
		overlay_layer = result_overlay.layer
		var result_label = result_overlay.get_node_or_null("ResultLabel")
		if result_label:
			result_label_text = result_label.text

	# Legacy win_label state (for transition period)
	var win_label = level.get_node_or_null("WinLabel")
	var win_label_visible := false
	var win_label_text := ""
	if win_label:
		win_label_visible = win_label.visible
		win_label_text = win_label.text

	return {
		"nodes": {
			"result_overlay": HarnessStateHelpers.build_node_facts(result_overlay) if result_overlay else {},
			"level": HarnessStateHelpers.build_node_facts(level),
		},
		"metrics": {
			"phase": phase_name,
			"is_paused": is_paused,
			"result_overlay_visible": overlay_visible,
			"result_overlay_layer": overlay_layer,
			"result_label_text": result_label_text,
			"win_label_visible": win_label_visible,
			"win_label_text": win_label_text,
		},
		"signals": {},
	}
