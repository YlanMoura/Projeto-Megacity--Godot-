extends Line2D

@export var length = 30 # Tamanho do rastro (quantos pontos ele guarda)

func _ready():
	top_level = true 
	
	
	clear_points()

func _physics_process(delta):
	
	var arrow = get_parent()
	
	if is_instance_valid(arrow):
		
		add_point(arrow.global_position)
		
		
		if points.size() > length:
			remove_point(0)
	else:
		
		queue_free()
