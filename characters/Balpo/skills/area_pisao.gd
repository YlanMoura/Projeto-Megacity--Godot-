extends ZoneEffect

# --- CONFIGURAÇÕES VISUAIS (Desenho no Chão) ---
@export var raio_visual: float = 180.0
@export var cor_borda: Color = Color(1.0, 0.5, 0.0, 1.0) # Laranja Forte
@export var cor_fundo: Color = Color(1.0, 0.5, 0.0, 0.2) # Laranja Transparente (Fundo)
@export var espessura_anel: float = 4.0 # Grossura da linha

# --- DADOS RECEBIDOS DO BALPO ---
var dano_calculado: int = 0
var tenacidade_por_hit: int = 12

func _ready():
	super._ready() # Chama o setup padrão do ZoneEffect
	
	affects_caster = false # Balpo não se machuca
	duration = 0.5 # A área dura pouco tempo no chão
	
	# 1. Ajusta o tamanho da colisão física para bater com o visual
	_atualizar_tamanho_fisico()
	
	# 2. Manda o Godot desenhar o círculo colorido
	queue_redraw()
	
	# 3. Ativa a explosão de poeira (Partículas)
	var particulas = get_node_or_null("GPUParticles2D")
	if particulas:
		particulas.emitting = true

# --- SISTEMA DE DESENHO (_draw) ---
# O Godot chama isso automaticamente quando usamos queue_redraw()
func _draw():
	# Desenha o fundo preenchido (transparente)
	draw_circle(Vector2.ZERO, raio_visual, cor_fundo)
	
	# Desenha a borda (Anel)
	# draw_arc(centro, raio, angulo_inicio, angulo_fim, qualidade, cor, espessura)
	draw_arc(Vector2.ZERO, raio_visual, 0, TAU, 64, cor_borda, espessura_anel)

# --- SISTEMA DE FÍSICA ---
func _atualizar_tamanho_fisico():
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape:
		# Se o shape não for círculo ou não existir, cria um novo
		if not col_shape.shape is CircleShape2D:
			col_shape.shape = CircleShape2D.new()
		
		# Define o raio da colisão igual ao raio do desenho
		col_shape.shape.radius = raio_visual
	else:
		print("ALERTA: AreaPisao sem CollisionShape2D filho!")

# --- LÓGICA DE COMBATE ---
func _apply_effect(body):
	# Só afeta inimigos
	if body.is_in_group("enemies"):
		_aplicar_combo(body)
		
		# Devolve Tenacidade para o Balpo (Caster)
		if is_instance_valid(caster) and caster.has_method("ganhar_tenacidade"):
			caster.ganhar_tenacidade(tenacidade_por_hit)

func _aplicar_combo(inimigo):
	# 1. Knockup (Levantar) visual
	if inimigo.has_method("apply_knockup"):
		inimigo.apply_knockup(Vector2.UP * 50, 0.5)
	
	# Pequeno delay enquanto o inimigo "sobe"
	await get_tree().create_timer(0.2).timeout
	
	# Verifica se o inimigo ainda existe (não morreu no meio do caminho)
	if is_instance_valid(inimigo):
		
		# 2. Aplica o Dano
		if inimigo.has_method("take_damage"):
			inimigo.take_damage(dano_calculado)
		
		# 3. Aplica o Stun
		if inimigo.has_method("apply_stun"):
			inimigo.apply_stun(2.0) # Stun de 2 segundos
