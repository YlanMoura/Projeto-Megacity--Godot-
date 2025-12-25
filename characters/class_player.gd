class_name ClassPlayer extends CharacterBody2D

# --- STATUS ---
@export_group("Status")
@export var max_health: int = 100
var current_health: int

# --- MOVIMENTO E DASH ---
@export_group("Movimento")
@export var speed: float = 400.0
@export_group("Dash")
@export var dash_speed: float = 1000.0
@export_group("Dash Duration") # Organizei os nomes para o Inspector
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.5
@export var max_dashes: int = 1
var current_dashes: int = 0
var is_dashing: bool = false 

# --- HABILIDADES ---
@export_group("Habilidades")
@export var skill_1_cooldown: float = 3.0
var can_use_skill_1: bool = true

# --- INTERFACE (UI TEMPORÁRIA) ---
# Removemos a health_bar_scene e usamos um Label direto
var vida_label: Label 

const FLOATING_NUMBER_SCENE = preload("res://UI/floating_number.tscn")

func _ready():
	current_health = max_health
	current_dashes = max_dashes
	
	# Configurações de colisão padrão
	set_collision_mask_value(1, true)
	set_collision_mask_value(4, true)
	set_collision_mask_value(3, true)
	
	# Criar o texto de vida via código (sem precisar de cena externa)
	vida_label = Label.new()
	add_child(vida_label)
	vida_label.position = Vector2(-20, -70) # Posição acima da cabeça
	actualizar_ui_vida()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill1") and can_use_skill_1:
		attempt_skill_1()

func attempt_skill_1():
	if not can_use_skill_1 or is_dashing: return
	can_use_skill_1 = false
	execute_skill_1_logic()
	await get_tree().create_timer(skill_1_cooldown).timeout
	can_use_skill_1 = true

func execute_skill_1_logic():
	pass # Sobrescrito pelo Inferno.gd ou Skye.gd

func recharge_one_dash():
	await get_tree().create_timer(dash_cooldown).timeout
	if current_dashes < max_dashes:
		current_dashes += 1

# --- SISTEMA DE VIDA ---
func take_damage(amount: int):
	current_health -= amount
	actualizar_ui_vida()
	mostrar_texto_flutuante(amount, "dano")
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	actualizar_ui_vida()
	mostrar_texto_flutuante(amount, "cura")

# Agora atualiza apenas o texto simples
func actualizar_ui_vida():
	if vida_label:
		vida_label.text = str(current_health) + " / " + str(max_health)
		# Muda para vermelho se estiver morrendo
		if current_health < max_health * 0.25:
			vida_label.modulate = Color.RED
		else:
			vida_label.modulate = Color.WHITE

func die():
	get_tree().reload_current_scene()

func mostrar_texto_flutuante(valor: int, tipo: String):
	if FLOATING_NUMBER_SCENE:
		var texto = FLOATING_NUMBER_SCENE.instantiate()
		get_tree().current_scene.add_child(texto)
		texto.global_position = global_position + Vector2.UP * 40
		texto.setup(valor, tipo)
