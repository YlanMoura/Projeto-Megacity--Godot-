extends ZoneEffect

@export var slow_factor: float = 0.5
@export var raio_visual: float = 160.0 # Controla o desenho E a colisão agora

func _ready():
	# 1. Desenha o visual
	criar_circulo_perfeito()
	
	# 2. Ajusta a colisão matematicamente
	atualizar_colisao()
	
	# 3. Chama o pai
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

# --- A MÁGICA DA COLISÃO (NOVA) ---
func atualizar_colisao():
	var col_shape = get_node_or_null("CollisionShape2D")
	
	if col_shape:
		# Cria um novo Círculo matemático na memória
		var forma_circular = CircleShape2D.new()
		forma_circular.radius = raio_visual
		
		# Aplica esse círculo no nó de colisão
		col_shape.shape = forma_circular
		print("Colisão ajustada para raio: ", raio_visual)
	else:
		print("ERRO: Não achei o CollisionShape2D para ajustar o tamanho!")
