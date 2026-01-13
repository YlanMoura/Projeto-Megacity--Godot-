extends Node2D
class_name ClassWeapon
var player: ClassPlayer

# --- Enums para Organização ---
enum Raridade { COMUM, INCOMUM, RARO, EPICO, LENDARIO, UNICA}
enum Elemento { FISICO, FOGO, CHOQUE, CORROSIVO, ÉTER}

# --- NOME DA ARMA --- #

@export var nome_arma: String ="Arma Base" 

# --- ATRIBUTOS --- #
@export_group("Stats da Arma")
@export var raridade: Raridade = Raridade.COMUM
@export var tipo_elemento: Elemento = Elemento.FISICO

@export var dano_base: float = 10.0
@export var cadencia_tiro: float = 0.2 #Segundos entre tiros
@export var tamanho_pente: int = 20
@export var velocidade_recarga: float = 2.0
@export var chance_critico: float = 0.1 #10% de chance
@export var multiplicador_critico: float = 2.0 #Dano x2

#--- Variáveis de Estado ---

var munição_atual: int
var pode_atirar: bool = true
var is_active: bool=true

func _ready():
	munição_atual = tamanho_pente
	
	# Busca o jogador para acessar o dicionário 'stats'
	if get_parent() is ClassPlayer:
		player = get_parent()
	elif get_owner() is ClassPlayer:
		player = get_owner()

func _physics_process(_delta):
	if not is_active or player == null: 
		return
	
	if Input.is_action_pressed("atirar"):
		tentar_atirar()

func tentar_atirar():
	if pode_atirar and munição_atual > 0:
		disparar()

func disparar():
	pode_atirar = false
	munição_atual -= 1
	
	# Usa a função de cálculo que já existe no seu Player
	var resultado = player.calculate_damage(dano_base, "atk")
	
	var dano_final = resultado["value"]
	var foi_critico = resultado["critical"]
	
	print("Dano: ", dano_final, " | Crítico: ", foi_critico)
	
	await get_tree().create_timer(cadencia_tiro).timeout
	pode_atirar = true
