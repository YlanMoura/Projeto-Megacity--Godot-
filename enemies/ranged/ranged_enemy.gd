extends Enemy

const PROJECTILE_SCENE = preload("res://enemies/projectiles/enemy_bolt.tscn")

@export_group("Ranged Attack")
@export var ideal_range: float = 190.0
@export var minimum_range: float = 110.0
@export var projectile_speed: float = 280.0
@export var projectile_damage: int = 9
@export var shoot_cooldown: float = 1.35
@export var projectile_lifetime: float = 2.2

var can_shoot: bool = true

func _ready() -> void:
	super._ready()
	preferred_distance = ideal_range
	orbit_weight = 0.55
	neighbor_avoidance_strength = 0.8
	wall_probe_distance = 46.0

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target) and _wants_to_retreat():
		var retreat_direction: Vector2 = (global_position - target.global_position).normalized()
		var movement_direction: Vector2 = _get_steered_direction(retreat_direction, retreat_direction)
		movement_direction += _get_neighbor_separation_force()
		if movement_direction.length_squared() > 0.001:
			movement_direction = movement_direction.normalized()
		else:
			movement_direction = retreat_direction
		velocity = movement_direction * float(stats["speed"])
		move_and_slide()
		_attempt_shot()
		return

	super._physics_process(delta)
	_attempt_shot()

func _wants_to_retreat() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) < minimum_range

func _attempt_shot() -> void:
	if not can_shoot:
		return
	if target == null or not is_instance_valid(target):
		return

	var distance_to_target: float = global_position.distance_to(target.global_position)
	if distance_to_target > ideal_range + 30.0:
		return

	can_shoot = false
	modulate = Color(0.65, 1.0, 0.65, 1.0)
	await get_tree().create_timer(0.08).timeout
	_fire_projectile()
	modulate = Color.WHITE
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func _fire_projectile() -> void:
	if PROJECTILE_SCENE == null or target == null or not is_instance_valid(target):
		return

	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = global_position
	projectile.setup((target.global_position - global_position).normalized(), projectile_speed, projectile_damage, projectile_lifetime)
	get_tree().current_scene.add_child(projectile)
