extends Enemy

@export_group("Melee Attack")
@export var attack_range: float = 34.0
@export var attack_damage: int = 12
@export var attack_cooldown: float = 1.0
@export var windup_time: float = 0.12
@export var lunge_speed_multiplier: float = 1.2

var can_attack: bool = true

func _ready() -> void:
	super._ready()
	preferred_distance = 26.0
	orbit_weight = 0.12
	neighbor_avoidance_strength = 1.0
	wall_probe_distance = 40.0

func _physics_process(delta: float) -> void:
	if can_attack and _can_melee_attack():
		_perform_melee_attack()
		super._physics_process(delta)
		return

	stats["speed"] = speed * (lunge_speed_multiplier if can_attack else 1.0)
	super._physics_process(delta)
	stats["speed"] = speed

func _can_melee_attack() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) <= attack_range

func _perform_melee_attack() -> void:
	can_attack = false
	velocity = Vector2.ZERO
	modulate = Color(1.0, 0.55, 0.55, 1.0)
	await get_tree().create_timer(windup_time).timeout

	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range + 8.0:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)

	modulate = Color.WHITE
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
