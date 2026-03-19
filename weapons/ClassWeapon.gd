extends Node2D
class_name ClassWeapon
var player: ClassPlayer

# --- Enums para Organizacao ---
enum Raridade { COMUM, INCOMUM, RARO, EPICO, LENDARIO, UNICA }
enum Elemento { FISICO, FOGO, CHOQUE, CORROSIVO, ETER, GELO }

# --- NOME DA ARMA --- #
@export var nome_arma: String = "Arma Base"

# --- ATRIBUTOS --- #
@export_group("Stats da Arma")
@export var raridade: Raridade = Raridade.COMUM
@export var tipo_elemento: Elemento = Elemento.FISICO

@export var dano_base: float = 10.0
@export var cadencia_tiro: float = 0.2
@export var tamanho_pente: int = 20
@export var velocidade_recarga: float = 2.0
@export var chance_critico: float = 0.1
@export var multiplicador_critico: float = 2.0
@export var quantidade_pellets: int = 1
@export var dispersao: float = 0.05

@export_group("Mundo")
@export var esta_no_chao: bool = false

# --- Variaveis de Estado ---
var municao_atual: int
var pode_atirar: bool = true
var is_active: bool = true

func _ready():
	municao_atual = tamanho_pente

	if get_parent() is ClassPlayer:
		player = get_parent()
	elif get_owner() is ClassPlayer:
		player = get_owner()

func _physics_process(_delta):
	if not is_active or player == null:
		return

	if Input.is_action_pressed("ataque"):
		tentar_atirar()

func tentar_atirar():
	if pode_atirar and municao_atual > 0:
		disparar()

func drop():
	is_active = false
	esta_no_chao = true

	var posicao_global_atual = global_position
	var mapa = get_tree().current_scene
	get_parent().remove_child(self)
	mapa.add_child(self)
	global_position = posicao_global_atual

	var direcao_drop = Vector2(randf_range(-60, 60), randf_range(-30, -50))
	var tween = create_tween()
	tween.tween_property(self, "global_position", global_position + direcao_drop, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	print(nome_arma, " foi dropada!")

func disparar():
	pode_atirar = false
	municao_atual -= 1

	for i in range(quantidade_pellets):
		var resultado = player.calculate_damage(dano_base, "atk")
		var angulo_final = randf_range(-dispersao, dispersao)
		var direcao = Vector2.RIGHT.rotated(global_rotation + angulo_final)
		criar_projetil(direcao, resultado)

	await get_tree().create_timer(cadencia_tiro).timeout
	pode_atirar = true

func criar_projetil(direcao: Vector2, dados_dano: Dictionary):
	print("Tiro disparado! Dano: ", dados_dano["value"], " Direcao: ", direcao)
