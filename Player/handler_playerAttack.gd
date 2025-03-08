class_name PlayerAttackHandler extends HandlerClass

var can_attack: bool = true  # Flag to determine if player can attack
var attack_confirmed: bool= false  # Flag to track if attack button is pressed
var attack_cooldown: float = 0.0  # Timer to track attack cooldown
var attack_cooldown_max: float= 0.5  # Time in seconds before player can attack again
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
		attack_confirmed = false  # Only apply impulse once per click
		can_attack = false
		attack_cooldown = attack_cooldown_max
		# Check if we are connected before calling RPC
		if multiplayer.has_multiplayer_peer():
			Master.attack.rpc(multiplayer.get_unique_id(), attack_direction)
		else:
			push_error("Cannot attack: No multiplayer peer")
