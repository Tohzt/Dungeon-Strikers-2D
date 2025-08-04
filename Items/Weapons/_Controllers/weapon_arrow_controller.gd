class_name ArrowController extends WeaponControllerBase

var default_angle: float


func handle_click(arrow: WeaponClass) -> void:
	super.handle_click(arrow)
	#var stab_length := get_default_arm_length(arrow) * 1.4  # 140% of adjusted default length
	#set_arm_length(arrow, stab_length, 0.016, 20.0)

func handle_hold(arrow: WeaponClass) -> void:
	super.handle_hold(arrow)
	hold_position = true

func handle_release(arrow: WeaponClass) -> void:
	super.handle_release(arrow)
	hold_position = false
	#if is_in_ready_position:
		#is_in_ready_position = false
		
		# Reset only the arrow
		#reset_arm_rotation(arrow, 0.016, 10.0)
		#reset_arm_length(arrow, 0.016, 10.0)


func update(arrow: WeaponClass, delta: float) -> void:
	if hold_position:
		arrow.throw_clone = true
		_move_to_ready_position(arrow)
	
	else:
		arrow.throw_clone = false
		arrow.mod_angle = 0
		reset_arm_rotation(arrow, delta, 8.0)
		reset_arm_position(arrow, delta, 8.0)


func _move_to_ready_position(arrow: WeaponClass) -> void:
	var forward_rotation := deg_to_rad(180)
	var arrow_distance := 50.0
	arrow.mod_angle = 90 - arrow.Properties.weapon_angle
	set_arm_rotation(arrow, forward_rotation, 0.016, 15.0)
	set_arm_position(arrow, arrow_distance, 0.016, 15.0)
