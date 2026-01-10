extends CharacterBody2D
#---------- status----------
@export_group("Stats")
@export var speed = 100 
@export var max_health: int = 50 
#------atk------
@export_group("Atributos de Combate")
@export var base_atk: int = 20
@export var base_ph: int = 20
@export var base_crit_chance: float = 0.1
@export var base_crit_damage: float = 1.2

#--------- sistema interno -----------
var current_health = 0
var target = null # antigo 'alvo'
var stats = {}
const FLOATING_NUMBER_SCENE = preload("res://UI/floating_number.tscn")

func _ready():
	current_health = max_health
	stats = { 
		"max_hp": max_health,
		"speed": speed,
		
		"atk": base_atk,
		"ph": base_ph,
		}

func _physics_process(delta):
	if target == null:
		return
	
	# Calcula a direção para o target
	var direction = global_position.direction_to(target.global_position)
	velocity = direction * speed
	move_and_slide()

func take_damage(amount: int):
	current_health -= amount
	
	# 1. Mostra o texto flutuante (Branco/Vermelho)
	mostrar_texto_flutuante(amount, "dano")
	
	# 2. Feedback visual (Piscada)
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	# Opcional: mostrar cura no inimigo também
	mostrar_texto_flutuante(amount, "cura")

func die(): 
	print("Enemy died!")
	queue_free()

# --- FUNÇÃO QUE CRIA O TEXTO ---
func mostrar_texto_flutuante(valor: int, tipo: String):
	if FLOATING_NUMBER_SCENE:
		var texto = FLOATING_NUMBER_SCENE.instantiate()
		# Adicionamos na cena principal para o texto não se mover junto com o inimigo
		get_tree().current_scene.add_child(texto)
		texto.global_position = global_position + Vector2.UP * 30 # Sobe um pouquinho
		texto.setup(valor, tipo)
