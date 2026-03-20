extends Area2D

var source_player: ClassPlayer = null
var source_weapon: ClassWeapon = null
var direction: Vector2 = Vector2.RIGHT
var speed: float = 900.0
var hit_data: Dictionary = {}
var lifetime: float = 0.9

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func setup(new_source_player: ClassPlayer, new_source_weapon: ClassWeapon, new_direction: Vector2, new_speed: float, new_hit_data: Dictionary, new_lifetime: float, tint: Color, scale_factor: float) -> void:
	source_player = new_source_player
	source_weapon = new_source_weapon
	direction = new_direction.normalized()
	speed = new_speed
	hit_data = new_hit_data
	lifetime = new_lifetime
	rotation = direction.angle()
	modulate = tint
	scale = Vector2.ONE * scale_factor

func _on_body_entered(body: Node) -> void:
	if body == source_player:
		return
	if body.is_in_group("players"):
		return
	if body.has_method("take_damage"):
		body.take_damage(int(hit_data.get("value", 0)))
		if source_player != null and source_player.has_method("on_weapon_hit_enemy") and body is Enemy:
			source_player.on_weapon_hit_enemy(body, hit_data, source_weapon)
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	queue_free()
