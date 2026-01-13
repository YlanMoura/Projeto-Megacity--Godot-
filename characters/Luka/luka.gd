extends ClassPlayer

# --- Variáveis Específicas do Luka ---
# is_active e camera já existem na mãe, removemos daqui para não duplicar!

# Variável única da mecânica do Luka
var saved_dash_direction : Vector2 = Vector2.ZERO 

func _ready():
	super._ready() # Configura vida, stats e UI da mãe

func _physics_process(delta):
	if not is_active:
		return

	# --- MECÂNICA ÚNICA: DASH TRAVADO (O "Trator") ---
	if is_dashing:
		# AQUI NÃO CHAMAMOS SUPER. O Luka ignora inputs enquanto corre.
		
		# Atualização: Usamos stats["dash_speed"] para buffs funcionarem no dash
		velocity = saved_dash_direction * stats["dash_speed"]
		move_and_slide()
		
		# Verifica colisão (Exclusivo do Luka)
		if get_slide_collision_count() > 0:
			detectar_impacto()
			
	else:
		# --- MOVIMENTAÇÃO NORMAL ---
		# Quando NÃO está no dash, deixamos a mãe controlar.
		# Ela vai ler WASD, aplicar stats["speed"] (com buffs) e checar se apertou Espaço.
		super(delta)
		
		# Inputs extras do Luka (como o cheat de dano)
		if Input.is_key_pressed(KEY_K):
			take_damage(10)

# --- SOBRESCRITA DO DASH (OVERRIDE) ---
# Quando a mãe (super) detectar o Input "dash", ela vai chamar esta função aqui
# porque o script do filho tem prioridade.
func start_dash(dir: Vector2):
	current_dashes -= 1
	is_dashing = true
	saved_dash_direction = dir # Trava a direção recebida
	
	print("Luka: TRATOR LIGADO!")
	
	recharge_one_dash() # Chama a função de recarga da mãe
	
	# Usa a duração que está nos stats
	await get_tree().create_timer(stats["dash_duration"]).timeout
	
	# Se o timer acabou e ele ainda está dando dash (não bateu), para ele.
	if is_dashing:
		cancelar_dash()

# --- FUNÇÕES EXCLUSIVAS DO LUKA ---

func detectar_impacto():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Verifica se bateu em parede ou inimigo
		if collider is TileMap or collider is StaticBody2D or collider.is_in_group("enemies"):
			print("Luka: BATIDA! Parei o dash.")
			
			# Opcional: Se quiser dar dano ao bater no inimigo com o corpo:
			# if collider.has_method("take_damage"):
			#    collider.take_damage(stats["atk"])
			
			cancelar_dash()
			break 

func cancelar_dash():
	is_dashing = false
	velocity = Vector2.ZERO 

# Removemos set_active() pois a mãe já faz isso perfeitamente.
