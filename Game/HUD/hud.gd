class_name HUDClass extends CanvasLayer
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var mana_bar: TextureProgressBar = $ManaBar
@onready var player_icon: TextureRect = $PlayerIcon
@export var game: GameClass


func set_hud() -> void:
	player_icon.modulate = game.Player.Properties.player_color
	health_bar.max_value = game.Player.hp_max
	health_bar.value = game.Player.hp
	stamina_bar.max_value = game.Player.stamina_max
	stamina_bar.value = game.Player.stamina_current
	mana_bar.max_value = game.Player.intelligence
	mana_bar.value = game.Player.intelligence

##TODO: Update bar vaulues via signals
func _process(delta: float) -> void:
	player_icon.rotation = game.Player.rotation
	health_bar.value = game.Player.hp/game.Player.hp_max*health_bar.max_value
	
	# Update stamina bar in real-time
	var stamina_value_new := game.Player.stamina_current/stamina_bar.max_value*stamina_bar.max_value
	stamina_bar.value = lerp(stamina_bar.value, stamina_value_new, delta*10)
