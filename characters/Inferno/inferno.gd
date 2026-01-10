extends ClassPlayer

# Variável de controle de troca de personagem (que já estava no seu código)
var is_active = false
@onready var camera = $Camera2D

# PRELOAD DA BOLA DE FOGO
# Ajuste o caminho abaixo para onde você salvou a cena da bola de fogo!
const FIREBALL_SCENE = preload("res://characters/Inferno/skills/bola de fogo.tscn") 

func _ready():
	super._ready() # Chama o _ready do pai (ClassPlayer) para configurar vida, etc.

func _physics_process(delta):
	if not is_active:
		return
		
	var direction = Input.get_vector("esquerda", "direita", "cima", "baixo")
	
	if Input.is_key_pressed(KEY_K):
		take_damage(10)

	# 1. Gatilho do Dash
	if Input.is_action_just_pressed("dash") and current_dashes > 0 and direction != Vector2.ZERO:
		start_dash(direction) # Passamos a direção para o dash
	
	# 2. Movimentação Normal (Só acontece se NÃO estiver em dash)
	if not is_dashing:
		if direction:
			velocity = direction * speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed)
	
	move_and_slide()

# --- AQUI ESTÁ A MÁGICA DA SKILL 1 ---
# Essa função é chamada automaticamente pelo ClassPlayer quando aperta "E"
func execute_skill_1_logic():
	# Verifica se o personagem está ativo antes de soltar a skill
	if not is_active:
		return

	# Instancia a bola de fogo
	var fireball = FIREBALL_SCENE.instantiate()
	
	# Define onde ela nasce (na posição do Inferno)
	fireball.global_position = global_position
	
	# Faz a bola olhar para o mouse
	fireball.look_at(get_global_mouse_position())
	
	# Adiciona na cena principal (não como filho do player, senão ela gira junto com ele)
	get_tree().current_scene.add_child(fireball)
	
	print("Inferno lançou Bola de Fogo!")

# --- Controle de Ativação do Personagem ---
func set_active(state: bool):
	is_active = state
	camera.enabled = state
	if state:
		camera.make_current()
		
		
func start_dash(dir: Vector2):
	current_dashes -= 1
	is_dashing = true
	
	# Aplica a velocidade alta do dash
	velocity = dir * dash_speed
	
	# Inicia o cooldown para recuperar o dash
	recharge_one_dash() 
	
	# Espera o tempo de duração do dash
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	# Opcional: Reduzir a velocidade bruscamente após o dash para não "deslizar"
	velocity = dir * speed
