class_name PlayerAttackHandler extends Node
@onready var Master: PlayerClass = get_parent()
@export var Input_Handler: PlayerInputHandler

var attack_cooldown: float = 0.0
var attack_cooldown_max: float= 0.25
var attack_confirmed: bool = false
var attack_side: String

func _process(delta: float) -> void:
	_handle_attack_cooldown(delta)

func _handle_attack_cooldown(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	else:
		_handle_attack()

func _handle_attack() -> void:
	if Input_Handler.attack_left:
		Input_Handler.attack_left = false
		attack_cooldown = attack_cooldown_max
		attack_confirmed = true
		attack_side = "left"
	
	elif Input_Handler.attack_right:
		Input_Handler.attack_right = false
		attack_cooldown = attack_cooldown_max
		attack_confirmed = true
		attack_side = "right"
