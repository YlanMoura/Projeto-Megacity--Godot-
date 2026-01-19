extends Node2D

@onready var tile_map = $TileMap
@onready var inferno = $Inferno
@onready var skye = $Skye
@onready var balpo = $Balpo
@onready var layla = $Layla

# --- NOVO: Referência ao seu HUD ---
@onready var hud = $Hud # Verifique se o nome na árvore de nós é exatamente "Hud"

# Lista com TODOS os personagens
@onready var personagens = [layla, skye, inferno, balpo] 

# Índice do personagem atual
var indice_atual = 0 

func _ready():
	# Começa ativando só o primeiro da lista
	atualizar_foco()

func _physics_process(_delta):
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
			novo_alvo = personagens[i]
		else:
			personagens[i].set_active(false)
	
	# 2. AVISA O HUD (Conecta a interface ao novo personagem)
	if hud and novo_alvo:
		hud.conectar_no_player(novo_alvo)
	
	# 3. AVISA O EXÉRCITO INIMIGO
	var inimigos_vivos = get_tree().get_nodes_in_group("enemies") 
	for inimigo in inimigos_vivos:
		if is_instance_valid(inimigo) and "target" in inimigo:
			inimigo.target = novo_alvo
