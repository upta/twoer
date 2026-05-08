extends CharacterBody2D
class_name Unit

signal unit_died(unit: Node2D)
signal reached_end(unit: Node2D)

const UNIT_COLORS := {
	"Swarm": Color(0.0, 1.0, 0.0),
	"Tank": Color(0.0, 0.5, 1.0),
	"Speeder": Color(1.0, 1.0, 0.0)
}

const UNIT_SIZES := {
	"Swarm": Vector2(12, 12),
	"Tank": Vector2(24, 24),
	"Speeder": Vector2(16, 10)
}

var unit_type: String
var max_hp: int
var current_hp: int
var speed: float
var damage: int
var is_alive: bool = true
var lane: Node2D

enum State { MOVING, ATTACKING, DEAD }
var state: State = State.MOVING
var attack_target: Node2D = null
var attack_timer: float = 0.0
const ATTACK_INTERVAL: float = 1.0

@onready var visual: ColorRect = $ColorRect
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_area: Area2D = $AttackArea

func initialize(type: String, stats: Dictionary, parent_lane: Node2D) -> void:
	unit_type = type
	max_hp = stats.get("hp", stats.get("base_hp", 100))
	add_to_group("unit")
	current_hp = max_hp
	speed = stats.speed
	damage = stats.damage
	lane = parent_lane
	
	if visual:
		visual.color = UNIT_COLORS.get(type, Color.WHITE)
		visual.size = UNIT_SIZES.get(type, Vector2(16, 16))
		visual.position = -visual.size / 2.0
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp

func _ready() -> void:
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)

func _physics_process(delta: float) -> void:
	if not is_alive or state == State.DEAD:
		return
	
	match state:
		State.MOVING:
			velocity = Vector2(speed, 0)
			move_and_slide()
			
			if global_position.x > 1150:
				reached_end.emit(self)
				state = State.DEAD
				is_alive = false
		
		State.ATTACKING:
			velocity = Vector2.ZERO
			if attack_target and is_instance_valid(attack_target):
				attack_timer += delta
				if attack_timer >= ATTACK_INTERVAL:
					attack_timer = 0.0
					if attack_target.has_method("take_damage"):
						attack_target.take_damage(damage)
			else:
				state = State.MOVING
				attack_target = null
				attack_timer = 0.0

func _on_attack_area_body_entered(body: Node2D) -> void:
	if state == State.MOVING and (body.is_in_group("tower") or body.is_in_group("wall")):
		state = State.ATTACKING
		attack_target = body
		attack_timer = 0.0
		
		if body.has_signal("tower_destroyed"):
			if not body.tower_destroyed.is_connected(_on_target_destroyed):
				body.tower_destroyed.connect(_on_target_destroyed)
		elif body.has_signal("wall_destroyed"):
			if not body.wall_destroyed.is_connected(_on_target_destroyed):
				body.wall_destroyed.connect(_on_target_destroyed)

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == attack_target:
		state = State.MOVING
		attack_target = null
		attack_timer = 0.0

func _on_target_destroyed(_target: Node2D) -> void:
	state = State.MOVING
	attack_target = null
	attack_timer = 0.0

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	
	current_hp = max(0, current_hp - amount)
	
	if health_bar:
		health_bar.value = current_hp
	
	if current_hp <= 0:
		is_alive = false
		state = State.DEAD
		unit_died.emit(self)
		queue_free()

func heal(amount: int) -> void:
	if not is_alive:
		return
	
	current_hp = min(max_hp, current_hp + amount)
	
	if health_bar:
		health_bar.value = current_hp

func revive(hp_percent: float) -> void:
	if is_alive:
		return
	
	is_alive = true
	state = State.MOVING
	current_hp = int(max_hp * hp_percent)
	
	if health_bar:
		health_bar.value = current_hp

func get_state() -> Dictionary:
	return {
		"unit_type": unit_type,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"speed": speed,
		"damage": damage,
		"is_alive": is_alive,
		"state": State.keys()[state],
		"position": global_position
	}
