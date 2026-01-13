extends ClassProjectile

# --- Configurações ---
@export var raio_explosao = 260.0
@export var escala_visual_explosao = Vector2(2.5, 2.5)
const CENA_ZONA = preload("res://characters/Inferno/skills/ZonaFogo.tscn")

var ja_explodiu = false
var meu_criador = null 

# --- 1. SETUP ---
func setup(direcao, dados_dano, quem_atirou = null):
	super.setup(direcao, dados_dano)
	meu_criador = quem_atirou

func _physics_process(delta):
	if not ja_explodiu:
		super(delta)

# --- 2. HORA DA CRIAÇÃO ---
func on_impact(body):
	if ja_explodiu: return
	ja_explodiu = true
	
	# [RECUPERADO] Dano Imediato da Explosão
	explodir_area()
	
	# Efeitos Visuais
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("explosao")
		$AnimatedSprite2D.scale = escala_visual_explosao
		await $AnimatedSprite2D.animation_finished
	
	# Cria a Zona
	criar_zona_dinamica()
	
	queue_free()

# [RECUPERADO] Função que dá dano em todo mundo ao redor na hora do impacto
func explodir_area():
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	
	for inimigo in inimigos:
		var distancia = global_position.distance_to(inimigo.global_position)
		
		if distancia <= raio_explosao:
			if inimigo.has_method("take_damage"):
				# Usa o dano que veio no pacote do Inferno (damage_info["value"])
				inimigo.take_damage(damage_info["value"])

func criar_zona_dinamica():
	if CENA_ZONA:
		var zona = CENA_ZONA.instantiate()
		zona.global_position = global_position
		
		# 1. Configura a Lógica (Dano/Cura/Criador)
		if zona.has_method("setup"):
			zona.setup(damage_info, meu_criador)
		
		# 2. [RECUPERADO] Configura o Tamanho Visual
		# Passamos o raio da explosão para a poça ter o mesmo tamanho
		if "raio_visual" in zona:
			zona.raio_visual = raio_explosao
			
		get_tree().current_scene.add_child(zona)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
