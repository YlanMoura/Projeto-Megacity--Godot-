extends Node2D

@onready var tile_map = $TileMap
@onready var inferno = $Inferno
@onready var skye = $Skye
@onready var luka = $Luka 
# 2. Crie uma lista com TODOS os personagens
@onready var personagens = [skye, inferno, luka] 

# 3. Qual o número do personagem atual? (0 = Skye, 1 = Inferno, 2 = Luka)
var indice_atual = 0 

func _ready():
	# Começa ativando só o primeiro da lista
	atualizar_foco()
	
	# 1. Pega a lista de TODOS os nós que têm a etiqueta "inimigos"
	var exercito_inimigo = get_tree().get_nodes_in_group("inimigos")
	
	# 2. Passa de um por um (loop) e define o alvo
	for soldado in exercito_inimigo:
		soldado.target = skye

func _physics_process(delta):
	# Quando apertar TAB (ou a tecla que você configurou)
	if Input.is_action_just_pressed("ui_focus_next"): # Geralmente é o TAB
		trocar_personagem()

func trocar_personagem():
	# Aumenta o índice (+1)
	indice_atual += 1
	
	# Se passou do último (3), volta para o zero
	if indice_atual >= personagens.size():
		indice_atual = 0
		
	atualizar_foco()

func atualizar_foco():
	# Passa por todos os personagens da lista
	for i in range(personagens.size()):
		if i == indice_atual:
			personagens[i].set_active(true) # Ativa o escolhido
		else:
			personagens[i].set_active(false) # Desliga os outros
