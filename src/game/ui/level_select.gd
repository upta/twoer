extends Control

signal level_selected(level_number: int)

@onready var level_1_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/Level1Button
@onready var level_2_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/Level2Button
@onready var level_3_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/Level3Button


func _ready() -> void:
	level_1_button.pressed.connect(_on_level_1_pressed)
	level_2_button.pressed.connect(_on_level_2_pressed)
	level_3_button.pressed.connect(_on_level_3_pressed)


func _on_level_1_pressed() -> void:
	level_selected.emit(1)


func _on_level_2_pressed() -> void:
	level_selected.emit(2)


func _on_level_3_pressed() -> void:
	level_selected.emit(3)
