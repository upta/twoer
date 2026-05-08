extends Panel
class_name PlanningPanel

@onready var buy_swarm_button: Button = $VBoxContainer/ShopSection/BuySwarmButton
@onready var buy_tank_button: Button = $VBoxContainer/ShopSection/BuyTankButton
@onready var buy_speeder_button: Button = $VBoxContainer/ShopSection/BuySpeedButton
@onready var upgrade_swarm_button: Button = $VBoxContainer/ShopSection/UpgradeSwarmButton
@onready var upgrade_tank_button: Button = $VBoxContainer/ShopSection/UpgradeTankButton
@onready var upgrade_speeder_button: Button = $VBoxContainer/ShopSection/UpgradeSpeedButton
@onready var queue_container: VBoxContainer = $VBoxContainer/QueueSection/QueueList
@onready var lane_1_button: Button = $VBoxContainer/LaneSection/LaneButtons/Lane1Button
@onready var lane_2_button: Button = $VBoxContainer/LaneSection/LaneButtons/Lane2Button
@onready var lane_3_button: Button = $VBoxContainer/LaneSection/LaneButtons/Lane3Button
@onready var lane_4_button: Button = $VBoxContainer/LaneSection/LaneButtons/Lane4Button
@onready var start_battle_button: Button = $VBoxContainer/StartBattleButton

var economy: EconomyManager
var units: UnitRegistry
var deployer: UnitDeployer
var phases: PhaseManager

var lane_buttons: Array[Button] = []
var _revive_buttons: Array[Button] = []
var _is_mana_mode: bool = false


func setup(p_economy: EconomyManager, p_units: UnitRegistry, p_deployer: UnitDeployer, p_phases: PhaseManager) -> void:
	economy = p_economy
	units = p_units
	deployer = p_deployer
	phases = p_phases
	
	lane_buttons = [lane_1_button, lane_2_button, lane_3_button, lane_4_button]
	
	buy_swarm_button.pressed.connect(_on_buy_unit.bind("Swarm"))
	buy_tank_button.pressed.connect(_on_buy_unit.bind("Tank"))
	buy_speeder_button.pressed.connect(_on_buy_unit.bind("Speeder"))
	
	upgrade_swarm_button.pressed.connect(_on_upgrade_unit.bind("Swarm"))
	upgrade_tank_button.pressed.connect(_on_upgrade_unit.bind("Tank"))
	upgrade_speeder_button.pressed.connect(_on_upgrade_unit.bind("Speeder"))
	
	for i in lane_buttons.size():
		lane_buttons[i].pressed.connect(_on_lane_selected.bind(i))
	
	start_battle_button.pressed.connect(_on_start_battle)
	
	economy.gold_changed.connect(_on_resources_changed)
	economy.mana_changed.connect(_on_resources_changed)
	units.queue_changed.connect(_on_queue_changed)
	units.upgrade_purchased.connect(_on_upgrade_purchased)
	phases.phase_changed.connect(_on_phase_changed)
	
	_update_all()


func _update_all() -> void:
	_update_mode()
	_update_buttons()
	_update_queue_display()
	_update_lane_selection()
	_update_start_button()
	_update_revive_section()


func _update_mode() -> void:
	_is_mana_mode = (phases.current_phase == PhaseManager.Phase.BATTLE_PLANNING)
	
	# Shop section only visible in gold mode (INITIAL_PLANNING)
	var shop_section := buy_swarm_button.get_parent()
	if shop_section:
		shop_section.visible = not _is_mana_mode


func _update_buttons() -> void:
	if _is_mana_mode:
		return
	
	buy_swarm_button.disabled = economy.gold < 10
	buy_tank_button.disabled = economy.gold < 40
	buy_speeder_button.disabled = economy.gold < 25
	
	var swarm_level: int = units.upgrades.get("Swarm", 0)
	var tank_level: int = units.upgrades.get("Tank", 0)
	var speeder_level: int = units.upgrades.get("Speeder", 0)
	
	var swarm_cost: int = UnitRegistry.UPGRADE_COSTS["Swarm"][swarm_level] if swarm_level < 2 else 0
	var tank_cost: int = UnitRegistry.UPGRADE_COSTS["Tank"][tank_level] if tank_level < 2 else 0
	var speeder_cost: int = UnitRegistry.UPGRADE_COSTS["Speeder"][speeder_level] if speeder_level < 2 else 0
	
	upgrade_swarm_button.text = "Upgrade Swarm Lv%d (%dg)" % [swarm_level, swarm_cost]
	upgrade_swarm_button.disabled = swarm_level >= 2 or economy.gold < swarm_cost
	
	upgrade_tank_button.text = "Upgrade Tank Lv%d (%dg)" % [tank_level, tank_cost]
	upgrade_tank_button.disabled = tank_level >= 2 or economy.gold < tank_cost
	
	upgrade_speeder_button.text = "Upgrade Speeder Lv%d (%dg)" % [speeder_level, speeder_cost]
	upgrade_speeder_button.disabled = speeder_level >= 2 or economy.gold < speeder_cost


