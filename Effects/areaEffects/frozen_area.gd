extends ZoneEffect

@export var slow_factor: float = 0.4
@export var raio_visual: float = 60.0 # Tamanho do desenho

func _ready():
	# Chama a função que desenha o círculo
	criar_circulo_perfeito()
	
	# Chama o _ready do pai (ZoneEffect) para não quebrar a lógica do timer
	super._ready()

func _apply_effect(body):
	if "speed" in body:
		body.speed *= slow_factor
		body.modulate = Color(0.5, 1.5, 2.0)

func _remove_effect(body):
	if "speed" in body:
		body.speed /= slow_factor
		body.modulate = Color.WHITE

# --- A MÁGICA VISUAL ---
func criar_circulo_perfeito():
	print("--- TENTANDO CRIAR CIRCULO ---")
	
	# Verifica se o nó existe e imprime o nome dele
	var visual = get_node_or_null("Polygon2D")
	
	if visual == null:
		print("ERRO: Não encontrei um filho chamado 'Polygon2D'.")
		print("Nomes encontrados: ")
		for filho in get_children():
			print("- ", filho.name)
		return # Para por aqui

	print("Achei o Polygon2D! Desenhando...")
	
	var pontos_array = PackedVector2Array()
	var numero_de_pontos = 32
	
	for i in range(numero_de_pontos + 1):
		var angulo = i * TAU / numero_de_pontos
		var ponto = Vector2(cos(angulo), sin(angulo)) * raio_visual
		pontos_array.append(ponto)
	
	visual.polygon = pontos_array
	visual.color = Color(0, 1, 1, 0.5)
	print("Desenho concluído com ", pontos_array.size(), " pontos.")
