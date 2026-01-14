extends Node2D
class_name ClassWeapon
var player: ClassPlayer

# --- Enums para Organização ---
enum Raridade { COMUM, INCOMUM, RARO, EPICO, LENDARIO, UNICA}
enum Elemento { FISICO, FOGO, CHOQUE, CORROSIVO, ETER, GELO}

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
@export var quantidade_pellets: int = 1
@export var dispersao: float = 0.05

@export_group("Mundo")
@export var esta_no_chao: bool = false # Define se a arma começa no chão ou na mão



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
func drop():
	#  1. Libera a arma para ser processada no mundo
	is_active = false
	esta_no_chao = true
	
	# 2. Salva a posição global atual antes de mudar de "pai"
	var posicao_global_atual = global_position
	
	# 3. Muda o "pai" da arma.
	# Ela deixa de ser filha do Player e vira filha da Cena Principal (o mapa)
	var mapa = get_tree().current_scene
	get_parent().remove_child(self)
	mapa.add_child(self)
	
	# 4. Reposiciona a arma onde o jogador a soltou
	global_position = posicao_global_atual
	
	# 5. Efeito visual de "pulinho"
	# Faz a arma dar um salto aleatório para o lado ao cair
	var direcao_drop = Vector2(randf_range (-60, 60), randf_range (-30, -50))
	var tween = create_tween()
	tween.tween_property(self, "global_position", global_position + direcao_drop, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	print(nome_arma, " foi dropada!")
	
func disparar():
	pode_atirar = false
	munição_atual -= 1
	
	#O loop agora usa a variável da classe pai
	for i in range(quantidade_pellets):
		# 1. Calcula dano (cada pellet tem seu próprio cálculo de crítico)
		var resultado = player.calculate_damage(dano_base, "atk")
		
		# 2. Calcula a direção com dispersão
		# Usamos global_transform.x para saber onde a arma está apontada
		var angulo_final = randf_range(-dispersao, dispersao)
		var direcao = Vector2.RIGHT.rotated(global_rotation + angulo_final)
		
		# 3. Chamar a criação do projétil real
		criar_projetil(direcao, resultado)
	
	# 4. Espera o tempo entre tiros
	await get_tree().create_timer(cadencia_tiro).timeout
	pode_atirar = true
	
#Função que será responsável por spawnar a bala no mundo
func criar_projetil(direcao: Vector2, dados_dano: Dictionary):
		#Por enquanto deixamos um print, mas aqui irá o código de instanciar a cena da bala
		print("Tiro disparado! Dano: ", dados_dano["value"], " Direção: ", direcao)
