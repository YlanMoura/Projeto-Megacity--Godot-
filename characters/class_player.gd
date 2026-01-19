class_name ClassPlayer extends CharacterBody2D

# --- STATUS GERAIS ---
@export_group("Identidade")
@export var nome_personagem: String = "Personagem"
@export var retrato: Texture2D # Arraste a foto aqui no Inspetor

@export_group("Status")
@export var max_health: int = 100
var current_health: int

# --- CONTROLE DE TROCA ---
# Define se o jogador está controlando este boneco agora
var is_active: bool = false 
@onready var camera = $Camera2D # Certifique-se que o Player tem uma Camera2D ou trate o erro

# Referência para o HUD Global
var hud_global = null

# --- ESCUDO (SHIELD) ---
@export_group("Escudo")
@export var max_shield: int = 50
@export var shield_regen_delay: float = 3.0
@export var shield_regen_rate: float = 10.0
var current_shield: int
var regen_timer: float = 0.0
var regen_accumulator: float = 0.0

# --- MOVIMENTO E DASH ---
@export_group("Movimento")
@export var speed: float = 400.0 # Valor base

@export_group("Dash")
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.5
@export var max_dashes: int = 1
var current_dashes: int = 0
var is_dashing: bool = false 

# --- ATAQUE E ATRIBUTOS ---
@export_group("Atributos de Combate")
@export var base_atk: int = 20
@export var base_ph: int = 20
@export var base_crit_chance: float = 0.1
@export var base_crit_damage: float = 1.5

# --- HABILIDADES ---
@export_group("Habilidades")
@export var skill_1_cooldown: float = 3.0
var can_use_skill_1: bool = true

# --- SISTEMA INTERNO ---
var stats = {}
var buff_timers = {}
const FLOATING_NUMBER_SCENE = preload("res://UI/floating_number.tscn")

func _ready():
	add_to_group("players")
	current_health = max_health
	current_shield = max_shield 
	current_dashes = max_dashes
	
	set_collision_mask_value(1, true)
	set_collision_mask_value(4, true)
	set_collision_mask_value(3, true)
	
	# --- CONEXÃO COM HUD ---
	# Procura o HUD na cena principal (assumindo que o nome do nó é "Hud" ou "HUD")
	hud_global = get_tree().current_scene.find_child("HUD", true, false)
	if not hud_global:
		hud_global = get_tree().current_scene.find_child("Hud", true, false)
	
	# Monta o dicionário. AQUI É A CHAVE DE TUDO.
	stats = {
		"max_hp": max_health,
		"max_shield": max_shield,
		"speed": speed,        # <--- O jogo vai ler DAQUI
		
		"dash_speed": dash_speed,
		"dash_duration": dash_duration,
		"dash_cooldown": dash_cooldown,
		"max_dashes": max_dashes,
		
		"atk": base_atk,
		"PH": base_ph,
		"crit_chance": base_crit_chance,
		"crit_damage": base_crit_damage,
		"skill_1_cooldown": skill_1_cooldown
	}
	
	# Se já nascer ativo, conecta
	if is_active:
		set_active(true)

# --- MOVIMENTAÇÃO CENTRALIZADA (A Mágica Acontece Aqui) ---
func _physics_process(delta: float) -> void:
	# Lógica do Escudo
	_processar_escudo(delta)
	
	# Se não estiver ativo, não anda
	if not is_active:
		return

	var direction = Input.get_vector("esquerda", "direita", "cima", "baixo")

	# 1. Gatilho do Dash
	if Input.is_action_just_pressed("dash") and current_dashes > 0 and direction != Vector2.ZERO:
		start_dash(direction)
	
	# 2. Movimentação Normal
	if not is_dashing:
		if direction:
			velocity = direction * stats["speed"]
			
			# --- NOVA LÓGICA DE VIRAR O SPRITE ---
			# Como está no PAI, todos os filhos herdam isso!
			if velocity.x > 0:
				transform.x.x = 1 # Olha p/ direita
			elif velocity.x < 0:
				transform.x.x = -1 # Olha p/ esquerda
				
		else:
			velocity = velocity.move_toward(Vector2.ZERO, stats["speed"])
	
	move_and_slide()

