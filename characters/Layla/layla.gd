extends ClassPlayer

# --- CONFIGURAÇÕES ---
@export_group("Skill 1: Flecha de Gelo")
@export var arrow_scene: PackedScene # Arraste o Arrow.tscn aqui!
@export var tempo_maximo_carga: float = 2.0
@export var alcance_minimo: float = 150.0
@export var alcance_maximo: float = 600.0

# --- ESTADOS INTERNOS ---
var tempo_carregando: float = 0.0
var carregando_tiro: bool = false

# Referências
@onready var aim_line = $Line2D

func _ready():
	super._ready()
	
	# Configurações iniciais da Layla
	speed = 180 # Ela pode ser um pouco mais rápida que o Inferno
	max_health = 40 # Mas tem menos vida
	current_health = max_health
	
	aim_line.visible = false

func _physics_process(delta):
	# Se não for o personagem ativo, esconde a mira e não processa input
	if not is_active:
		aim_line.visible = false
		super(delta)
		return

	# --- LÓGICA DA SKILL 1 (SEGURAR) ---
	if Input.is_action_pressed("skill_1"): # Botão Direito ou Q
		preparar_flecha(delta)
	
	elif Input.is_action_just_released("skill_1"):
		disparar()
	
	else:
		# Se não está apertando nada, reseta o estado
		carregando_tiro = false
		aim_line.visible = false
		tempo_carregando = 0.0
	
	# Chama a física da mãe (movimento, dash, regeneração)
	super(delta)

# --- FUNÇÃO DE MIRA ---
func preparar_flecha(delta):
	carregando_tiro = true
	aim_line.visible = true
	
	# 1. Carrega o tiro (0 -> 1.5s)
	tempo_carregando = min(tempo_carregando + delta, tempo_maximo_carga)
	
	# 2. Penalidade de Movimento (Layla anda 60% mais devagar mirando)
	velocity *= 0.4 
	
	# 3. Desenha a linha de mira
	var mouse_local = get_local_mouse_position()
	var direcao = mouse_local.normalized()
	
	# Calcula o tamanho da linha baseado na carga (Lerp)
	var porcentagem = tempo_carregando / tempo_maximo_carga
	var comprimento = lerp(alcance_minimo, alcance_maximo, porcentagem)
	
	# Atualiza o Line2D
	aim_line.set_point_position(0, Vector2.ZERO)
	aim_line.set_point_position(1, direcao * comprimento)

# --- FUNÇÃO DE DISPARO ---
func disparar():
	if not arrow_scene:
		print("ERRO: Cena da flecha não atribuída na Layla!")
		return
		
	var flecha = arrow_scene.instantiate()
	flecha.global_position = global_position
	
	var mouse_pos = get_global_mouse_position()
	var direcao = global_position.direction_to(mouse_pos)
	
	# Define se é tiro fraco (Tap) ou forte (Hold)
	# Vamos dizer que precisa carregar pelo menos 30% para ser considerado "Forte"
	var porcentagem_carga = tempo_carregando / tempo_maximo_carga
	
	if porcentagem_carga < 0.3:
		# --- TIRO RÁPIDO (POKE) ---
		var dano = int(stats["atk"] * 0.8 + 20) # 80% do ATK
		var dados = {"damage": dano}
		
		# Flecha normal, mas aplica slow
		flecha.setup(direcao, dados, self, false, true)
		
	else:
		# --- TIRO CARREGADO (SNIPER) ---
		# Dano escala de 100% até 250% do ATK dependendo da carga
		var multiplicador = lerp(1.0, 2.5, porcentagem_carga)
		var dano = int(stats["atk"] * multiplicador)
		
		# Chance de Crítico Aumentada (+50% chance se estiver full charge)
		if porcentagem_carga >= 0.9:
			var chance_bonus = 0.5
			if randf() < (base_crit_chance + chance_bonus):
				dano = int(dano * base_crit_damage)
				flecha.modulate = Color(1.5, 1.5, 0, 1) # Brilha amarelo
		
		var dados = {"damage": dano}
		
		# Flecha perfurante, sem slow
		flecha.setup(direcao, dados, self, true, false)

	get_tree().current_scene.add_child(flecha)
	
	# Limpeza
	aim_line.visible = false
	carregando_tiro = false
	tempo_carregando = 0.0
