class_name classEnemy extends CharacterBody2D

#---------- status----------
@export_group("Stats")
@export var speed: float = 100.0 
@export var max_health: int = 50 

#------atk------
@export_group("Atributos de Combate")
@export var base_atk: int = 20
@export var base_ph: int = 20

#--------- sistema interno -----------
var current_health = 0
var target = null 
var stats = {} 
const FLOATING_NUMBER_SCENE = preload("res://UI/floating_number.tscn")
const ALMA_SCENE = preload("res://characters/Inferno/skills/alma/alma.tscn")

# --- NOVAS VARIÁVEIS DE CONTROLE DE GRUPO (CC) ---
var is_stunned: bool = false
var is_knocked_up: bool = false

func _ready():
	add_to_group("enemies") 
	current_health = max_health
	
	# Monta o dicionário
	stats = { 
		"max_hp": max_health,
		"speed": speed,
		"atk": base_atk,
		"ph": base_ph,
	}

func _physics_process(delta):
	# 1. CHECAGEM DE CONTROLE DE GRUPO (CC)
	# Se estiver atordoado ou voando, não se mexe!
	if is_stunned or is_knocked_up:
		return 

	if target == null:
		return
	
	# 2. MOVIMENTAÇÃO NORMAL
	var direction = global_position.direction_to(target.global_position)
	velocity = direction * stats["speed"]
	move_and_slide()

# --- COMBATE ---

func take_damage(amount: int):
	current_health -= amount
	mostrar_texto_flutuante(amount, "dano")
	
	# Flash Vermelho de Dano
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	
	# Se ainda estiver stunado, volta pra cinza, senão volta pra branco
	if is_stunned:
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE
	
	if current_health <= 0:
		die()

# --- NOVAS FUNÇÕES PARA O BALPO (E OUTROS) USAREM ---

func apply_stun(duration: float):
	# Se já está stunado, só renova o tempo? 
	# Por simplicidade, vamos sobrescrever.
	is_stunned = true
	
	# Muda a cor para indicar atordoamento (Cinza)
	modulate = Color.GRAY
	
	# Cria um timer temporário
	await get_tree().create_timer(duration).timeout
	
	# Acabou o stun
	is_stunned = false
	modulate = Color.WHITE

func apply_knockup(force: Vector2, duration: float):
	if is_knocked_up: return # Evita bugar se receber 2 ao mesmo tempo
	
	is_knocked_up = true
	
	# Cria uma animação suave (Tween) de "pulo"
	var tween = create_tween()
	var original_pos = position
	# Como é top-down, Vector2.UP vai mover ele para o "Norte" da tela
	var target_pos = position + force 
	
	# Sobe
	tween.tween_property(self, "position", target_pos, duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Desce (Volta pro lugar original)
	tween.tween_property(self, "position", original_pos, duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Quando terminar a animação, libera o inimigo
	await tween.finished
	is_knocked_up = false

# --- RESTO DO CÓDIGO (MORTE/ALMA) ---

func die():
	print("Enemy died!")
	spawnar_alma()
	queue_free()

func mostrar_texto_flutuante(valor: int, tipo: String):
	if FLOATING_NUMBER_SCENE:
		var texto = FLOATING_NUMBER_SCENE.instantiate()
		get_tree().current_scene.add_child(texto)
		texto.global_position = global_position + Vector2.UP * 30 
		texto.setup(valor, tipo)

func spawnar_alma():
	if target and ALMA_SCENE:
		var alma = ALMA_SCENE.instantiate()
		alma.global_position = global_position
		alma.setup(target)
		get_tree().current_scene.add_child(alma)
