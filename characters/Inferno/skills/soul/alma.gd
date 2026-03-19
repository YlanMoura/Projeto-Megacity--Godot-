extends Area2D

var alvo = null
var velocidade = 400.0
var aceleracao = 15.0 
var velocidade_atual = Vector2.ZERO

func _ready():
	# 1. Efeito visual (Crescer)
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3)
	
	# 2. AGORA SIM: Procura o Inferno (Aqui o get_tree() funciona!)
	var inferno_encontrado = encontrar_inferno()
	
	if inferno_encontrado:
		alvo = inferno_encontrado
	else:
		# Se não achar o Inferno, a alma some
		queue_free()

# A função setup fica vazia ou opcional, pois a lógica mudou pro _ready
func setup(_quem_matou_original):
	pass

func encontrar_inferno():
	# Agora é seguro chamar get_tree()
	var players = get_tree().get_nodes_in_group("players")
	
	for player in players:
		if "Inferno" in player.name:
			return player
	return null

func _physics_process(delta):
	# Se não tiver alvo (Inferno morreu ou não existe), some
	if not is_instance_valid(alvo):
		queue_free()
		return

	# Lógica de perseguição
	var direcao = global_position.direction_to(alvo.global_position)
	velocidade += aceleracao 
	global_position += direcao * velocidade * delta
	
	if global_position.distance_to(alvo.global_position) < 25:
		entregar_alma()

func entregar_alma():
	if alvo.has_method("receber_alma"):
		alvo.receber_alma()
	queue_free()
