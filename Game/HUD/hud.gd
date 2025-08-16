class_name HUDClass extends CanvasLayer
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var mana_bar: TextureProgressBar = $ManaBar
@onready var player_icon: TextureRect = $PlayerIcon
@export var game: GameClass


func set_hud() -> void:
	player_icon.modulate = game.Player.Properties.player_color
	health_bar.max_value = game.Player.strength
	health_bar.value = game.Player.strength
	stamina_bar.max_value = game.Player.endurance
	stamina_bar.value = game.Player.endurance
	mana_bar.max_value = game.Player.intelligence
	mana_bar.value = game.Player.intelligence

##TODO: Update bar vaulues via signals
func _process(_delta: float) -> void:
	player_icon.rotation = game.Player.rotation
	health_bar.value = game.Player.hp/game.Player.hp_max*health_bar.max_value
