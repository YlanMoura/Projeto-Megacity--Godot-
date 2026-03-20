extends CharacterBody2D
class_name Enemy

@export_group("Stats")
@export var speed: float = 100.0
@export var max_health: int = 50

@export_group("Combat")
@export var base_atk: int = 20
@export var base_ph: int = 20

@export_group("Movement")
@export var stop_distance: float = 18.0
@export var preferred_distance: float = 42.0
@export var orbit_weight: float = 0.35
@export var orbit_switch_interval: float = 1.4
@export var neighbor_avoidance_radius: float = 56.0
@export var neighbor_avoidance_strength: float = 0.9
@export var wall_probe_distance: float = 34.0
@export var wall_steer_angle_degrees: float = 30.0

var current_health: int = 0
var target: Node2D = null
var stats: Dictionary = {}
const FLOATING_NUMBER_SCENE = preload("res://ui/floating_number.tscn")
const ALMA_SCENE = preload("res://characters/Inferno/skills/soul/alma.tscn")

var is_stunned: bool = false
var is_knocked_up: bool = false
var orbit_direction_sign: float = 1.0
var orbit_switch_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("inimigos")
	current_health = max_health
	orbit_direction_sign = -1.0 if randf() < 0.5 else 1.0
	orbit_switch_timer = randf_range(0.4, orbit_switch_interval)

	stats = {
		"max_hp": max_health,
		"speed": speed,
		"atk": base_atk,
		"ph": base_ph,
	}

func _physics_process(delta: float) -> void:
	if is_stunned or is_knocked_up:
		velocity = Vector2.ZERO
		return

	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	orbit_switch_timer -= delta
	if orbit_switch_timer <= 0.0:
		orbit_direction_sign *= -1.0
		orbit_switch_timer = orbit_switch_interval + randf_range(-0.25, 0.35)

	var to_target: Vector2 = target.global_position - global_position
	var distance_to_target: float = to_target.length()
	if distance_to_target <= stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var chase_direction: Vector2 = to_target.normalized()
	var movement_direction: Vector2 = _get_engagement_direction(chase_direction, distance_to_target)
	movement_direction = _get_steered_direction(movement_direction, chase_direction)
	movement_direction += _get_neighbor_separation_force()

	if movement_direction.length_squared() > 0.001:
		movement_direction = movement_direction.normalized()
	else:
		movement_direction = chase_direction

	velocity = movement_direction * float(stats["speed"])
	move_and_slide()

func _get_engagement_direction(chase_direction: Vector2, distance_to_target: float) -> Vector2:
	var tangent: Vector2 = Vector2(-chase_direction.y, chase_direction.x) * orbit_direction_sign
	var distance_offset: float = clampf((distance_to_target - preferred_distance) / max(preferred_distance, 1.0), -1.0, 1.0)
	var radial_weight: float = 1.0

	if distance_to_target < preferred_distance:
		radial_weight = 0.45
	elif distance_to_target < preferred_distance * 1.35:
		radial_weight = 0.75

	var desired: Vector2 = chase_direction * radial_weight * max(distance_offset, 0.25)
	if distance_to_target < preferred_distance:
		desired -= chase_direction * (1.0 - distance_offset)

	desired += tangent * orbit_weight
	if desired.length_squared() > 0.001:
		return desired.normalized()
	return chase_direction

func _get_neighbor_separation_force() -> Vector2:
	if neighbor_avoidance_radius <= 0.0 or neighbor_avoidance_strength <= 0.0:
		return Vector2.ZERO

	var push_force: Vector2 = Vector2.ZERO
	var neighbors: Array = get_tree().get_nodes_in_group("enemies")

	for neighbor in neighbors:
		if neighbor == self or not (neighbor is Enemy):
			continue

		var offset: Vector2 = global_position - neighbor.global_position
		var distance: float = offset.length()
		if distance <= 0.001 or distance > neighbor_avoidance_radius:
			continue

		var weight: float = (neighbor_avoidance_radius - distance) / neighbor_avoidance_radius
		push_force += offset.normalized() * weight

	return push_force * neighbor_avoidance_strength

func _get_steered_direction(desired_direction: Vector2, chase_direction: Vector2) -> Vector2:
	if desired_direction.length_squared() <= 0.001:
		return Vector2.ZERO

	var desired_normalized: Vector2 = desired_direction.normalized()
	if not _is_direction_blocked(desired_normalized):
		return desired_normalized

	var steer_angle: float = deg_to_rad(wall_steer_angle_degrees)
	var candidates: Array[Vector2] = [
		desired_normalized,
		chase_direction,
		desired_normalized.rotated(steer_angle),
		desired_normalized.rotated(-steer_angle),
		desired_normalized.rotated(steer_angle * 2.0),
		desired_normalized.rotated(-steer_angle * 2.0),
		Vector2(-desired_normalized.y, desired_normalized.x),
		Vector2(desired_normalized.y, -desired_normalized.x),
	]

	var best_direction: Vector2 = desired_normalized
	var best_score: float = -INF

	for candidate in candidates:
		var normalized_candidate: Vector2 = candidate.normalized()
		if normalized_candidate.length_squared() <= 0.001:
			continue
		if _is_direction_blocked(normalized_candidate):
			continue

		var alignment_score: float = normalized_candidate.dot(desired_normalized) * 2.0
		var chase_score: float = normalized_candidate.dot(chase_direction)
		var spacing_score: float = normalized_candidate.dot(_get_neighbor_separation_force()) * 0.35
		var total_score: float = alignment_score + chase_score + spacing_score

		if total_score > best_score:
			best_score = total_score
			best_direction = normalized_candidate

	if best_score > -INF:
		return best_direction

	return Vector2.ZERO

func _is_direction_blocked(direction: Vector2) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + direction * wall_probe_distance)
	query.exclude = [self]
	query.collision_mask = collision_mask
	var result: Dictionary = space_state.intersect_ray(query)
	return not result.is_empty()

func take_damage(amount: int) -> void:
	current_health -= amount
	mostrar_texto_flutuante(amount, "dano")

	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout

	if is_stunned:
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE

	if current_health <= 0:
		die()

func apply_stun(duration: float) -> void:
	is_stunned = true
	velocity = Vector2.ZERO
	modulate = Color.GRAY
	await get_tree().create_timer(duration).timeout
	is_stunned = false
	modulate = Color.WHITE

func apply_knockup(force: Vector2, duration: float) -> void:
	if is_knocked_up:
		return

	is_knocked_up = true
	velocity = Vector2.ZERO

	var tween: Tween = create_tween()
	var original_pos: Vector2 = position
	var target_pos: Vector2 = position + force

	tween.tween_property(self, "position", target_pos, duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", original_pos, duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished
	is_knocked_up = false

func die() -> void:
	print("Enemy died!")
	spawnar_alma()
	queue_free()

func mostrar_texto_flutuante(valor: int, tipo: String) -> void:
	if FLOATING_NUMBER_SCENE:
		var texto = FLOATING_NUMBER_SCENE.instantiate()
		get_tree().current_scene.add_child(texto)
		texto.global_position = global_position + Vector2.UP * 30
		texto.setup(valor, tipo)

func spawnar_alma() -> void:
	if target and ALMA_SCENE:
		var alma = ALMA_SCENE.instantiate()
		alma.global_position = global_position
		alma.setup(target)
		get_tree().current_scene.add_child(alma)
