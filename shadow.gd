extends Node2D

var target = null # Quem eu devo seguir? (Vai ser o Skye)
var velocidade = 1500.0 # <--- AQUI VOCÊ CONTROLA A VELOCIDADE (SPEED)!

func _physics_process(delta):
	# Se não tiver alvo definido, não faz nada
	if target == null:
		return
		
	# A Mágica: Move a posição atual em direção ao alvo
	# move_toward(destino, o_quanto_andar_nesse_frame)
	global_position = global_position.move_toward(target.global_position, velocidade * delta)
	
	# Se chegou muito perto (distância menor que 10 pixels), some
	if global_position.distance_to(target.global_position) < 10:
		queue_free()
