extends ZoneEffect

# Configurações da Gosma
@export var damage_amount: int = 10     # Dano por tic e impacto
@export var slow_factor: float = 0.5    # 50% de lentidão
@export var raio_visual: float = 80.0   # Tamanho da área
@export var tick_rate: float = 1.0      # Tempo entre os danos (1 segundo)

var damage_timer : Timer

func _ready():
	# 1. Cria o visual Rosa
	criar_visual_rosa()
	atualizar_colisao()
	
	# 2. Configura o Timer de Dano via código
	# (Assim você não precisa criar nó Timer na cena manualmente toda vez)
	configurar_timer()
	
	super._ready()

# --- LÓGICA DE ENTRADA E SAÍDA (Herdado do ZoneEffect) ---

func _apply_effect(body):
	# Efeito 1: Lentidão
	if "speed" in body:
		body.speed *= slow_factor
		body.modulate = Color(1, 0.5, 0.8) # Fica rosado
	
	# Efeito 2: Dano Imediato (O "Splash" inicial)
	if body.has_method("take_damage"):
		body.take_damage(damage_amount)

func _remove_effect(body):
	# Restaura a velocidade ao sair
	if "speed" in body:
		body.speed /= slow_factor
		body.modulate = Color.WHITE

# --- LÓGICA DO TIMER (Dano contínuo) ---

func configurar_timer():
	damage_timer = Timer.new()
	damage_timer.wait_time = tick_rate
	damage_timer.autostart = true # Começa a rodar sozinho
	damage_timer.one_shot = false # Fica em loop
	add_child(damage_timer)
	
	# Conecta o sinal de timeout na nossa função customizada
	damage_timer.timeout.connect(_on_timer_tick)

func _on_timer_tick():
	# Pega todo mundo que está dentro da área NESTE MOMENTO
	var vitimas = get_overlapping_bodies()
	
	for body in vitimas:
		# Se tiver vida, toma dano
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)

# --- VISUAL (Mesma lógica do gelo, cor diferente) ---

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
		# Cor Rosa "Gosmento" (R, G, B, Alpha)
		visual.color = Color(1, 0.2, 0.6, 0.6) 

func atualizar_colisao():
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape:
		var forma_circular = CircleShape2D.new()
		forma_circular.radius = raio_visual
		col_shape.shape = forma_circular