# Separei a lógica do escudo para ficar organizado
func _processar_escudo(delta):
	if regen_timer > 0:
		regen_timer -= delta
	elif current_shield < max_shield:
		regen_accumulator += shield_regen_rate * delta
		if regen_accumulator >= 1.0:
			var amount = int(regen_accumulator)
			regen_accumulator -= amount 
			current_shield += amount
			if current_shield > max_shield: current_shield = max_shield
			# Não precisamos chamar ui update aqui toda hora se o HUD já faz no _process
			# Mas mantemos caso queira forçar
			actualizar_ui_vida()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active: return
	
	if event.is_action_pressed("skill1") and can_use_skill_1:
		attempt_skill_1()

# --- FUNÇÕES DE DASH ---

func start_dash(dir: Vector2):
	current_dashes -= 1
	is_dashing = true
	
	velocity = dir * stats["dash_speed"]
	
	recharge_one_dash() 
	
	await get_tree().create_timer(stats["dash_duration"]).timeout
	is_dashing = false

func recharge_one_dash():
	await get_tree().create_timer(stats["dash_cooldown"]).timeout
	if current_dashes < max_dashes:
		current_dashes += 1

# --- FUNÇÕES DE CONTROLE ---
func set_active(state: bool):
	is_active = state
	
	# Controle da Câmera
	if has_node("Camera2D"):
		$Camera2D.enabled = state
		if state: $Camera2D.make_current()
		
	# Controle do HUD
	if state and hud_global:
		if hud_global.has_method("conectar_no_player"):
			hud_global.conectar_no_player(self)

# --- COMBATE E DANO ---

func take_damage(amount: int):
	regen_timer = shield_regen_delay
	regen_accumulator = 0.0 
	
	if current_shield > 0:
		var damage_to_shield = min(current_shield, amount)
		current_shield -= damage_to_shield
		amount -= damage_to_shield 
		mostrar_texto_flutuante(damage_to_shield, "escudo")
	
	if amount > 0:
		current_health -= amount
		mostrar_texto_flutuante(amount, "dano")
	
	actualizar_ui_vida()
	if current_health <= 0: die()

func calculate_damage(base_dmg: float, scaling_stat: String) -> Dictionary:
	var stat_val = 0
	if scaling_stat != "":
		stat_val = stats.get(scaling_stat, 0)
		
	var final_dmg = base_dmg + stat_val
	var is_crit = false
	
	if randf() <= stats["crit_chance"]:
		final_dmg *= stats["crit_damage"]
		is_crit = true
		
	return {"value": int(final_dmg), "critical": is_crit}

func heal(amount: int):
	current_health += amount
	if current_health > max_health: current_health = max_health
	actualizar_ui_vida()
	mostrar_texto_flutuante(amount, "cura")

# --- UI E EFEITOS ---
func actualizar_ui_vida():
	# Agora apenas manda um sinal para o HUD Global, se necessário
	# Nota: Como seu HUD novo usa _process, isso aqui é mais para garantir atualização instantânea em eventos
	if is_active and hud_global and hud_global.has_method("atualizar_todos_os_status"):
		hud_global.atualizar_todos_os_status()

func mostrar_texto_flutuante(valor: int, tipo: String):
	if FLOATING_NUMBER_SCENE and valor > 0:
		var texto = FLOATING_NUMBER_SCENE.instantiate()
		get_tree().current_scene.add_child(texto)
		texto.global_position = global_position + Vector2.UP * 40
		texto.setup(valor, tipo)

# --- SISTEMA DE BUFFS ---
func aplicar_buff_temporario(stat_name: String, porcentagem: float, duracao: float):
	if not stats.has(stat_name): return
	
	if buff_timers.has(stat_name):
		buff_timers[stat_name].time_left = duracao
		return

	var valor_original = stats[stat_name]
	var bonus = valor_original * porcentagem
	
	if typeof(valor_original) == TYPE_INT:
		bonus = int(bonus)
	
	stats[stat_name] += bonus
	
	var timer = get_tree().create_timer(duracao)
	buff_timers[stat_name] = timer
	
	await timer.timeout
	
	stats[stat_name] -= bonus
	buff_timers.erase(stat_name)

# --- ABSTRACTS ---
func attempt_skill_1():
	if not can_use_skill_1 or is_dashing: return
	can_use_skill_1 = false
	execute_skill_1_logic()
	await get_tree().create_timer(skill_1_cooldown).timeout
	can_use_skill_1 = true

func execute_skill_1_logic(): pass
func die(): 
	print("Morreu!")
	get_tree().reload_current_scene()
