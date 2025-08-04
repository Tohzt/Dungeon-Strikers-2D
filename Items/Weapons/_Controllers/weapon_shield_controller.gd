class_name ShieldController extends WeaponControllerBase

var is_blocking: bool = false


func handle_click(shield: WeaponClass) -> void:
	super.handle_click(shield)
func handle_hold(shield: WeaponClass) -> void:
	super.handle_hold(shield)
	is_blocking = true
func handle_release(shield: WeaponClass) -> void:
	super.handle_release(shield)
	is_blocking = false


func update(shield: WeaponClass, delta: float) -> void:
	var hand := get_hand(shield)
	if !hand: return
	
	if is_blocking:
		var block_rotation := deg_to_rad(180)
		var block_position := get_default_arm_length(shield) * 0.6
		set_arm_rotation(shield, block_rotation, delta, 8.0)
		set_arm_position(shield, block_position, delta, 8.0)
	else:
		reset_arm_rotation(shield, delta, 8.0)
		reset_arm_position(shield, delta, 8.0) 
