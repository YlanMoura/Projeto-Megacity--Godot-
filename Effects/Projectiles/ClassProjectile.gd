class_name ClassProjectile extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 5.0
@export var penetrate_enemies: bool = false 

# Não precisamos mais da variável 'direction' para o movimento, 
# vamos confiar na Rotação do objeto (transform.x)
var damage_info: Dictionary = {"value": 0, "critical": false}

func _ready():
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)
	
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("voando")

func _physics_process(delta):
	# AQUI ESTÁ A MUDANÇA PARA FICAR IGUAL AO SEU ANTIGO:
	# Ele se move baseado na rotação atual do objeto
	position += transform.x * speed * delta

# Função de Setup atualizada
func setup(dir: Vector2, dmg_data: Dictionary):
	damage_info = dmg_data
	
	# O setup agora apenas gira o objeto para a direção certa.
	# O _physics_process vai ler essa rotação e mover para frente.
	rotation = dir.angle() 

func _on_body_entered(body):
	if body is ClassPlayer: return 
	on_impact(body)

func on_impact(body):
	if body.has_method("take_damage"):
		body.take_damage(damage_info["value"])
	if not penetrate_enemies:
		queue_free()
