extends Panel
class_name TacticalPanel

@onready var redirect_button: Button = $VBoxContainer/RedirectButton
@onready var hold_button: Button = $VBoxContainer/HoldButton
@onready var heal_button: Button = $VBoxContainer/HealButton
@onready var revive_button: Button = $VBoxContainer/ReviveButton

var economy: EconomyManager
var deployer: UnitDeployer

var is_holding: bool = false

const REDIRECT_COST := 20
const HOLD_COST := 15
const HEAL_COST := 20
const REVIVE_COST := 30
const HEAL_AMOUNT := 30


func setup(p_economy: EconomyManager, p_deployer: UnitDeployer) -> void:
	economy = p_economy
	deployer = p_deployer
	
	redirect_button.pressed.connect(_on_redirect_pressed)
	hold_button.pressed.connect(_on_hold_pressed)
	heal_button.pressed.connect(_on_heal_pressed)
	revive_button.pressed.connect(_on_revive_pressed)
	
	economy.mana_changed.connect(_on_mana_changed)
	
	revive_button.disabled = true
	revive_button.tooltip_text = "Coming soon"
	
	_update_buttons()


func _update_buttons() -> void:
	redirect_button.disabled = economy.mana < REDIRECT_COST
	
	if is_holding:
		hold_button.text = "Release Hold"
		hold_button.disabled = false
	else:
		hold_button.text = "Hold (15m)"
		hold_button.disabled = economy.mana < HOLD_COST
	
	heal_button.disabled = economy.mana < HEAL_COST


func _on_redirect_pressed() -> void:
	if economy.spend_mana(REDIRECT_COST):
		var next_lane := (deployer.current_lane + 1) % 4
		deployer.redirect_lane(next_lane)


func _on_hold_pressed() -> void:
	if is_holding:
		deployer.release_hold()
		is_holding = false
	else:
		if economy.spend_mana(HOLD_COST):
			deployer.hold()
			is_holding = true
	_update_buttons()


func _on_heal_pressed() -> void:
	if not economy.spend_mana(HEAL_COST):
		return
	
	for unit in deployer.deployed_units:
		if is_instance_valid(unit) and unit.has_method("get_state"):
			var state: Dictionary = unit.get_state()
			if state.get("state", "") != "DEAD" and unit.has_method("heal"):
				unit.heal(HEAL_AMOUNT)
				break


func _on_revive_pressed() -> void:
	pass


func _on_mana_changed(_amount: int) -> void:
	_update_buttons()
