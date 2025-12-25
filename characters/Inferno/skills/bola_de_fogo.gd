extends Area2D

# --- Configurações de Combate ---
@export var speed = 200
@export var dano_explosao = 20        # Dano que causa na hora que explode
@export var raio_explosao = 80.0      # Tamanho da área que a explosão atinge

# --- Configuração Visual ---
# Se sua animação for pequena, aumente este valor (ex: x=3, y=3)
@export var escala_visual_explosao = Vector2(2.5, 2.5) 

# --- Referências ---
# Confere se este caminho está certo para a sua pasta!
const CENA_ZONA = preload("res://characters/Inferno/skills/ZonaFogo.tscn")

var ja_explodiu = false

func _ready():
	# Começa tocando a animação da bola voando
	# Certifique-se que o nome na lista de animações é "voando"
	$AnimatedSprite2D.play("voando")

func _physics_process(delta):
	# A bola só anda se ainda não tiver batido em nada
	if not ja_explodiu:
		position += transform.x * speed * delta



func explodir_area():
	# Pega todos os inimigos da fase
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	
	for inimigo in inimigos:
		# Mede a distância entre a explosão e o inimigo
		var distancia = global_position.distance_to(inimigo.global_position)
		
		# Se estiver dentro do raio, toma dano!
		if distancia <= raio_explosao:
			if inimigo.has_method("take_damage"):
				inimigo.take_damage(dano_explosao)
				# print("BUM! Acertou: ", inimigo.name)

func criar_zona():
	var zona = CENA_ZONA.instantiate()
	zona.global_position = global_position
	
	# (Opcional) Passa o tamanho do raio para a zona desenhar igual à explosão
	# Só funciona se você tiver "var raio_visual" lá no script da zona
	if "raio_visual" in zona:
		zona.raio_visual = raio_explosao
		
	# Adiciona na cena principal para não sumir
	get_tree().current_scene.add_child(zona)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _on_body_entered(body: Node2D):
	if ja_explodiu: return
	
	if body is ClassPlayer and body.name == "Inferno": 
		return

	ja_explodiu = true 
	
	explodir_area()
	
	$AnimatedSprite2D.play("explosao")
	$AnimatedSprite2D.scale = escala_visual_explosao 
	
	await $AnimatedSprite2D.animation_finished
	
	criar_zona()
	queue_free()
