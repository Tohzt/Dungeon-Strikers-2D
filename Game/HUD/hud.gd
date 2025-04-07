extends CanvasLayer
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var mana_bar: TextureProgressBar = $ManaBar
@onready var player_icon: TextureRect = $PlayerIcon

func set_hud(col: Color, hp_max: int) -> void:
	player_icon.modulate = col
	health_bar.max_value = hp_max

func update(rot: float, hp: int) -> void:
	player_icon.rotation = rot
	health_bar.value = hp
