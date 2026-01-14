extends Node2D

@onready var tile_map = $TileMap
@onready var inferno = $Inferno
@onready var skye = $Skye
@onready var luka = $Luka 
@onready var auro = $Auro
@onready var balpo = $Balpo
@onready var layla = $Layla

# Lista com TODOS os personagens
@onready var personagens = [skye, inferno, luka, auro, balpo, layla] 

# Índice do personagem atual
var indice_atual = 0 

func _ready():
	# Começa ativando só o primeiro da lista e avisando os inimigos
	atualizar_foco()

func _physics_process(delta):
	# Botão de troca (TAB)
	if Input.is_action_just_pressed("ui_focus_next"):
		trocar_personagem()

func trocar_personagem():
	indice_atual += 1
	
	if indice_atual >= personagens.size():
		indice_atual = 0
		
	atualizar_foco()

func atualizar_foco():
	var novo_alvo = null
	
	# 1. Ativa o personagem certo e desativa os outros
	for i in range(personagens.size()):
		if i == indice_atual:
			personagens[i].set_active(true)
			novo_alvo = personagens[i] # Guardamos quem é o ativo
		else:
			personagens[i].set_active(false)
	
	# 2. AVISA O EXÉRCITO INIMIGO (A novidade está aqui!)
	# Pega todos os inimigos que já nasceram (do Spawner ou colocados na mão)
	# IMPORTANTE: Use o nome do grupo que você colocou no script do Inimigo ("enemies" ou "inimigos")
	var inimigos_vivos = get_tree().get_nodes_in_group("enemies") 
	
	for inimigo in inimigos_vivos:
		# Se o inimigo ainda existe e tem a variável target
		if is_instance_valid(inimigo) and "target" in inimigo:
			inimigo.target = novo_alvo
			# print("Inimigo mudou o alvo para: ", novo_alvo.name)
