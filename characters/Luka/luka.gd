extends ClassPlayer

# --- Variaveis Específicas do Luka ---
var is_active = false
@onready var camera = $Camera2D

# Variável única da mecânica do Luka
var saved_dash_direction : Vector2 = Vector2.ZERO 

# NOTA: Removemos speed, dash_speed, health, etc. Tudo vem do Pai agora!

func _ready():
	super._ready() # Chama o pai para configurar vida e dashes

func _physics_process(delta):
	if not is_active:
		return

	# --- MECÂNICA ÚNICA DO LUKA: DASH TRAVADO ---
	if is_dashing:
		velocity = saved_dash_direction * dash_speed
		move_and_slide()
		
		# Verifica colisão (Exclusivo do Luka)
		if get_slide_collision_count() > 0:
			detectar_impacto()
		return 
	
	# --- MOVIMENTAÇÃO NORMAL ---
	var direction = Input.get_vector("esquerda", "direita", "cima", "baixo")
	
	if Input.is_key_pressed(KEY_K):
		take_damage(10)

	if Input.is_action_just_pressed("dash") and current_dashes > 0 and direction != Vector2.ZERO:
		start_dash(direction) 
	
	if direction:
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	
	move_and_slide()

# --- FUNÇÕES EXCLUSIVAS DO LUKA ---

func detectar_impacto():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is TileMap or collider is StaticBody2D or collider.is_in_group("enemies"):
			print("Luka: BATIDA! Parei o dash.")
			cancelar_dash()
			break 

func cancelar_dash():
	is_dashing = false
	velocity = Vector2.ZERO 

func start_dash(direction_to_lock: Vector2):
	current_dashes -= 1
	is_dashing = true
	saved_dash_direction = direction_to_lock # Trava direção
	
	print("Luka: TRATOR LIGADO!")
	
	recharge_one_dash() # Chama a função do Pai
	
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false 
	velocity = Vector2.ZERO

func set_active(state: bool):
	is_active = state
	camera.enabled = state
	if state == true:
		camera.make_current()
