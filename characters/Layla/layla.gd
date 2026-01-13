extends ClassPlayer

func _ready():
	super._ready() # Chama a mãe para configurar vida, UI e Stats

func _physics_process(delta):
	# 1. MOVIMENTO E DASH
	# A função 'super(delta)' chama a mãe.
	# Ela vai ler o teclado (WASD), aplicar a velocidade (stats["speed"])
	# e verificar o Dash padrão (stats["dash_speed"]).
	super(delta)
	
	# Se o personagem não estiver ativo, paramos por aqui para não processar inputs de ataque/cheats
	if not is_active: 
		return

	# 2. CHEATS E TESTES
	if Input.is_key_pressed(KEY_K):
		take_damage(10)
		
	# 3. FUTUROS ATAQUES
	# Quando você criar o ataque do arqueiro/mago, coloque aqui:
	# if Input.is_action_just_pressed("ataque"):
	#     atirar_flecha()
