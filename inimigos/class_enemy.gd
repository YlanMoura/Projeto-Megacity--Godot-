class_name classEnemy extends CharacterBody2D
#---------- status----------
@export_group("Stats")
@export var speed: float = 100.0 # Agora apenas define o valor inicial
@export var max_health: int = 50 

#------atk------
@export_group("Atributos de Combate")
@export var base_atk: int = 20
@export var base_ph: int = 20

#--------- sistema interno -----------
var current_health = 0
var target = null 
var stats = {} # Onde a mágica acontece
const FLOATING_NUMBER_SCENE = preload("res://UI/floating_number.tscn")
const ALMA_SCENE = preload("res://characters/Inferno/skills/alma/alma.tscn")

func _ready():
	# Adicione o inimigo no grupo para o Spawner achar fácil, se quiser
	add_to_group("enemies") 
	
	current_health = max_health
	
	# Monta o dicionário igual ao do Player
	stats = { 
		"max_hp": max_health,
		"speed": speed, # <--- A velocidade real fica aqui agora
		"atk": base_atk,
		"ph": base_ph,
	}

func _physics_process(delta):
	if target == null:
		return
	
	# Calcula a direção para o target
	var direction = global_position.direction_to(target.global_position)
	
	# CORREÇÃO: Usamos stats["speed"] em vez da variável speed
	# Assim, se a gosma reduzir stats["speed"], o inimigo anda devagar!
	velocity = direction * stats["speed"]
	
	move_and_slide()

# --- COMBATE ---

func take_damage(amount: int):
	current_health -= amount
	mostrar_texto_flutuante(amount, "dano")
	
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		die()

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
	# Só cria alma se tiver um alvo definido (o player que matou ou estava perseguindo)
	if target and ALMA_SCENE:
		var alma = ALMA_SCENE.instantiate()
		alma.global_position = global_position
		
		# Configura a alma para voar até o player (target)
		alma.setup(target)
		
		get_tree().current_scene.add_child(alma)
