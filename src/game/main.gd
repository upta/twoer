extends Node2D

var level_select_scene: PackedScene = preload("res://game/ui/level_select.tscn")
var level_scene: PackedScene = preload("res://game/level/level.tscn")

var current_level_select: Control = null
var current_level: Level = null
var return_timer: Timer


func _ready() -> void:
	return_timer = Timer.new()
	return_timer.name = "ReturnTimer"
	return_timer.one_shot = true
	return_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	return_timer.timeout.connect(_on_return_timer_timeout)
	add_child(return_timer)
	
	_show_level_select()


func _show_level_select() -> void:
	if current_level_select != null:
		return
	
	get_tree().paused = false
	
	current_level_select = level_select_scene.instantiate()
	current_level_select.level_selected.connect(_on_level_selected)
	add_child(current_level_select)


func _on_level_selected(level_number: int) -> void:
	if current_level_select != null:
		current_level_select.queue_free()
		current_level_select = null
	
	current_level = level_scene.instantiate()
	add_child(current_level)
	
	var level_data: Dictionary = LevelData.get_level(level_number)
	current_level.setup(level_data)
	
	current_level.game_manager.level_won.connect(_on_level_won)
	current_level.game_manager.level_lost.connect(_on_level_lost)


func _on_level_won() -> void:
	return_timer.start(2.0)


func _on_level_lost() -> void:
	return_timer.start(2.0)


func _on_return_timer_timeout() -> void:
	if current_level != null:
		current_level.queue_free()
		current_level = null
	
	_show_level_select()
