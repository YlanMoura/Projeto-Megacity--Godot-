extends ZoneEffect

@export var slow_factor: float = 0.5
@export var raio_visual: float = 160.0 # Controla o desenho E a colisão

# Dicionário para guardar quanta velocidade tiramos (O "Caderninho")
var debitos_de_velocidade = {}

func _ready():
	# 1. Desenha o visual
	criar_circulo_perfeito()
	
	# 2. Ajusta a colisão matematicamente
	atualizar_colisao()
	
	# 3. Chama o pai
	super._ready()

# --- APLICAÇÃO SEGURA DE LENTIDÃO ---

func _apply_effect(body):
	# Verifica se o corpo tem o sistema novo de stats
	if "stats" in body and body.stats.has("speed"):
		var speed_original = body.stats["speed"]
		
		# Calcula quanto vamos REDUZIR.
		# Se speed é 400 e fator é 0.5 (50%), a redução é 200.
		var valor_retirado = speed_original * (1.0 - slow_factor)
		
		# Subtrai do dicionário oficial
		body.stats["speed"] -= valor_retirado
		
		# Anota no caderninho para devolver depois
		debitos_de_velocidade[body] = valor_retirado
		
		# Efeito visual (Azul Gelo)
		body.modulate = Color(0.5, 1.5, 2.0)

func _remove_effect(body):
	# Verifica se esse corpo deve algo no caderninho
	if debitos_de_velocidade.has(body):
		
		# Se o corpo ainda existe (não morreu/desapareceu)
		if is_instance_valid(body) and "stats" in body:
			# Devolve o valor exato que tirou
			body.stats["speed"] += debitos_de_velocidade[body]
			body.modulate = Color.WHITE
		
		# Rasga a folha do caderninho (limpa a memória)
		debitos_de_velocidade.erase(body)

# --- A MÁGICA VISUAL (MANTIDA IGUAL) ---
func criar_circulo_perfeito():
	var visual = get_node_or_null("Polygon2D")
	if visual:
		var pontos_array = PackedVector2Array()
		var numero_de_pontos = 32
		
		for i in range(numero_de_pontos + 1):
			var angulo = i * TAU / numero_de_pontos
			var ponto = Vector2(cos(angulo), sin(angulo)) * raio_visual
			pontos_array.append(ponto)
		
		visual.polygon = pontos_array
		visual.color = Color(0, 1, 1, 0.5)

# --- A MÁGICA DA COLISÃO (MANTIDA IGUAL) ---
func atualizar_colisao():
	var col_shape = get_node_or_null("CollisionShape2D")
	
	if col_shape:
		var forma_circular = CircleShape2D.new()
		forma_circular.radius = raio_visual
		col_shape.shape = forma_circular
		print("Colisão ajustada para raio: ", raio_visual)
	else:
		print("ERRO: Não achei o CollisionShape2D para ajustar o tamanho!")
