extends ClassPlayer

func _ready():
	super._ready() 
func _physics_process(delta):
	super(delta)
	
	if not is_active: 
		return
	if Input.is_key_pressed(KEY_K):
		take_damage(10)
		
	
