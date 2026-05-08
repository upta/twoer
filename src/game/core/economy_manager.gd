extends Node
class_name EconomyManager

signal gold_changed(new_amount: int)
signal mana_changed(new_amount: int)

var gold: int = 0
var mana: int = 0


func setup(starting_gold: int) -> void:
	gold = starting_gold
	mana = 0
	gold_changed.emit(gold)
	mana_changed.emit(mana)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func spend_mana(amount: int) -> bool:
	if mana < amount:
		return false
	mana -= amount
	mana_changed.emit(mana)
	return true


func add_mana(amount: int) -> void:
	mana += amount
	mana_changed.emit(mana)


func reset_mana(starting_mana: int) -> void:
	mana = starting_mana
	mana_changed.emit(mana)
