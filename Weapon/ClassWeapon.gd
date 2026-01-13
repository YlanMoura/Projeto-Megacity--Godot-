class_name classWeapon
extends Node2D

@export var weapon_name := "Weapon"
@export var damage := 10
@export var cooldown := 0.3
@export var energy_cost := 0

var user: Node

var can_use := true

func setup(p_user):
	user = p_user

func use(direction: Vector2):
	if not can_use:
		return

	execute(direction)
	can_use = false
	await get_tree().create_timer(cooldown).timeout
	can_use = true

# método para sobrescrever
func execute(direction: Vector2):
	pass
