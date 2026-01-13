extends ZoneEffect

# Configurações da Gosma
@export var damage_amount: int = 10     
@export var slow_factor: float = 0.5    # 0.5 = Reduz 50% da velocidade
@export var raio_visual: float = 80.0   

var damage_timer : Timer

# Dicionário para guardar quanta velocidade tiramos de cada inimigo/player
# Ex: { <ObjetoPlayer>: 200, <ObjetoInimigo>: 150 }
var debitos_de_velocidade = {}

func _ready():
	criar_visual_rosa()
	atualizar_colisao()
	configurar_timer()
	super._ready()

# --- LÓGICA DE ENTRADA E SAÍDA ---

func _apply_effect(body):
	# 1. Aplica Lentidão (Se tiver sistema de Stats)
	if "stats" in body and body.stats.has("speed"):
		var speed_original = body.stats["speed"]
		
		# Calcula quanto vamos "roubar" de velocidade
		# Ex: 400 * (1 - 0.5) = 200 pontos de lentidão
		var valor_retirado = int(speed_original * (1.0 - slow_factor))
		
		# Tira do status
		body.stats["speed"] -= valor_retirado
		
		# Guarda no caderninho para devolver depois
		debitos_de_velocidade[body] = valor_retirado
		
		# Efeito visual
		body.modulate = Color(1, 0.5, 0.8) # Rosa
	
	# 2. Dano Imediato
	if body.has_method("take_damage"):
		body.take_damage(damage_amount)

func _remove_effect(body):
	# Tenta devolver a velocidade roubada
	if debitos_de_velocidade.has(body):
		var valor_a_devolver = debitos_de_velocidade[body]
		
		# Verifica se o corpo ainda existe e tem stats
		if is_instance_valid(body) and "stats" in body:
			body.stats["speed"] += valor_a_devolver
			body.modulate = Color.WHITE
		
		# Risca do caderninho
		debitos_de_velocidade.erase(body)

# --- LÓGICA DO TIMER (Dano contínuo) ---

func configurar_timer():
	damage_timer = Timer.new()
	damage_timer.wait_time = tick_rate # Certifique-se que 'tick_rate' existe no pai (ZoneEffect)
	damage_timer.autostart = true 
	damage_timer.one_shot = false 
	add_child(damage_timer)
	damage_timer.timeout.connect(_on_timer_tick)

func _on_timer_tick():
	var vitimas = get_overlapping_bodies()
	for body in vitimas:
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)

# --- VISUAL ---

func criar_visual_rosa():
	var visual = get_node_or_null("Polygon2D")
	if visual:
		var pontos_array = PackedVector2Array()
		var numero_de_pontos = 32
		
		for i in range(numero_de_pontos + 1):
			var angulo = i * TAU / numero_de_pontos
			var ponto = Vector2(cos(angulo), sin(angulo)) * raio_visual
			pontos_array.append(ponto)
		
		visual.polygon = pontos_array
		visual.color = Color(1, 0.2, 0.6, 0.6) 

func atualizar_colisao():
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape:
		var forma_circular = CircleShape2D.new()
		forma_circular.radius = raio_visual
		col_shape.shape = forma_circular
