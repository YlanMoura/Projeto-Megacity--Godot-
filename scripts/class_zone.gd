class_name ZoneEffect extends Area2D
# O comando 'class_name' acima permite que o Godot reconheça
# esse script como um TIPO novo, assim como existe 'Sprite2D' ou 'Node'.

# --- Configurações Gerais ---
@export var duration: float = 0.0 # Tempo de vida (0 = infinito)

# --- Variáveis de Controle ---
var caster = null # Quem soltou a skill (Player ou Inimigo)
var targets_inside: Array = [] # Lista de quem está dentro da área

func _ready():
	# Conecta os sinais de colisão automaticamente via código.
	# Assim você não precisa conectar manualmente toda vez que criar uma magia nova.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Se tiver duração, liga o cronômetro da morte
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		_end_effect()

# --- Lógica Interna (Não mexer nas classes filhas) ---
func _on_body_entered(body):
	# Regra de Segurança: A magia não afeta quem a soltou
	if body == caster: 
		return 
	
	targets_inside.append(body)
	_apply_effect(body) # Chama a função específica da magia

func _on_body_exited(body):
	if body in targets_inside:
		targets_inside.erase(body)
		_remove_effect(body) # Remove o efeito específico

func _end_effect():
	# Antes da magia sumir, remove o efeito de todo mundo que ainda tá dentro
	for body in targets_inside:
		if is_instance_valid(body):
			_remove_effect(body)
	
	queue_free() # Destroi o objeto

# --- Funções "Ocas" (Interface) ---
# As classes filhas (Gelo, Veneno, Fogo) vão escrever por cima dessas funções.
# Aqui elas ficam vazias (pass) só para o Godot não dar erro.

func _apply_effect(body):
	pass 

func _remove_effect(body):
	pass
