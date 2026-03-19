extends ZoneEffect

@export var impact_damage: int = 0
@export var tick_damage: int = 0
@export var radius: float = 96.0

var damaged_on_entry := {}

func _ready():
	_update_collision()
	queue_redraw()
	super._ready()

func setup(owner: Node2D, damage_on_impact: int, burn_tick_damage: int):
	caster = owner
	impact_damage = damage_on_impact
	tick_damage = burn_tick_damage

func _apply_effect(body):
	if body == caster:
		return
	if body.is_in_group("enemies") and not damaged_on_entry.has(body.get_instance_id()):
		damaged_on_entry[body.get_instance_id()] = true
		if body.has_method("take_damage"):
			body.modulate = Color(0.8, 1.0, 0.15, 1.0)
			body.take_damage(impact_damage)

func _remove_effect(body):
	if is_instance_valid(body) and body.is_in_group("enemies") and not body.is_stunned:
		body.modulate = Color.WHITE

func _tick_effect(body):
	if body == caster:
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.modulate = Color(0.75, 1.0, 0.1, 1.0)
		body.take_damage(tick_damage)

func _update_collision():
	var shape_node = get_node_or_null("CollisionShape2D")
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)
	var shape = CircleShape2D.new()
	shape.radius = radius
	shape_node.shape = shape

func _draw():
	draw_circle(Vector2.ZERO, radius, Color(0.72, 1.0, 0.08, 0.26))
	draw_circle(Vector2.ZERO, radius * 0.72, Color(0.85, 1.0, 0.2, 0.18))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(0.8, 1.0, 0.1, 0.92), 3.0)
	draw_arc(Vector2.ZERO, radius * 0.55, 0, TAU, 32, Color(0.95, 1.0, 0.45, 0.72), 2.0)
