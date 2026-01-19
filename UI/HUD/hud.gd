extends CanvasLayer

# --- REFERÊNCIAS ---
@onready var retrato_rect: TextureRect = $MarginContainer/PanelContainer/HBoxContainer/TextureRect
@onready var bar_hp: ProgressBar = $MarginContainer/PanelContainer/HBoxContainer/VBoxContainer/ProgressBar
@onready var label_valor_vida: Label = $MarginContainer/PanelContainer/HBoxContainer/VBoxContainer/ProgressBar/Label_Valor_Vida
@onready var bar_shield: ProgressBar = $MarginContainer/PanelContainer/HBoxContainer/VBoxContainer/ProgressBar2
@onready var label_valor_shield: Label = $MarginContainer/PanelContainer/HBoxContainer/VBoxContainer/ProgressBar2/Label_Valor_Shield

# Labels de Atributos
@onready var label_atk: Label = $MarginContainer/PanelContainer/HBoxContainer/VBoxContainer/GridContainer/Label_ATK
@onready var label_ph: Label = $MarginContainer/PanelContainer/HBoxContainer/VBoxContainer/GridContainer/Label_PH
@onready var label_crit_chance: Label = $MarginContainer/PanelContainer/HBoxContainer/VBoxContainer/GridContainer/Label_CritChance
@onready var label_crit_dmg: Label = $MarginContainer/PanelContainer/HBoxContainer/VBoxContainer/GridContainer/Label_CritDmg

var player_focado: ClassPlayer = null

func _process(_delta: float) -> void:
	# Agora verificamos TUDO a cada frame
	if is_instance_valid(player_focado):
		_atualizar_interface_completa()

func conectar_no_player(novo_player: ClassPlayer):
	player_focado = novo_player
	
	# Atualiza a foto (só precisa fazer isso na troca)
	if retrato_rect:
		if novo_player.retrato:
			retrato_rect.texture = novo_player.retrato
		else:
			retrato_rect.texture = null
	
	# Atualiza os máximos das barras (HP Max muda pouco, mas se tiver item de vida, ajuda)
	bar_hp.max_value = novo_player.stats["max_hp"]
	bar_shield.max_value = novo_player.stats["max_shield"]

func _atualizar_interface_completa():
	var stats = player_focado.stats
	
	
	label_atk.text = "⚔️ ATK: " + str(stats["atk"])
	label_ph.text = "✨ PH: " + str(stats["PH"])
	
	
	var crit_c = snapped(stats["crit_chance"] * 100, 0.1)
	var crit_d = snapped(stats["crit_damage"] * 100, 0.1)
	
	label_crit_chance.text = "🎯 Crit: " + str(crit_c) + "%"
	label_crit_dmg.text = "💥 Dmg: " + str(crit_d) + "%"

	# --- 2. ATUALIZAÇÃO DAS BARRAS (VIDA E ESCUDO) ---
	bar_hp.value = player_focado.current_health
	label_valor_vida.text = "%d / %d" % [player_focado.current_health, stats["max_hp"]]
	
	bar_shield.value = player_focado.current_shield
	label_valor_shield.text = "%d / %d" % [player_focado.current_shield, stats["max_shield"]]
	
	# Efeito visual para quando o escudo quebra
	if player_focado.current_shield <= 0:
		bar_shield.modulate = Color(1, 1, 1, 0.3)
	else:
		bar_shield.modulate = Color(1, 1, 1, 1)
