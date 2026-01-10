extends Label

# Configurações da animação
@export var altura_subida: float = 50.0
@export var duracao: float = 0.8

func _ready():
	# Centraliza o texto no ponto onde ele nasce
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Começa a animação assim que nasce
	animar_e_morrer()

# Função que o Luka vai chamar para configurar o número
func setup(valor: int, tipo: String):
	text = str(valor)
	
	if tipo == "dano":
		modulate = Color(1, 0.2, 0.2) # Vermelho vivo
	elif tipo == "cura":
		modulate = Color(0.2, 1, 0.2) # Verde vivo
	elif tipo == "escudo":
		modulate = Color.CYAN 
		

func animar_e_morrer():
	# Cria um Tween (o animador de código)
	var tween = create_tween()
	
	# Faz as duas animações ao mesmo tempo (subir e desaparecer)
	tween.set_parallel(true)
	
	# 1. Sobe: Move da posição atual para 50 pixels pra cima
	var destino_final = position + Vector2.UP * altura_subida
	tween.tween_property(self, "position", destino_final, duracao)
	
	# 2. Desaparece: Muda o Alpha (transparência) do modulate para 0
	# O set_ease(Tween.EASE_IN) faz ele sumir mais rápido no final
	tween.tween_property(self, "modulate:a", 0.0, duracao).set_ease(Tween.EASE_IN)
	
	# Quando o tween acabar, espera as paralelas terminarem e deleta o nó
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
