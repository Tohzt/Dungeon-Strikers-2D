class_name PlayerAttackHandler extends HandlerClass
@export var Input_Handler: HandlerClass

var attack_cooldown: float = 0.0
var attack_cooldown_max: float= 0.25
var attack_confirmed: bool = false

func _process(delta: float) -> void:
	_handle_attack_cooldown(delta)

func _handle_attack_cooldown(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	else:
		_handle_attack()

func _handle_attack() -> void:
	if Input_Handler.input_confirmed:
		Input_Handler.input_confirmed = false
		attack_cooldown = attack_cooldown_max
		attack_confirmed = true
