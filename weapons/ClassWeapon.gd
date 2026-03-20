extends Node2D
class_name ClassWeapon

const PLAYER_PROJECTILE_SCENE = preload("res://weapons/projectiles/player_projectile.tscn")

@export_group("Identity")
@export var nome_arma: String = "Prototype Weapon"
@export var weapon_prop_scene: PackedScene
@export var hold_offset: Vector2 = Vector2(24, -10)
@export var weapon_tint: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var weapon_size: Vector2 = Vector2(26, 8)

@export_group("Stats")
@export var dano_base: float = 10.0
@export var cadencia_tiro: float = 0.2
@export var quantidade_pellets: int = 1
@export var dispersao: float = 0.05
@export var projectile_speed: float = 900.0
@export var projectile_lifetime: float = 0.9
@export var projectile_scale: float = 1.0

@export_group("Pickup")
@export var pickup_radius: float = 26.0

var player: ClassPlayer = null
var pode_atirar: bool = true
var is_equipped: bool = false
var pickup_area: Area2D = null
var pickup_shape: CollisionShape2D = null
var visual_root: Node2D = null

func _ready() -> void:
	_ensure_runtime_nodes()
	_refresh_visual()
	_set_pickup_enabled(true)

func _physics_process(_delta: float) -> void:
	if is_equipped:
		if player == null or not is_instance_valid(player):
			queue_free()
			return
		_update_held_transform()
		if player.is_active and Input.is_action_pressed("ataque"):
			tentar_atirar()

func tentar_atirar() -> void:
	if not is_equipped:
		return
	if player == null or not is_instance_valid(player):
		return
	if not pode_atirar:
		return
	disparar()

func disparar() -> void:
	pode_atirar = false
	var base_direction: Vector2 = player.get_weapon_aim_direction()

	for _pellet in range(quantidade_pellets):
		var resultado: Dictionary = player.calculate_damage(dano_base, "atk")
		var final_direction: Vector2 = base_direction.rotated(randf_range(-dispersao, dispersao))
		criar_projetil(final_direction, resultado)

	await get_tree().create_timer(cadencia_tiro).timeout
	pode_atirar = true

func criar_projetil(direcao: Vector2, dados_dano: Dictionary) -> void:
	if PLAYER_PROJECTILE_SCENE == null:
		return

	var projectile = PLAYER_PROJECTILE_SCENE.instantiate()
	projectile.global_position = global_position + direcao.normalized() * 12.0
	projectile.setup(player, self, direcao, projectile_speed, dados_dano, projectile_lifetime, weapon_tint, projectile_scale)
	get_tree().current_scene.add_child(projectile)

func equip_to(new_player: ClassPlayer) -> void:
	if new_player == null:
		return
	player = new_player
	is_equipped = true
	top_level = true
	z_index = 40
	_set_pickup_enabled(false)
	_update_held_transform()

func _update_held_transform() -> void:
	var aim_direction: Vector2 = player.get_weapon_aim_direction()
	var side: float = 1.0 if aim_direction.x >= 0.0 else -1.0
	global_position = player.global_position + Vector2(hold_offset.x * side, hold_offset.y)
	rotation = aim_direction.angle()
	if visual_root != null:
		visual_root.scale = Vector2(1.0, side)

func _ensure_runtime_nodes() -> void:
	visual_root = get_node_or_null("WeaponVisualRoot")
	if visual_root == null:
		visual_root = Node2D.new()
		visual_root.name = "WeaponVisualRoot"
		add_child(visual_root)

	pickup_area = get_node_or_null("PickupArea")
	if pickup_area == null:
		pickup_area = Area2D.new()
		pickup_area.name = "PickupArea"
		pickup_area.monitoring = true
		pickup_area.monitorable = true
		pickup_area.collision_layer = 16
		pickup_area.collision_mask = 2
		add_child(pickup_area)
		pickup_area.body_entered.connect(_on_pickup_body_entered)
	elif not pickup_area.body_entered.is_connected(_on_pickup_body_entered):
		pickup_area.body_entered.connect(_on_pickup_body_entered)

	pickup_shape = pickup_area.get_node_or_null("CollisionShape2D")
	if pickup_shape == null:
		pickup_shape = CollisionShape2D.new()
		pickup_shape.name = "CollisionShape2D"
		pickup_area.add_child(pickup_shape)

	var shape := CircleShape2D.new()
	shape.radius = pickup_radius
	pickup_shape.shape = shape

func _refresh_visual() -> void:
	for child in visual_root.get_children():
		child.queue_free()

	if weapon_prop_scene != null:
		var prop = weapon_prop_scene.instantiate()
		visual_root.add_child(prop)
		return

	var polygon := Polygon2D.new()
	polygon.color = weapon_tint
	polygon.polygon = PackedVector2Array([
		Vector2(-weapon_size.x * 0.25, -weapon_size.y * 0.5),
		Vector2(weapon_size.x * 0.75, -weapon_size.y * 0.5),
		Vector2(weapon_size.x * 0.75, weapon_size.y * 0.5),
		Vector2(-weapon_size.x * 0.25, weapon_size.y * 0.5),
	])
	visual_root.add_child(polygon)

	var muzzle := Polygon2D.new()
	muzzle.color = weapon_tint.lightened(0.15)
	muzzle.position = Vector2(weapon_size.x * 0.65, 0)
	muzzle.polygon = PackedVector2Array([
		Vector2(0, -weapon_size.y * 0.35),
		Vector2(weapon_size.x * 0.35, -weapon_size.y * 0.22),
		Vector2(weapon_size.x * 0.35, weapon_size.y * 0.22),
		Vector2(0, weapon_size.y * 0.35),
	])
	visual_root.add_child(muzzle)

func _set_pickup_enabled(enabled: bool) -> void:
	if pickup_area == null:
		return
	pickup_area.monitoring = enabled
	pickup_area.monitorable = enabled
	pickup_area.visible = false
	if pickup_shape != null:
		pickup_shape.disabled = not enabled

func _on_pickup_body_entered(body: Node) -> void:
	if is_equipped:
		return
	if body is ClassPlayer:
		body.equip_weapon(self)
