extends Area2D

# --- Configurações Iguais à Slime ---
@export var damage_amount: int = 10      # Dano em inimigos
@export var heal_amount: int = 5         # Cura no Inferno (adicionei para a mecânica dele)
@export var slow_factor: float = 0.5     # 50% de lentidão (se tiver sistema de speed)
@export var raio_visual: float = 80.0    # Tamanho do círculo
@export var tick_rate: float = 0.5       # Tempo entre os tics (0.5s é bom para fogo)
@export var duration: float = 5.0        # Quanto tempo a poça fica no chão

func _ready():
	# 1. Ajusta o Colisor para ter o mesmo tamanho do desenho
	var shape_node = get_node_or_null("CollisionShape2D")
	if shape_node and shape_node.shape is CircleShape2D:
		shape_node.shape.radius = raio_visual
	
	# 2. Cria o Timer do Dano/Cura (Tick) via código
	var tick_timer = Timer.new()
	tick_timer.wait_time = tick_rate
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_tick_timer_timeout)
	add_child(tick_timer)
	
	# 3. Cria o Timer para a poça sumir sozinha
	var life_timer = get_tree().create_timer(duration)
	life_timer.timeout.connect(queue_free)
	
	# 4. Força o Godot a desenhar o círculo
	queue_redraw()

# --- A FUNÇÃO DO CÍRCULO PERFEITO ---
func _draw():
	# Desenha um círculo preenchido
	# Color(Red, Green, Blue, Alpha)
	# Ciano/Turquesa = (0, 1, 1). Alpha 0.4 para ficar transparente.
	draw_circle(Vector2.ZERO, raio_visual, Color(0, 1, 1, 0.4))
	
	# Opcional: Desenha uma borda mais forte
	draw_arc(Vector2.ZERO, raio_visual, 0, TAU, 32, Color(0, 1, 1, 0.8), 2.0)

# --- LÓGICA DO TICK ---
func _on_tick_timer_timeout():
	var corpos = get_overlapping_bodies()
	
	for corpo in corpos:
		# 1. Se for INIMIGO -> Dano
		if corpo.is_in_group("inimigos"):
			if corpo.has_method("take_damage"):
				corpo.take_damage(damage_amount)
			
			# (Opcional) Se tiver lógica de lentidão no inimigo:
			# if corpo.has_method("apply_slow"):
			#    corpo.apply_slow(slow_factor)
		
		# 2. Se for o INFERNO -> Cura
		elif corpo is ClassPlayer and corpo.name == "Inferno" or corpo.name == "Auro" :
			if corpo.has_method("heal"):
				corpo.heal(heal_amount)
				# print("Inferno a curar na zona!")
func atualizar_colisao():
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape:
		var forma_circular = CircleShape2D.new()
		forma_circular.radius = raio_visual
		col_shape.shape = forma_circular
