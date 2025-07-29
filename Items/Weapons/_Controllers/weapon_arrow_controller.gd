class_name ArrowController extends WeaponControllerBase

var default_angle: float
var is_in_ready_position: bool = false


func handle_click(weapon: WeaponClass) -> void:
	super.handle_click(weapon)
	#var stab_length := get_default_arm_length(weapon) * 1.4  # 140% of adjusted default length
	#set_arm_length(weapon, stab_length, 0.016, 20.0)

func handle_hold(weapon: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_hold(weapon)
	#is_in_ready_position = true
	#_move_to_ready_position(weapon)

func handle_release(weapon: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_release(weapon)
	#if is_in_ready_position:
		#is_in_ready_position = false
		
		# Reset only the arrow
		#reset_arm_rotation(weapon, 0.016, 10.0)
		#reset_arm_length(weapon, 0.016, 10.0)

func update(weapon: WeaponClass, delta: float) -> void:
	if is_in_ready_position:
		weapon.mod_angle = 90 - weapon.Properties.weapon_angle
		is_in_ready_position = false
	
	else:
		weapon.mod_angle = 0
		#reset_arm_rotation(weapon, delta, 8.0)
		#reset_arm_length(weapon, delta, 8.0)


func _move_to_ready_position(arrow: WeaponClass) -> void:
	var forward_rotation := deg_to_rad(180)
	var arrow_distance := 50.0
	#set_arm_rotation(arrow, forward_rotation, 0.016, 15.0)
	#set_arm_length(arrow, arrow_distance, 0.016, 15.0)
