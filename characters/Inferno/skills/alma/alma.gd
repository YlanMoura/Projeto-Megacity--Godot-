extends Area2D

var alvo = null
var velocidade = 400.0
var aceleracao = 10.0
var velocidade_atual = Vector2.ZERO

func _ready():
	# Começa pequeno e cresce (efeito visual)
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3)

func setup(novo_alvo):
	alvo = novo_alvo

func _physics_process(delta):
	if alvo == null:
		queue_free() # Se o Inferno morreu, a alma some
		return

	# Lógica de perseguição (Míssil Teleguiado)
	var direcao = global_position.direction_to(alvo.global_position)
	
	# Aumenta a velocidade aos poucos para dar um efeito de "atração magnética"
	velocidade += aceleracao 
	global_position += direcao * velocidade * delta
	
	# Checa se chegou perto o suficiente (Colisão manual)
	if global_position.distance_to(alvo.global_position) < 20:
		entregar_alma()

func entregar_alma():
	if alvo.has_method("receber_alma"):
		alvo.receber_alma()
	
	# Efeito visual antes de sumir (opcional)
	queue_free()
