extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 280.0
var damage: int = 9
var lifetime: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func setup(new_direction: Vector2, new_speed: float, new_damage: int, new_lifetime: float) -> void:
	direction = new_direction.normalized()
	speed = new_speed
	damage = new_damage
	lifetime = new_lifetime
	rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	queue_free()
