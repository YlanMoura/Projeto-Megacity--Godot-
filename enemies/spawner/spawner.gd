extends Node2D

@export_group("Configurações")
@export var enemy_scene: PackedScene # Arraste a cena do inimigo (tscn) para cá
@export var spawn_interval: float = 2.0 # Tempo entre cada inimigo
@export var spawn_radius: float = 300.0 # Raio da área de spawn
@export var max_enemies: int = 10 # Limite para não travar o PC

@export_group("Alvo")
# Se quiser forçar um alvo específico, senão ele busca automático
@export var forced_target: Node2D 

var timer: Timer
var enemies_alive = []

func _ready():
	# Configura o timer via código
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	# Limpa a lista de inimigos mortos (que viraram null)
	enemies_alive = enemies_alive.filter(func(e): return is_instance_valid(e))
	
	if enemies_alive.size() >= max_enemies:
		return # Já tem inimigo demais, espera matarem alguns
		
	spawn_enemy()

func spawn_enemy():
	if enemy_scene == null:
		print("ERRO: Nenhuma cena de inimigo definida no Spawner!")
		return

	var enemy = enemy_scene.instantiate()
	
	# 1. Escolhe posição aleatória em volta do Spawner
	var random_angle = randf() * TAU # 360 graus
	var random_dist = randf_range(0, spawn_radius)
	var offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
	
	enemy.global_position = global_position + offset
	
	# 2. Define o alvo (Busca o Player Ativo)
	enemy.target = find_active_player()
	
	# 3. Adiciona na cena principal (não dentro do spawner, para organizar)
	get_tree().current_scene.add_child(enemy)
	enemies_alive.append(enemy)

func find_active_player():
	if forced_target: return forced_target
	
	# Procura na árvore de nós pelos personagens
	# (Assume que seus players estão num grupo "players" ou busca por tipo)
	var nodes = get_tree().get_nodes_in_group("players") # <--- Lembre de adicionar os players neste grupo!
	
	# Se não tiver grupo, tenta achar o nó "Inferno" ou "Luka" manualmente:
	if nodes.is_empty():
		return get_tree().current_scene.get_node_or_null("Inferno") # Ajuste o nome conforme sua cena
		
	# Retorna o primeiro que estiver ativo
	for node in nodes:
		if node.has_method("set_active") and node.is_active:
			return node
			
	return null # Ninguém encontrado
