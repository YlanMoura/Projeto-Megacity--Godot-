extends Area2D

var velocidade = 900.0
var direcao = Vector2.RIGHT
var dados_dano = {} 
var shooter = null  
var posicao_inicial = Vector2.ZERO # Para calcular a passiva

# Configurações do tiro
var is_perfurante = false
var causa_lentidao = false
var inimigos_atingidos = [] 

func setup(dir, dados, dono, perfura: bool, slow: bool):
	direcao = dir
	dados_dano = dados
	shooter = dono
	is_perfurante = perfura
	causa_lentidao = slow
	
	# Salva de onde saiu para calcular a distância depois
	posicao_inicial = global_position
	look_at(global_position + direcao)

func _physics_process(delta):
	position += direcao * velocidade * delta

func _on_body_entered(body):
	if body == shooter: return
	
	if body.has_method("take_damage"):
		if is_perfurante and body in inimigos_atingidos:
			return
		
		# --- CÁLCULO DA PASSIVA (PRECISÃO FRÍGIDA) ---
		var distancia = posicao_inicial.distance_to(body.global_position)
		var dano_base = dados_dano["damage"]
		
		# Bônus: 0.1% por pixel (ex: 300px = +30% de dano)
		# Limitamos a 30% (0.3) para não quebrar o jogo
		var multiplicador_distancia = clamp(distancia * 0.001, 0.0, 0.3)
		
		var dano_final = int(dano_base * (1.0 + multiplicador_distancia))
		
		# Debug visual para você ver a passiva funcionando
		# print("Distância: ", int(distancia), " | Bônus: ", int(multiplicador_distancia * 100), "%")
		
		# Aplica o Dano Final
		body.take_damage(dano_final)
		
		# Aplica Lentidão
		if causa_lentidao and "stats" in body:
			aplicar_slow(body)
		
		if not is_perfurante:
			queue_free()
		else:
			inimigos_atingidos.append(body)

func aplicar_slow(body):
	# Se o inimigo tiver stats de velocidade, reduz
	if body.stats.has("speed"):
		body.stats["speed"] *= 0.5 # 50% de slow
		body.modulate = Color.CYAN
		
		# Cria um timer temporário na árvore para limpar o efeito
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func():
			if is_instance_valid(body):
				body.stats["speed"] /= 0.5
				body.modulate = Color.WHITE
		)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
