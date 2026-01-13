extends ClassPlayer

# --- Configurações Específicas do Skye ---
@export var shadow_scene : PackedScene

# Variáveis de ataque
@onready var attack_area = $AreaAtaque 
@onready var attack_visual = $AreaAtaque/Polygon2D
var is_attacking = false

func _ready():
	super._ready() # Chama o pai para configurar vida, stats e UI
	
	if attack_visual: attack_visual.visible = false
	if attack_area: attack_area.monitoring = false

func _physics_process(delta):
	# Se não estiver ativo, a mãe já trava. 
	# Mas precisamos verificar aqui para não rodar a lógica de virar o sprite
	if not is_active: return
	
	# 1. Movimentação Básica (WASD)
	# A mãe calcula velocity usando stats["speed"] (com buffs) e faz o move_and_slide()
	super(delta)
	
	# 2. Lógica Visual (Virar o sprite)
	# Como a mãe moveu o boneco, verificamos a velocity dela
	if velocity.x > 0:
		transform.x.x = 1 # Olha p/ direita
	elif velocity.x < 0:
		transform.x.x = -1 # Olha p/ esquerda

	# 3. Ataque
	if Input.is_action_just_pressed("ataque") and not is_attacking:
		attack()

	# 4. Cheat de Dano
	if Input.is_key_pressed(KEY_K):
		take_damage(10) 

# --- MECÂNICA ÚNICA: DASH FANTASMA (OVERRIDE) ---
# A mãe chama esta função quando aperta Espaço
func start_dash(dir: Vector2):
	var start_pos = global_position
	
	# Salva a máscara original
	var old_mask = collision_mask 
	
	# --- MODO FANTASMA ---
	# Colide apenas com Layer 1 (Cenario/Borda).
	collision_mask = 1 
	
	current_dashes -= 1
	is_dashing = true
	spawn_shadow_delayed(start_pos)
	
	# Aplica velocidade do dash usando os STATS (Buffs funcionam aqui!)
	velocity = dir * stats["dash_speed"]
	
	recharge_one_dash() # Chama mãe para recarregar
	
	# Usa duração do stats
	await get_tree().create_timer(stats["dash_duration"]).timeout
	
	is_dashing = false
	
	# Volta a bater em tudo (Borda, Parede Fina e Inimigos)
	collision_mask = old_mask
	# A velocidade volta ao normal automaticamente no próximo frame da mãe

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
			# Evita se bater (self)
			if body.has_method("take_damage") and body != self:
				# MUDANÇA: Agora o dano escala com o ATK do personagem!
				# Se ele pegar buff na zona de fogo, bate mais forte.
				body.take_damage(stats["atk"])
	
	await get_tree().create_timer(0.3).timeout
	
	if attack_visual: attack_visual.visible = false
	if attack_area: attack_area.monitoring = false
	is_attacking = false

func spawn_shadow_delayed(start_pos):
	await get_tree().create_timer(0.2).timeout 
	if shadow_scene == null: return
	
	var shadow = shadow_scene.instantiate()
	# Adiciona no pai do Skye (a cena principal) para a sombra não se mexer com ele
	get_parent().add_child(shadow)
	shadow.global_position = start_pos
	shadow.target = self

# Removemos set_active() pois a mãe já cuida disso.
