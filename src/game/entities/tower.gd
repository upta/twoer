extends StaticBody2D
class_name Tower

signal tower_destroyed(tower: Node2D)
signal tower_upgraded(tower: Node2D, new_level: int)

const TOWER_COLORS := {
	"AoE": Color(1.0, 0.0, 0.0),
	"RapidFire": Color(1.0, 0.5, 0.0),
	"Sniper": Color(0.5, 0.0, 1.0)
}

const TOWER_STATS := {
	"AoE": { "hp": 100, "damage": 30, "fire_rate": 2.0, "range": 150.0, "splash": true },
	"RapidFire": { "hp": 60, "damage": 5, "fire_rate": 0.5, "range": 120.0, "splash": false },
	"Sniper": { "hp": 100, "damage": 60, "fire_rate": 3.0, "range": 150.0, "splash": false }
}

var tower_type: String
var max_hp: int
var current_hp: int
var base_damage: int
var fire_rate: float
var attack_range: float
var is_splash: bool
var upgrade_level: int = 0
var total_damage_dealt: int = 0

var fire_timer: float = 0.0
var targets_in_range: Array[Node2D] = []

@onready var visual: ColorRect = $ColorRect
@onready var health_bar: ProgressBar = $HealthBar
@onready var range_area: Area2D = $RangeArea
@onready var range_collision: CollisionShape2D = $RangeArea/CollisionShape2D

func initialize(type: String) -> void:
	tower_type = type
	var stats: Dictionary = TOWER_STATS[type]
	
	max_hp = stats.hp
	current_hp = max_hp
	base_damage = stats.damage
	fire_rate = stats.fire_rate
	attack_range = stats.range
	is_splash = stats.splash
	
	if visual:
		visual.color = TOWER_COLORS.get(type, Color.RED)
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	
	if range_collision:
		var circle := range_collision.shape as CircleShape2D
		if circle:
			circle.radius = attack_range
	
	add_to_group("tower")

func _ready() -> void:
	if range_area:
		range_area.body_entered.connect(_on_range_body_entered)
		range_area.body_exited.connect(_on_range_body_exited)

func _process(delta: float) -> void:
	if current_hp <= 0:
		return
	
	fire_timer += delta
	
	if fire_timer >= fire_rate:
		fire_timer = 0.0
		_fire_at_targets()

func _fire_at_targets() -> void:
	if current_hp <= 0:
		return
	if targets_in_range.is_empty():
		return
	
	var damage_to_deal := base_damage * (1.0 + 0.25 * upgrade_level)
	
	if is_splash:
		for target in targets_in_range:
			if is_instance_valid(target) and target.has_method("take_damage"):
				target.take_damage(int(damage_to_deal))
				total_damage_dealt += int(damage_to_deal)
				_show_attack_line(target)
	else:
		var target := targets_in_range[0]
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(int(damage_to_deal))
			total_damage_dealt += int(damage_to_deal)
			_show_attack_line(target)

func _show_attack_line(target: Node2D) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = TOWER_COLORS.get(tower_type, Color.RED)
	line.default_color.a = 0.7
	line.add_point(Vector2.ZERO)
	line.add_point(target.global_position - global_position)
	add_child(line)
	
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("unit") or (body is CharacterBody2D and body.has_method("take_damage")):
		targets_in_range.append(body)

func _on_range_body_exited(body: Node2D) -> void:
	var idx := targets_in_range.find(body)
	if idx >= 0:
		targets_in_range.remove_at(idx)

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	
	if health_bar:
		health_bar.value = current_hp
	
	if current_hp <= 0:
		tower_destroyed.emit(self)
		queue_free()

func upgrade() -> void:
	if upgrade_level >= 2:
		return
	
	upgrade_level += 1
	
	if range_collision:
		var circle := range_collision.shape as CircleShape2D
		if circle:
			circle.radius = attack_range * (1.0 + 0.25 * upgrade_level)
	
	tower_upgraded.emit(self, upgrade_level)

func get_state() -> Dictionary:
	return {
		"tower_type": tower_type,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"damage": base_damage * (1.0 + 0.25 * upgrade_level),
		"fire_rate": fire_rate,
		"attack_range": attack_range * (1.0 + 0.25 * upgrade_level),
		"is_splash": is_splash,
		"upgrade_level": upgrade_level,
		"total_damage_dealt": total_damage_dealt,
		"targets_in_range": targets_in_range.size(),
		"position": global_position
	}
