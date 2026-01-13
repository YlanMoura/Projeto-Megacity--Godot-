# pistola.gd
extends BaseWeapon # Herda tudo da sua classe Weapon

@onready var muzzle = $Marker2D # O ponto que você criou na cena

# Preload da bala que esta arma vai usar
const BULLET_SCENE = preload("res://weapons/bullet.tscn")

func execute(direction: Vector2):
	# Instancia a bala
	var bullet = BULLET_SCENE.instantiate()
	
	# Define a posição inicial no Marker2D da pistola
	bullet.global_position = muzzle.global_position
	
	# Define a direção (a bala viaja para onde a arma está apontada)
	bullet.rotation = direction.angle()
	
	# Passa o dano da arma para a bala (opcional)
	if "damage" in bullet:
		bullet.damage = damage
	
	# Adiciona à cena principal para a bala não "girar" junto com a arma
	get_tree().current_scene.add_child(bullet)
