extends ClassPlayer

# --- CONFIGURAÇÕES DO BALPO ---
@export var pisao_scene: PackedScene

# --- VARIÁVEIS DA PASSIVA (FORTITUDE) ---
var tempo_sem_combate: float = 0.0
var acumulador_cura: float = 0.0 # <--- AQUI ESTÁ O SEGREDO (O BALDE)

# CONFIGURAÇÃO DE TEMPO
# 20s é muito tempo! Jogos rápidos usam 3s a 5s. Mudei para 4s pra testar.
const LIMITE_SEM_COMBATE: float = 4.0 
const TAXA_CONVERSAO: float = 10.0 # Aumentei pra 10 pra ser visível

func _ready():
	# Configura os status base do Balpo
	max_shield = 80
	current_shield = 0
	
	base_atk = 15 
	max_health = 150 
	
	super._ready()

func _physics_process(delta):
	if not is_active: return
	super(delta)
	
	# Lógica do "Timer de Combate"
	tempo_sem_combate += delta
	
	# Se passou do tempo E tem escudo pra gastar E não tá de vida cheia
	if tempo_sem_combate >= LIMITE_SEM_COMBATE and current_shield > 0 and current_health < max_health:
		_converter_tenacidade_em_vida(delta)
	elif current_shield > 0 and current_health >= max_health and tempo_sem_combate >= LIMITE_SEM_COMBATE:
		# OPCIONAL: Se a vida encheu, o resto do escudo deve sumir devagar ou ficar?
		# Aqui estou fazendo sumir devagar sem curar (degrade natural)
		current_shield -= TAXA_CONVERSAO * delta
		actualizar_ui_vida()

# --- SOBRESCREVENDO O ESCUDO DO PAI ---
func _processar_escudo(_delta):
	pass # Balpo não regenera escudo sozinho

# --- LÓGICA DA PASSIVA CORRIGIDA ---
func _converter_tenacidade_em_vida(delta):
	# 1. Acumula os "pingos" de tempo
	acumulador_cura += TAXA_CONVERSAO * delta
	
	# 2. Só executa quando encher pelo menos 1 ponto de vida inteiro
	if acumulador_cura >= 1.0:
		var valor_inteiro = int(acumulador_cura)
		
		# Não pode curar mais do que tem de escudo
		valor_inteiro = min(valor_inteiro, int(current_shield))
		
		if valor_inteiro > 0:
			# Tira do Escudo
			current_shield -= valor_inteiro
			
			# Põe na Vida (A função heal do pai cuida do limite max_hp)
			heal(valor_inteiro) 
			
			# Tira do acumulador o que já usamos
			acumulador_cura -= valor_inteiro
			
			actualizar_ui_vida()

# --- GATILHOS DE COMBATE ---
func take_damage(amount: int):
	tempo_sem_combate = 0.0 # Resetou!
	super.take_damage(amount)

func ganhar_tenacidade(quantidade: int):
	tempo_sem_combate = 0.0 # Resetou!
	current_shield += quantidade
	if current_shield > max_shield:
		current_shield = max_shield
	
	mostrar_texto_flutuante(quantidade, "escudo")
	actualizar_ui_vida()

# --- SKILL 1: PISÃO PESADO ---
func attempt_skill_1():
	if not can_use_skill_1 or is_dashing: return
	
	tempo_sem_combate = 0.0
	can_use_skill_1 = false
	
	# Dash
	var direcao = Vector2.RIGHT * transform.x.x
	velocity = direcao * 600 
	move_and_slide()
	
	await get_tree().create_timer(0.2).timeout
	velocity = Vector2.ZERO 
	
	# Spawn
	if pisao_scene:
		_spawnar_pisao()
	else:
		print("ERRO: Falta AreaPisao.tscn no Inspector!")
	
	# Cooldown
	await get_tree().create_timer(skill_1_cooldown).timeout
	can_use_skill_1 = true

func _spawnar_pisao():
	var pisao = pisao_scene.instantiate()
	
	# Cálculo de Dano
	var dano_base = 15
	var scale_atk = stats["atk"] * 0.40
	var scale_hp = stats["max_hp"] * 0.10
	var dano_total = int(dano_base + scale_atk + scale_hp)
	
	# Setup direto (Funciona bem pois _ready do pisao roda depois do add_child)
	pisao.caster = self            
	pisao.dano_calculado = dano_total 
	pisao.tenacidade_por_hit = 15 # Opcional: Definir quanto ganha aqui
	pisao.global_position = global_position
	
	get_tree().current_scene.add_child(pisao)

# --- UI: Cor Laranja ---
func set_active(state: bool):
	super.set_active(state)
	
	if state and hud_global:
		# Força atualização da UI ao trocar pro Balpo
		actualizar_ui_vida() 
		
		if "bar_shield" in hud_global:
			var stylebox = hud_global.bar_shield.get_theme_stylebox("fill").duplicate()
			stylebox.bg_color = Color(0.9, 0.5, 0.0) # Laranja Tenacidade
			hud_global.bar_shield.add_theme_stylebox_override("fill", stylebox)
