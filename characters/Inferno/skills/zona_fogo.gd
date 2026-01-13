extends ZoneEffect

# --- Configurações ---
@export var dano_por_tick: int = 0
@export var cura_por_tick: int = 0        
@export var raio_visual: float = 80.0   
	

func _ready():
	atualizar_tamanho_zona()
	
	var tick_timer = Timer.new()
	tick_timer.wait_time = tick_rate
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_tick_timer_timeout)
	add_child(tick_timer)
	
	var life_timer = get_tree().create_timer(duration)
	life_timer.timeout.connect(queue_free)

# --- ALTERAÇÃO NA SETUP: Agora pede o "criador" também ---
func setup(pacote_de_dano: Dictionary, criador: Node2D): # <--- NOVO 2: Recebe o criador
	caster = criador # Guarda o Inferno na memória
	
	# Mantém a leitura do pacote como "valor base/inicial"
	if pacote_de_dano.has("final_damage"):
		dano_por_tick = pacote_de_dano["final_damage"]
	
	if pacote_de_dano.has("cura_valor"):
		cura_por_tick = pacote_de_dano["cura_valor"]
	
	print("Zona criada! Caster é: ", caster.name)

func atualizar_tamanho_zona():
	# ... (igual) ...
	var shape_node = get_node_or_null("CollisionShape2D")
	if shape_node:
		if shape_node.shape is CircleShape2D:
			shape_node.shape.radius = raio_visual
		else:
			var novo_shape = CircleShape2D.new()
			novo_shape.radius = raio_visual
			shape_node.shape = novo_shape
	queue_redraw()

func _draw():
	# ... (igual) ...
	draw_circle(Vector2.ZERO, raio_visual, Color(0, 1, 1, 0.4))
	draw_arc(Vector2.ZERO, raio_visual, 0, TAU, 32, Color(0, 1, 1, 0.8), 2.0)

func _on_tick_timer_timeout():
	# --- CÁLCULO DINÂMICO (NOVO 3) ---
	var dano_atual = dano_por_tick # Começa com o valor padrão
	var cura_atual = cura_por_tick
	
	# Se o Inferno ainda existe no jogo, pega o ATK dele AGORA
	if is_instance_valid(caster):
		var atk_do_momento = caster.stats["atk"]
		
		# Recalcula as porcentagens (5% dano, 10% cura)
		dano_atual = int(atk_do_momento * 0.25)
		cura_atual = int(atk_do_momento * 0.10)
	
	# --- APLICAÇÃO ---
	var corpos = get_overlapping_bodies()
	
	for corpo in corpos:
		# 1. INIMIGOS
		if corpo.is_in_group("inimigos"):
			if corpo.has_method("take_damage"):
				corpo.take_damage(dano_atual) # <--- Usa a variável atualizada
		
		# 2. PLAYERS
		elif corpo is ClassPlayer and "Inferno" in corpo.name:
			if corpo.has_method("heal"):
				corpo.heal(cura_atual) # <--- Usa a variável atualizada
			
			if corpo.has_method("aplicar_buff_temporario"):
				corpo.aplicar_buff_temporario("atk", 0.5, 0.6)
				
