extends ClassPlayer

const VIXY_MOLLY_ZONE_SCENE = preload("res://characters/Vixy/skills/VixyMollyZone.tscn")
const NEON_GREEN = Color(0.78, 1.0, 0.12, 1.0)
const NEON_GREEN_SOFT = Color(0.78, 1.0, 0.12, 0.35)

@export_group("Basic Attack")
@export var basic_attack_range: float = 700.0
@export var basic_attack_pick_radius: float = 180.0
@export var basic_attack_cooldown: float = 0.2
@export var basic_attack_base_damage: float = 12.0

@export_group("Passive: Rising Exposure")
@export var max_exposure_stacks: int = 10
@export var base_exposure_per_hit: int = 1
@export var radioactive_burn_duration: float = 1.0
@export var radioactive_burn_ticks: int = 5

@export_group("Skill 1: Neon Molly")
@export var molly_range: float = 560.0
@export var molly_pick_radius: float = 180.0
@export var molly_radius: float = 96.0
@export var molly_attack_scale: float = 0.8
@export var molly_ph_scale: float = 1.2
@export var molly_fire_tail_stacks_applied: int = 3
@export var attack_steal_ratio: float = 0.35
@export var attack_steal_duration: float = 3.0

var can_basic_attack: bool = true
var exposure_by_enemy := {}
var fire_tail_by_enemy := {}
var burn_versions := {}
var active_stolen_atk_bonus: int = 0
var attack_steal_version: int = 0

func _ready():
	super._ready()

func _physics_process(delta):
	super(delta)
	_cleanup_tracked_targets()
	
	if not is_active:
		return
	
	if Input.is_action_pressed("ataque"):
		attempt_basic_attack()

func attempt_basic_attack():
	if not can_basic_attack or is_dashing:
		return
	
	var target_enemy = _get_enemy_near_mouse(basic_attack_range, basic_attack_pick_radius)
	if target_enemy == null:
		return
	
	can_basic_attack = false
	_fire_basic_attack(target_enemy)
	await get_tree().create_timer(basic_attack_cooldown).timeout
	can_basic_attack = true

func _fire_basic_attack(target_enemy: Enemy):
	await _show_attack_line(target_enemy.global_position, NEON_GREEN, 0.08)
	var damage_result = calculate_damage(basic_attack_base_damage, "atk")
	target_enemy.take_damage(damage_result["value"])
	var exposure_amount = base_exposure_per_hit
	if damage_result["critical"]:
		exposure_amount *= 2
	_show_popup(target_enemy.global_position + Vector2(0, -34), "+%d EXP" % exposure_amount, NEON_GREEN)
	_apply_exposure(target_enemy, exposure_amount)

func attempt_skill_1():
	if not can_use_skill_1 or is_dashing:
		return
	
	var target_enemy = _get_enemy_near_mouse(molly_range, molly_pick_radius)
	if target_enemy == null:
		return
	
	can_use_skill_1 = false
	_spawn_neon_molly(target_enemy)
	await get_tree().create_timer(skill_1_cooldown).timeout
	can_use_skill_1 = true

func _spawn_neon_molly(target_enemy: Enemy):
	var impact_position = target_enemy.global_position
	await _show_attack_line(impact_position, Color(0.92, 1.0, 0.3, 0.95), 0.12)
	_show_popup(impact_position + Vector2(0, -42), "MOLLY", Color(0.95, 1.0, 0.35, 1.0), 22)
	
	var molly_damage = int(10 + stats["atk"] * molly_attack_scale + stats["PH"] * molly_ph_scale)
	var tick_damage = max(1, int(stats["PH"] * 0.22))
	var zone = VIXY_MOLLY_ZONE_SCENE.instantiate()
	zone.global_position = impact_position
	zone.radius = molly_radius
	zone.setup(self, molly_damage, tick_damage)
	get_tree().current_scene.add_child(zone)
	_add_fire_tail(target_enemy, molly_fire_tail_stacks_applied)
	_apply_attack_steal(target_enemy)
	if is_instance_valid(target_enemy):
		target_enemy.take_damage(molly_damage)
		_show_popup(target_enemy.global_position + Vector2(0, -24), "+%d TAIL" % molly_fire_tail_stacks_applied, Color(0.9, 1.0, 0.35, 1.0), 16)

func _apply_attack_steal(target_enemy: Enemy):
	var bonus = int(target_enemy.stats.get("atk", 0) * attack_steal_ratio)
	if bonus <= 0:
		return
	
	if active_stolen_atk_bonus > 0:
		stats["atk"] -= active_stolen_atk_bonus
	
	active_stolen_atk_bonus = bonus
	stats["atk"] += active_stolen_atk_bonus
	attack_steal_version += 1
	var current_version = attack_steal_version
	_show_popup(global_position + Vector2(0, -46), "+%d ATK" % bonus, Color(0.92, 1.0, 0.4, 1.0), 18)
	atualizar_ui_vida()
	
	await get_tree().create_timer(attack_steal_duration).timeout
	if attack_steal_version == current_version:
		stats["atk"] -= active_stolen_atk_bonus
		active_stolen_atk_bonus = 0
		atualizar_ui_vida()

