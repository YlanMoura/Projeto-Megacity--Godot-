extends CharacterBody2D

# --- Configuration ---
@export var shadow_scene : PackedScene
var is_active = false
@onready var camera = $Camera2D

# Movement Settings
@export var speed = 600.0
@export var dash_speed = 1500
@export var dash_duration = 0.2
@export var dash_cooldown = 1.5
@export var max_dashes: int = 2

# Health Settings
@export var max_health: int = 80

# --- Attack Variables (Renomeadas) ---
# Mantive $AreaAtaque para não quebrar seu projeto, 
# mas no código chamaremos de attack_area
@onready var attack_area = $AreaAtaque 
@onready var attack_visual = $AreaAtaque/Polygon2D

# --- Control Variables ---
var is_attacking = false
var current_dashes = 0
var is_dashing = false
var current_health : int = 0

func _ready():
	current_dashes = max_dashes
	current_health = max_health
	
	# Setup inicial
	if attack_visual: attack_visual.visible = false
	if attack_area: attack_area.monitoring = false

func _physics_process(delta):
	if not is_active:
		return
	
	if speed == null: speed = 600.0

	var direction = Input.get_vector("esquerda", "direita", "cima", "baixo")
	
	# Dash Input
	if Input.is_action_just_pressed("dash") and current_dashes > 0 and direction != Vector2.ZERO:
		start_dash() 
	
	# Attack Input
	if Input.is_action_just_pressed("ataque") and not is_attacking:
		attack() # Chama a nova função em inglês

	# Test Damage Key
	if Input.is_key_pressed(KEY_K):
		take_damage(10) 
		
	var current_speed = speed
	if is_dashing:
		current_speed = dash_speed

	if direction:
		velocity = direction * current_speed
		
		# Flip sprite
		if direction.x > 0:
			transform.x.x = 1
		elif direction.x < 0:
			transform.x.x = -1
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	
	move_and_slide()

# --- ATTACK FUNCTION (Padronizada) ---
func attack():
	if is_attacking: return
	is_attacking = true
	
	# Liga visual e colisão
	if attack_visual: attack_visual.visible = true
	if attack_area: 
		attack_area.monitoring = true
	
	# Delay físico (importante para detectar colisão)
	await get_tree().process_frame
	await get_tree().process_frame 
	
	# Lógica de Dano
	if attack_area:
		var bodies = attack_area.get_overlapping_bodies()
		
		for body in bodies:
			# Agora procuramos pela função em INGLÊS no inimigo
			if body.has_method("take_damage") and body != self:
				body.take_damage(25)
				print("Hit enemy!")
	
	# Tempo da animação
	await get_tree().create_timer(0.3).timeout
	
	# Reset
	if attack_visual: attack_visual.visible = false
	if attack_area: attack_area.monitoring = false
	is_attacking = false

# --- OTHER FUNCTIONS ---
func start_dash():
	var start_pos = global_position
	var old_mask = collision_mask 
	collision_mask = 0 
	current_dashes -= 1
	spawn_shadow_delayed(start_pos)
	is_dashing = true
	recharge_one_dash()
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	collision_mask = old_mask 

func recharge_one_dash():
	await get_tree().create_timer(dash_cooldown).timeout
	if current_dashes < max_dashes:
		current_dashes += 1

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		die()

func heal(amount:int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health

func die():
	print("Player Died!")
	get_tree().reload_current_scene()

func set_active(state: bool):
	is_active = state
	camera.enabled = state 
	if state == true:
		camera.make_current() 

func spawn_shadow_delayed(start_pos):
	await get_tree().create_timer(0.2).timeout 
	if shadow_scene == null: return
	var shadow = shadow_scene.instantiate()
	get_parent().add_child(shadow)
	shadow.global_position = start_pos
	shadow.target = self
	# shadow.target = self (se seu script de sombra usar 'target' agora)
