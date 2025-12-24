class_name ClassPlayer extends CharacterBody2D

# --- Grupo de STATUS ---
@export_group("Status")
@export var max_health: int = 100
var current_health: int

# --- Grupo de MOVIMENTO ---
@export_group("Movimento")
@export var speed: float = 400.0

# --- Grupo de DASH ---
@export_group("Dash")
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.5
@export var max_dashes: int = 1

var current_dashes: int = 0
var is_dashing: bool = false # Compartilhado: ambos precisam saber se estão dashando

# Carrega a cena do texto flutuante
const FLOATING_NUMBER_SCENE = preload("res://UI/floating_number.tscn")

func _ready():
	current_health = max_health
	current_dashes = max_dashes # Já inicia as cargas aqui
# Força a colisão com a Layer 1 (Cenário/Borda)
	set_collision_mask_value(1, true)
	
	# Força a colisão com a Layer 4 (Parede Fina)
	set_collision_mask_value(4, true)
	
	# (Opcional) Se quiser garantir que eles colidam com inimigos (Layer 3)
	set_collision_mask_value(3, true)
# --- LÓGICA DE RECARGA (Compartilhada) ---
func recharge_one_dash():
	# Usa o dash_cooldown que está configurado no Inspector do filho
	await get_tree().create_timer(dash_cooldown).timeout
	
	if current_dashes < max_dashes:
		current_dashes += 1
		print(name, " recarregou dash! Cargas: ", current_dashes)

# --- COMBATE (Dano, Cura, Morte) ---
func take_damage(amount: int):
	current_health -= amount
	print(name, " tomou ", amount, " de dano. Vida: ", current_health)
	mostrar_texto_flutuante(amount, "dano")
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	mostrar_texto_flutuante(amount, "cura")

func die():
	print("MORREU! X_X")
	get_tree().reload_current_scene()

func mostrar_texto_flutuante(valor: int, tipo: String):
	if FLOATING_NUMBER_SCENE:
		var texto_instancia = FLOATING_NUMBER_SCENE.instantiate()
		get_tree().current_scene.add_child(texto_instancia)
		texto_instancia.global_position = global_position + Vector2.UP * 40
		texto_instancia.setup(valor, tipo)
