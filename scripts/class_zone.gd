class_name ZoneEffect extends Area2D

# --- Configurações Gerais ---
@export var duration: float = 5.0     # Tempo de vida total
@export var tick_rate: float = 0.5    # Tempo entre cada "pulso" (0 = desativado)
@export var affects_caster: bool = true # Se 'false', o dono não é afetado

# --- Variáveis de Controle ---
var caster = null 
var targets_inside: Array = [] 
var tick_timer: Timer = null # Timer interno para controlar os pulsos

func _ready():
	# Conexões automáticas
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Configura a morte da zona
	if duration > 0:
		get_tree().create_timer(duration).timeout.connect(_end_effect)
	
	# Configura o sistema de Ticks (Dano/Cura por segundo)
	if tick_rate > 0:
		tick_timer = Timer.new()
		tick_timer.wait_time = tick_rate
		tick_timer.autostart = true
		tick_timer.timeout.connect(_on_tick) # Chama a função de pulso
		add_child(tick_timer)

# --- Lógica de Entrada/Saída ---
func _on_body_entered(body):
	# --- LINHA DE DEBUG ---
	print("A Zona ", name, " encostou em: ", body.name) 
	# ----------------------
	# Trava opcional: Se affects_caster for false, ignora o dono
	if not affects_caster and body == caster:
		return
	
	targets_inside.append(body)
	_apply_effect(body) # Efeito imediato (ex: aplicar Slow)

func _on_body_exited(body):
	if body in targets_inside:
		targets_inside.erase(body)
		_remove_effect(body) # Remover efeito (ex: tirar Slow)

func _end_effect():
	for body in targets_inside:
		if is_instance_valid(body):
			_remove_effect(body)
	queue_free()

# --- INTERFACE (As filhas mexem aqui) ---

# 1. Chamado quando entra (Buffs, Slows)
func _apply_effect(body):
	pass 

# 2. Chamado quando sai (Remover Buffs, Slows)
func _remove_effect(body):
	pass

# 3. Chamado a cada X segundos (Dano, Cura) <--- NOVO!
func _on_tick():
	# Por padrão, aplica o efeito de tick em todo mundo que tá dentro
	for body in targets_inside:
		if is_instance_valid(body):
			_tick_effect(body)

# 4. A lógica individual do Dano/Cura
func _tick_effect(body):
	pass
