extends ClassPlayer

# --- Configurações Específicas do Skye ---
@export var shadow_scene : PackedScene
var is_active = false
@onready var camera = $Camera2D

# Variáveis de ataque
@onready var attack_area = $AreaAtaque 
@onready var attack_visual = $AreaAtaque/Polygon2D
var is_attacking = false

# NOTA: Removemos speed, dash_speed, health, etc. Tudo vem do Pai agora!

func _ready():
	super._ready() # Chama o pai para configurar vida e dashes
	
	if attack_visual: attack_visual.visible = false
	if attack_area: attack_area.monitoring = false

func _physics_process(delta):
	if not is_active:
		return
	
	# Fallback de segurança se speed vier zerado do inspector
	if speed == 0: speed = 600.0

	var direction = Input.get_vector("esquerda", "direita", "cima", "baixo")
	
	if Input.is_action_just_pressed("dash") and current_dashes > 0 and direction != Vector2.ZERO:
		start_dash() 
	
	if Input.is_action_just_pressed("ataque") and not is_attacking:
		attack()

	if Input.is_key_pressed(KEY_K):
		take_damage(10) 
		
	var current_speed = speed
	if is_dashing:
		current_speed = dash_speed

	if direction:
		velocity = direction * current_speed
		if direction.x > 0: transform.x.x = 1
		elif direction.x < 0: transform.x.x = -1
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	
	move_and_slide()

# --- MECÂNICA ÚNICA DO SKYE: DASH FANTASMA ---
func start_dash():
	var start_pos = global_position
	
	# Salva a máscara original (que bate em Paredes, Paredes Finas e Inimigos)
	var old_mask = collision_mask 
	
	# --- A MUDANÇA ---
	# Durante o dash, colida APENAS com a Layer 1 (Cenario/Borda).
	# Ignora Layer 3 (Inimigos) e Layer 4 (Parede Fina).
	collision_mask = 1 
	
	current_dashes -= 1
	spawn_shadow_delayed(start_pos)
	is_dashing = true
	
	recharge_one_dash() 
	
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	
	# Volta a bater em tudo (Borda, Parede Fina e Inimigos)
	collision_mask = old_mask

func attack():
	if is_attacking: return
	is_attacking = true
	
	if attack_visual: attack_visual.visible = true
	if attack_area: attack_area.monitoring = true
	
	await get_tree().process_frame
	await get_tree().process_frame 
	
	if attack_area:
		var bodies = attack_area.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("take_damage") and body != self:
				body.take_damage(25)
	
	await get_tree().create_timer(0.3).timeout
	
	if attack_visual: attack_visual.visible = false
	if attack_area: attack_area.monitoring = false
	is_attacking = false

func set_active(state: bool):
	is_active = state
	camera.enabled = state 
	if state == true:
		camera.make_current() 

func spawn_shadow_delayed(start_pos):
	await get_tree().create_timer(0.2).timeout 
	if shadow_scene == null: return
	var shadow = shadow_scene.instantiate()
	get_parent().add_child(shadow)
	shadow.global_position = start_pos
	shadow.target = self
