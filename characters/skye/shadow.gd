extends Node2D

var target = null # O Skye original
var velocidade = 1500.0 # Velocidade que a sombra corre atrás

# Pega a referência do Sprite da sombra para podermos espelhar (flip)
# GARANTA QUE NA CENA DA SOMBRA O SPRITE SE CHAME "Visual"
@onready var visual_sprite = $Visual

func _ready():
	# --- EFEITO SILHUETA ---
	# A mágica acontece aqui!
	# Color(Vermelho, Verde, Azul, Alpha/Transparência)
	# Tudo zero é preto. Alpha 0.7 deixa um pouco transparente (fantasmagórico).
	modulate = Color(0, 0, 0, 0.7) 
	
	# Se quiser um tom azulado escuro tipo "sombra da noite":
	# modulate = Color(0.1, 0.1, 0.3, 0.7)

func _physics_process(delta):
	if target == null:
		return
		
	# --- COPIAR A DIREÇÃO ---
	# Verifica para onde o Skye está olhando e aplica na sombra
	if visual_sprite and is_instance_valid(target):
		# Se o Skye vira usando transform.x.x (como está no seu script):
		transform.x.x = target.transform.x.x
		
		# (OBS: Se o visual da sombra for um AnimatedSprite2D, ele 
		# deve tentar tocar a mesma animação do target automaticamente 
		# se os SpriteFrames forem iguais, mas a direção garantimos aqui).

	# --- MOVIMENTO (Igual antes) ---
	global_position = global_position.move_toward(target.global_position, velocidade * delta)
	
	if global_position.distance_to(target.global_position) < 10:
		queue_free()