func _update_queue_display() -> void:
	for child in queue_container.get_children():
		child.queue_free()
	
	var queue_size: int = units.unit_queue.size()
	# Queue reordering only available during BATTLE_PLANNING (per design)
	var show_reorder: bool = _is_mana_mode
	for i in queue_size:
		var row := HBoxContainer.new()
		
		var label := Label.new()
		label.text = "%d. %s" % [i + 1, units.unit_queue[i]]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		
		if show_reorder:
			var up_button := Button.new()
			up_button.text = "▲"
			up_button.disabled = (i == 0)
			up_button.custom_minimum_size = Vector2(30, 0)
			up_button.pressed.connect(_on_queue_move.bind(i, i - 1))
			row.add_child(up_button)
			
			var down_button := Button.new()
			down_button.text = "▼"
			down_button.disabled = (i == queue_size - 1)
			down_button.custom_minimum_size = Vector2(30, 0)
			down_button.pressed.connect(_on_queue_move.bind(i, i + 1))
			row.add_child(down_button)
		
		queue_container.add_child(row)


func _update_revive_section() -> void:
	# Clear old revive buttons
	for btn in _revive_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_revive_buttons.clear()
	
	if not _is_mana_mode:
		return
	
	if units.dead_units.is_empty():
		return
	
	# Add revive header
	var header := Label.new()
	header.text = "— Revive (%dm each) —" % UnitRegistry.REVIVE_COST
	queue_container.add_child(header)
	_revive_buttons.append(header)
	
	# Count dead units by type for display
	var dead_counts: Dictionary = {}
	for unit_type in units.dead_units:
		dead_counts[unit_type] = dead_counts.get(unit_type, 0) + 1
	
	for unit_type in dead_counts:
		var btn := Button.new()
		btn.text = "Revive %s x%d (50%% HP)" % [unit_type, dead_counts[unit_type]]
		btn.disabled = economy.mana < UnitRegistry.REVIVE_COST
		btn.pressed.connect(_on_revive_unit.bind(unit_type))
		queue_container.add_child(btn)
		_revive_buttons.append(btn)


func _update_lane_selection() -> void:
	# Lane selection only available during BATTLE_PLANNING (per design)
	var lane_section := lane_1_button.get_parent().get_parent()
	if lane_section:
		lane_section.visible = _is_mana_mode
	
	if deployer.current_lane >= 0 and deployer.current_lane < lane_buttons.size():
		for i in lane_buttons.size():
			lane_buttons[i].button_pressed = (i == deployer.current_lane)


func _update_start_button() -> void:
	if _is_mana_mode:
		# In BATTLE_PLANNING, always allow resuming battle (alive units keep fighting)
		start_battle_button.disabled = false
		start_battle_button.text = "Deploy!"
	else:
		start_battle_button.disabled = units.unit_queue.is_empty()
		start_battle_button.text = "Ready for Battle"


func _on_buy_unit(unit_type: String) -> void:
	units.buy_unit(unit_type, economy)


func _on_upgrade_unit(unit_type: String) -> void:
	units.upgrade_unit(unit_type, economy)


func _on_lane_selected(lane_index: int) -> void:
	if phases.current_phase == PhaseManager.Phase.BATTLE_PLANNING:
		deployer.current_lane = lane_index
		_update_lane_selection()


func _on_start_battle() -> void:
	if phases.current_phase == PhaseManager.Phase.INITIAL_PLANNING:
		phases.begin_battle_planning()
	elif phases.current_phase == PhaseManager.Phase.BATTLE_PLANNING:
		phases.begin_battle()


func _on_revive_unit(unit_type: String) -> void:
	units.revive_unit(unit_type, economy)


func _on_queue_move(from_index: int, to_index: int) -> void:
	units.move_unit_in_queue(from_index, to_index)


func _on_resources_changed(_amount: int) -> void:
	_update_buttons()
	_update_start_button()
	_update_revive_section()


func _on_queue_changed() -> void:
	_update_queue_display()
	_update_start_button()
	_update_revive_section()


func _on_upgrade_purchased(_type: String, _level: int) -> void:
	_update_buttons()


func _on_phase_changed(_phase: PhaseManager.Phase) -> void:
	_update_all()
