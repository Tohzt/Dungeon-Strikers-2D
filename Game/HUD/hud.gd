class_name HUDClass extends CanvasLayer
@export var game: GameClass

@onready var health_bar:  TextureProgressBar = $HealthBar
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var mana_bar:    TextureProgressBar = $ManaBar
@onready var player_icon: TextureRect        = $PlayerIcon


func set_hud() -> void:
	player_icon.modulate  = game.Player.Properties.player_color
	health_bar.max_value  = game.Player.hp_max
	health_bar.value      = game.Player.hp
	stamina_bar.max_value = game.Player.stamina_max
	stamina_bar.value     = game.Player.stamina
	mana_bar.max_value    = game.Player.mana_max
	mana_bar.value        = game.Player.mana

##TODO: Update bar vaulues via signals
func _process(delta: float) -> void:
	player_icon.rotation = game.Player.rotation
	
	var health_value_new  := game.Player.hp/game.Player.hp_max           * health_bar.max_value
	var stamina_value_new := game.Player.stamina/game.Player.stamina_max * stamina_bar.max_value
	var mana_value_new    := game.Player.mana/game.Player.mana_max       * mana_bar.max_value
	
	health_bar.value  = lerp(health_bar.value,  health_value_new, delta*10)
	stamina_bar.value = lerp(stamina_bar.value, stamina_value_new, delta*10)
	mana_bar.value    = lerp(mana_bar.value,    mana_value_new, delta*10)
	
