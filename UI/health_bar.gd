extends Control # Ou Node2D, dependendo do nó raiz da sua cena de barra

func _process(_delta):
	# Mantém a barra horizontal mesmo se o player girar
	
	# Mantém a escala constante mesmo se o player mudar de tamanho
	if get_parent():
		scale = Vector2(1, 1) / get_parent().scale.abs()