func _apply_exposure(target_enemy: Enemy, amount: int):
	var enemy_id = target_enemy.get_instance_id()
	var next_value = exposure_by_enemy.get(enemy_id, 0) + amount
	if next_value >= max_exposure_stacks:
		exposure_by_enemy[enemy_id] = 0
		_trigger_radioactive_combustion(target_enemy)
	else:
		exposure_by_enemy[enemy_id] = next_value
		_flash_exposure(target_enemy, float(next_value) / max_exposure_stacks)

func _trigger_radioactive_combustion(target_enemy: Enemy):
	if not is_instance_valid(target_enemy):
		return
	
	var enemy_id = target_enemy.get_instance_id()
	var version = burn_versions.get(enemy_id, 0) + 1
	burn_versions[enemy_id] = version
	_show_popup(target_enemy.global_position + Vector2(0, -52), "COMBUSTION", Color(0.96, 1.0, 0.42, 1.0), 22)
	await _show_burst_ring(target_enemy.global_position, 56.0)
	
	var total_damage = max(1, int(stats["PH"] * 1.2))
	var ticks = max(1, radioactive_burn_ticks)
	var tick_damage = max(1, int(ceil(float(total_damage) / ticks)))
	var tick_delay = radioactive_burn_duration / ticks
	
	for _tick in range(ticks):
		if not is_instance_valid(target_enemy):
			break
		if burn_versions.get(enemy_id, -1) != version:
			break
		
		target_enemy.modulate = Color(0.86, 1.0, 0.18, 1.0)
		target_enemy.take_damage(tick_damage)
		_show_popup(target_enemy.global_position + Vector2(randf_range(-10, 10), -28), str(tick_damage), Color(0.8, 1.0, 0.15, 1.0), 17)
		await get_tree().create_timer(tick_delay).timeout
		if is_instance_valid(target_enemy) and not target_enemy.is_stunned:
			target_enemy.modulate = Color.WHITE

func _flash_exposure(target_enemy: Enemy, ratio: float):
	if not is_instance_valid(target_enemy):
		return
	var flash_strength = lerp(0.18, 0.7, ratio)
	target_enemy.modulate = Color(0.7 + flash_strength * 0.2, 1.0, 0.18, 1.0)
	var marker = Line2D.new()
	marker.width = 5.0
	marker.default_color = Color(0.85, 1.0, 0.2, 0.9)
	marker.add_point(Vector2(-14, -36))
	marker.add_point(Vector2(-14 + 28.0 * ratio, -36))
	target_enemy.add_child(marker)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(marker):
		marker.queue_free()
	if is_instance_valid(target_enemy) and not target_enemy.is_stunned:
		target_enemy.modulate = Color.WHITE

func _add_fire_tail(target_enemy: Enemy, amount: int):
	var enemy_id = target_enemy.get_instance_id()
	fire_tail_by_enemy[enemy_id] = fire_tail_by_enemy.get(enemy_id, 0) + amount

func _cleanup_tracked_targets():
	for enemy_id in exposure_by_enemy.keys().duplicate():
		if not is_instance_id_valid(enemy_id):
			exposure_by_enemy.erase(enemy_id)
			fire_tail_by_enemy.erase(enemy_id)
			burn_versions.erase(enemy_id)

func _get_enemy_near_mouse(max_range: float, pick_radius: float) -> Enemy:
	var mouse_position = get_global_mouse_position()
	var best_enemy: Enemy = null
	var best_distance := INF
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > max_range:
			continue
		
		var mouse_distance = mouse_position.distance_to(enemy.global_position)
		if mouse_distance <= pick_radius and mouse_distance < best_distance:
			best_distance = mouse_distance
			best_enemy = enemy
	
	return best_enemy

func _show_popup(world_position: Vector2, text_value: String, color: Color, font_size: int = 18):
	var label = Label.new()
	label.text = text_value
	label.global_position = world_position
	label.z_index = 50
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = font_size
	label.label_settings.font_color = color
	label.label_settings.outline_size = 4
	label.label_settings.outline_color = Color(0.08, 0.16, 0.02, 0.9)
	get_tree().current_scene.add_child(label)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", world_position + Vector2(0, -26), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)

func _show_attack_line(target_position: Vector2, color: Color, width: float):
	var line = Line2D.new()
	line.width = width * 100.0
	line.default_color = color
	line.add_point(Vector2.ZERO)
	line.add_point(target_position - global_position)
	add_child(line)
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(line):
		line.queue_free()

func _show_burst_ring(world_position: Vector2, radius: float):
	var ring = Line2D.new()
	ring.width = 7.0
	ring.default_color = Color(0.88, 1.0, 0.25, 0.95)
	var points = PackedVector2Array()
	for i in range(33):
		var angle = float(i) / 32.0 * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	ring.global_position = world_position
	get_tree().current_scene.add_child(ring)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.35, 1.35), 0.18)
	tween.tween_property(ring, "modulate:a", 0.0, 0.18)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)
	await tween.finished
