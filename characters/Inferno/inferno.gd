extends CharacterBody2D
#variaveis de configuração
var is_active = false
@onready var camera = $Camera2D
@export var speed = 400.0
@export var dash_speed = 1000
@export var dash_duration = 0.2
@export var dash_cooldown = 1.5
@export var max_dashes: int = 1
@export var max_health: int = 100
#variaveis de controle (lógica interna)

var current_dashes = 0
var is_dashing = false
var current_health : int = 0

func _ready():
	current_dashes = max_dashes
	current_health = max_health

func _physics_process(delta):
	if not is_active:
		return
	var direction = Input.get_vector("esquerda", "direita", "cima", "baixo")
	
	if Input.is_action_just_pressed("dash") and current_dashes > 0 and direction != Vector2.ZERO:
		start_dash() 
		
	if Input.is_key_pressed(KEY_K):
		take_damage(10) # Tira 10 de vida por frame (cuidado, morre rápido!)
		
	var current_speed = speed
	if is_dashing:
		current_speed = dash_speed
	

	if direction:
		# Use 'current_speed' aqui, e não 'speed'
		velocity = direction * current_speed 
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	
	move_and_slide()
func start_dash():
	current_dashes -= 1
	is_dashing = true
	print("Dash usado! Cargas restantes: ", current_dashes) # Olha o Console (Output) pra ver funcionando
	
	#await get_tree().create_timer(1.0).timeout #era a criação de cooldown no dash diretamente
	recharge_one_dash()
	
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
func recharge_one_dash():
	# Espera o tempo de recarga (1.0s)
	await get_tree().create_timer(dash_cooldown).timeout
	if current_dashes < max_dashes:
		current_dashes += 1
		print("Recarregou! Cargas atuais: ", current_dashes)
		
func take_damage(amount: int):
	current_health -= amount
	print("Ai! Levou ", amount, " de dano. Vida atual: ", current_health)
	if current_health <= 0:
		die()
func heal(amount:int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
func die():
	print("MORREU! X_X")
	# Por enquanto, vamos reiniciar a fase pra não travar o jogo
	get_tree().reload_current_scene()
func set_active(state: bool):
	is_active = state
	camera.enabled = state # Liga ou desliga a câmera deste personagem

	if state == true:
		camera.make_current() # Garante que essa é a câmera principal
