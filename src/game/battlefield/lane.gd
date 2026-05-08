extends Node2D
class_name Lane

@export var lane_index: int = 0
@export var lane_height: float = 120.0

var checkpoint_positions: Array[float] = [400.0, 800.0]
var _checkpoint_lines: Array[Line2D] = []
var _checkpoint_labels: Array[Label] = []

const CHECKPOINT_COLOR := Color(1, 1, 0, 0.25)
const CHECKPOINT_REACHED_COLOR := Color(0.2, 1, 0.2, 0.35)
const CHECKPOINT_LINE_WIDTH := 2.0

@onready var defense_container: Node2D = $DefenseContainer
@onready var unit_container: Node2D = $UnitContainer

func _ready() -> void:
	_create_checkpoint_markers()


func _create_checkpoint_markers() -> void:
	for i in checkpoint_positions.size():
		var x_pos: float = checkpoint_positions[i]

		# Solid translucent vertical line spanning the lane
		var line := Line2D.new()
		line.width = CHECKPOINT_LINE_WIDTH
		line.default_color = CHECKPOINT_COLOR
		line.add_point(Vector2(x_pos, 0))
		line.add_point(Vector2(x_pos, lane_height))
		line.z_index = -1
		add_child(line)
		_checkpoint_lines.append(line)

		# Small label at top of lane
		var label := Label.new()
		label.text = "CP%d" % (i + 1)
		label.position = Vector2(x_pos - 12, 2)
		label.add_theme_color_override("font_color", CHECKPOINT_COLOR)
		label.add_theme_font_size_override("font_size", 10)
		label.z_index = -1
		add_child(label)
		_checkpoint_labels.append(label)


func mark_checkpoint_reached(checkpoint_index: int) -> void:
	if checkpoint_index < 0 or checkpoint_index >= _checkpoint_lines.size():
		return
	_checkpoint_lines[checkpoint_index].default_color = CHECKPOINT_REACHED_COLOR
	_checkpoint_labels[checkpoint_index].add_theme_color_override("font_color", CHECKPOINT_REACHED_COLOR)

func add_unit(unit_node: Node2D) -> void:
	unit_container.add_child(unit_node)

func add_defense(defense_node: Node2D, x_position: float) -> void:
	defense_container.add_child(defense_node)
	defense_node.position = Vector2(x_position, lane_height / 2.0)

func get_units() -> Array[Node2D]:
	var units: Array[Node2D] = []
	for child in unit_container.get_children():
		if is_instance_valid(child) and child is CharacterBody2D:
			units.append(child)
	return units

func get_defenses() -> Array[Node2D]:
	var defenses: Array[Node2D] = []
	for child in defense_container.get_children():
		if is_instance_valid(child):
			defenses.append(child)
	return defenses

func get_state() -> Dictionary:
	return {
		"lane_index": lane_index,
		"unit_count": get_units().size(),
		"defense_count": get_defenses().size()
	}
