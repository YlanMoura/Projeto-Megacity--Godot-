class_name ClassPlayer extends CharacterBody2D

# --- STATUS GERAIS ---
@export_group("Status")
@export var max_health: int = 100
var current_health: int

# --- ESCUDO (SHIELD) ---
@export_group("Escudo")
@export var max_shield: int = 50
@export var shield_regen_delay: float = 3.0 # Tempo de espera para regenerar
@export var shield_regen_rate: float = 10.0  # Pontos por segundo
var current_shield: int
var regen_timer: float = 0.0      # Cronômetro para delay
var regen_accumulator: float = 0.0 # Acumulador para números inteiros

# --- MOVIMENTO E DASH ---
@export_group("Movimento")
@export var speed: float = 400.0

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
var vida_label: Label 
var stats = {}
const FLOATING_NUMBER_SCENE = preload("res://UI/floating_number.tscn")

func _ready():
	# Inicializa os valores atuais
	current_health = max_health
	current_shield = max_shield 
	current_dashes = max_dashes
	
	# Configurações de colisão padrão
	set_collision_mask_value(1, true)
	set_collision_mask_value(4, true)
	set_collision_mask_value(3, true)
	
	# Criar o texto de vida via código
	vida_label = Label.new()
	add_child(vida_label)
	vida_label.position = Vector2(-20, -70)
	actualizar_ui_vida()
	
	# Monta o dicionário de Stats (Ficha do Personagem)
	stats = {
		"max_hp": max_health,
		"max_shield": max_shield,
		"speed": speed,
		
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

# Lógica de Regeneração do Escudo
func _process(delta: float) -> void:
	# 1. Se tomou dano recentemente, diminui o tempo de espera
	if regen_timer > 0:
		regen_timer -= delta
		
	# 2. Se o tempo acabou E o escudo não está cheio
	elif current_shield < max_shield:
		regen_accumulator += shield_regen_rate * delta
		
		# Só aplica quando juntar 1 ponto inteiro (para não travar a tela com textos)
		if regen_accumulator >= 1.0:
			var amount = int(regen_accumulator)
			regen_accumulator -= amount 
			
			current_shield += amount
			
			# Trava no máximo
			if current_shield > max_shield:
				current_shield = max_shield
			
			actualizar_ui_vida()
			# Mostra texto CIANO (igual ao dano de escudo, mas subindo)
			mostrar_texto_flutuante(amount, "escudo")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill1") and can_use_skill_1:
		attempt_skill_1()

# --- COMBATE E DANO ---

func take_damage(amount: int):
	# PARA A REGENERAÇÃO IMEDIATAMENTE AO TOMAR DANO
	regen_timer = shield_regen_delay
	regen_accumulator = 0.0 
	
	# 1. Lógica do Escudo (Absorve primeiro)
	if current_shield > 0:
		var damage_to_shield = min(current_shield, amount)
		current_shield -= damage_to_shield
		amount -= damage_to_shield 
		# Mostra dano no escudo (Ciano/Azul)
		mostrar_texto_flutuante(damage_to_shield, "escudo")
	
	# 2. Lógica da Vida (Se sobrou dano)
	if amount > 0:
		current_health -= amount
		# Mostra dano na vida (Vermelho/Branco)
		mostrar_texto_flutuante(amount, "dano")
	
	actualizar_ui_vida()
	
	if current_health <= 0:
		die()

# Função auxiliar para calcular dano e critico (Usada por armas e skills)
func calculate_damage(base_dmg: float, scaling_stat: String) -> Dictionary:
	var final_dmg = base_dmg + stats.get(scaling_stat, 0)
	var is_crit = false
	
	if randf() <= stats["crit_chance"]:
		final_dmg *= stats["crit_damage"]
		is_crit = true
		
	return {"value": int(final_dmg), "critical": is_crit}

func heal(amount: int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	actualizar_ui_vida()
	mostrar_texto_flutuante(amount, "cura")

# --- UI E EFEITOS ---

func actualizar_ui_vida():
	if vida_label:
		# Exibe: HP: 100 | SH: 50
		vida_label.text = "HP: %d | SH: %d" % [current_health, current_shield]
		
		# Feedback de cor do texto fixo
		if current_health < max_health * 0.25:
			vida_label.modulate = Color.RED
		elif current_shield <= 0:
			vida_label.modulate = Color.YELLOW # Alerta: sem escudo!
		else:
			vida_label.modulate = Color.WHITE

func mostrar_texto_flutuante(valor: int, tipo: String):
	if FLOATING_NUMBER_SCENE and valor > 0:
		var texto = FLOATING_NUMBER_SCENE.instantiate()
		get_tree().current_scene.add_child(texto)
		# Sobe um pouco acima da cabeça
		texto.global_position = global_position + Vector2.UP * 40
		texto.setup(valor, tipo)

# --- FUNÇÕES DE HABILIDADE E DASH ---

func attempt_skill_1():
	if not can_use_skill_1 or is_dashing: return
	can_use_skill_1 = false
	execute_skill_1_logic()
	await get_tree().create_timer(skill_1_cooldown).timeout
	can_use_skill_1 = true

func execute_skill_1_logic():
	pass # Sobrescrito pelo Inferno.gd ou Skye.gd

func recharge_one_dash():
	await get_tree().create_timer(dash_cooldown).timeout
	if current_dashes < max_dashes:
		current_dashes += 1

func die():
	print("Morreu!")
	get_tree().reload_current_scene()
