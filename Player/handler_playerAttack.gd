class_name PlayerAttackHandler extends HandlerClass
@export var Input_Handler: HandlerClass

var can_attack: bool = true
var attack_confirmed: bool= false
var attack_cooldown: float = 0.0
var attack_cooldown_max: float= 0.25
var attack_direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if !Master.has_authority: return
	attack_direction = Input_Handler.input_direction
	attack_confirmed = Input_Handler.input_confirmed
	_handle_attack_cooldown(delta)
	_handle_attack()

func _handle_attack_cooldown(delta: float) -> void:
	if !can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true

func _handle_attack() -> void:
	if attack_confirmed:
		Input_Handler.input_confirmed = false 
		can_attack = false
		attack_cooldown = attack_cooldown_max
		Master.attack.rpc(attack_direction)
