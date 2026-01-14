extends ClassWeapon 

@export_group("Configurações de Shotgun")
@export var quantidade_pellets: int = 8 #Número de projéteis por tiro
@export var dispersao: float = 0.2 # O "espalhamento" das balas

@export_group("Configurações de Mundo")
@export var esta_no_chao: bool = true # Se true, ela não atira, apenas espera ser coletada

@onready var area_interacao: Area2D = $Area2D #Você precisará adicionar esse nó na cena
@onready var ui_info: Control = $LootCard     # Um nó de UI para o cartão de info



func _ready():
	super._ready() # Importante: Executa a busca pelo player que está no pai
	# Você pode customizar atributos específicos aqui
	nome_arma = "Conference Call"

#Sobreescrevemos a função disparar para o comportamento de escopeta
func disparar():
	pode_atirar = false
	munição_atual -= 1

	print("--- DISPARO DE SHOTGUN ---")

#Loop para simular cada pellet da escopeta

	for i in range(quantidade_pellets):
		var resultado = player.calculate_damage(dano_base, "atk")
		var dano_final = resultado["value"]
		var foi_critico = resultado["critical"]

		#  No futuro, aqui você instanciaria o projétil
		#e aplicaria a 'dispersao'' no ângulo dele
		print("Pellet ", i+1, "-> Dano: ", dano_final, "Crit: ", foi_critico)
		
		#Espera a cadência antes de permitir o próximo tiro
		await get_tree().create_timer(cadencia_tiro).timemout
		pode_atirar = true
