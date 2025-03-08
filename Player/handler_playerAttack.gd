class_name PlayerAttackHandler extends HandlerClass

var can_attack: bool = true
var attack_confirmed: bool= false
var attack_cooldown: float = 0.0
var attack_cooldown_max: float= 0.5
var attack_direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if !Master.has_authority: return
	_handle_attack_cooldown(delta)
	_handle_attack()

func _handle_attack_cooldown(delta: float) -> void:
	if !can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true

func _handle_attack() -> void:
	if attack_confirmed:
		attack_confirmed = false 
		can_attack = false
		attack_cooldown = attack_cooldown_max
		Master.attack.rpc(attack_direction)
