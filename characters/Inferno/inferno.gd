extends ClassPlayer

# --- PASSIVA: COLETA DE ALMAS ---
var almas_atuais: int = 0
var max_almas: int = 40
var bonus_atk_por_alma: float = 0.05 
var bonus_shield_por_alma: int = 2

# Variável nova para guardar o valor original do escudo (ex: 50)
var max_shield_base_original: int = 0 

# PRELOAD DA BOLA DE FOGO
const FIREBALL_SCENE = preload("res://characters/Inferno/skills/bola de fogo.tscn") 

func _ready():
	# 1. Antes de qualquer coisa, salvamos quanto era o escudo original configurado no Inspector
	max_shield_base_original = max_shield 
	
	super._ready()
	
	almas_atuais = 0
	atualizar_passiva_stats()

func _physics_process(delta):
	super(delta) 

	if not is_active: return
	
	if Input.is_key_pressed(KEY_K):
		take_damage(10)

# --- SKILL 1 (Bola de Fogo) ---
func execute_skill_1_logic():
	if not is_active: return

	# Usa o stats["atk"] atualizado pela passiva
	var dano_explosao = int(stats["atk"] * 1.7)  
	var cura_zona = int(stats["atk"] * 0.10)     
	var dano_zona = int(stats["atk"] * 0.25)     
	
	var pacote_de_dano = calculate_damage(dano_explosao, "")
	pacote_de_dano["cura_valor"] = cura_zona
	pacote_de_dano["dano_zona_valor"] = dano_zona 
	
	if FIREBALL_SCENE:
		var fireball = FIREBALL_SCENE.instantiate()
		fireball.global_position = global_position
		var mouse_pos = get_global_mouse_position()
		var direcao_tiro = global_position.direction_to(mouse_pos)
		fireball.setup(direcao_tiro, pacote_de_dano, self)
		get_tree().current_scene.add_child(fireball)

# --- SISTEMA DE ALMAS ---

func receber_alma():
	# 1. Cura 2% da Vida Máxima
	var cura_passiva = int(max_health * 0.02)
	heal(cura_passiva)
	
	# 2. Adiciona Acúmulo
	if almas_atuais < max_almas:
		almas_atuais += 1
		atualizar_passiva_stats()
		print("Alma Coletada! Total: ", almas_atuais, " | ATK Atual: ", stats["atk"])
		
		# print("Alma +1! Total: ", almas_atuais, " | Novo Max Shield: ", max_shield)

func atualizar_passiva_stats():
	# --- CÁLCULO DO ATAQUE ---
	# base_atk é fixo na ClassPlayer, seguro usar direto
	var bonus_atk = int(base_atk * (bonus_atk_por_alma * almas_atuais))
	stats["atk"] = base_atk + bonus_atk
	
	# --- CÁLCULO DO ESCUDO (A CORREÇÃO) ---
	# Usamos a variável que criamos 'max_shield_base_original' (50) para calcular
	var bonus_shield = bonus_shield_por_alma * almas_atuais
	var novo_maximo = max_shield_base_original + bonus_shield
	
	# 1. Atualiza o dicionário (para consultas de stats)
	stats["max_shield"] = novo_maximo
	
	# 2. Atualiza a variável DA MÃE (para a regeneração funcionar até o novo teto)
	max_shield = novo_maximo
	
	# 3. Força a UI a redesenhar os números na tela
	actualizar_ui_vida()
