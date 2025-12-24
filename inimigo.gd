extends CharacterBody2D

@export var speed = 100 
@export var max_health: int = 50 

var current_health = 0
var target = null # antigo 'alvo'

func _ready():
	current_health = max_health

func _physics_process(delta):
	if target == null:
		return
	
	# Calcula a direção para o target
	var direction = global_position.direction_to(target.global_position)
	velocity = direction * speed
	move_and_slide()

# --- FUNÇÃO PADRONIZADA EM INGLÊS ---
func take_damage(amount: int):
	current_health -= amount
	print("Enemy took ", amount, " damage. HP: ", current_health)
	
	# Hit Flash (Piscada Vermelha)
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health

func die(): # antigo 'morrer'
	print("Enemy died!")
	queue_free()
