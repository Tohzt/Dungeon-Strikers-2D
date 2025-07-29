class_name BowController extends WeaponControllerBase

var charge_level: float = 0.0
var draw_start_time: float = 0.0
var is_drawn: bool = false
var is_in_ready_position: bool = false

func handle_click(weapon: WeaponClass) -> void:
	super.handle_click(weapon)

func handle_hold(weapon: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_hold(weapon)

func handle_release(weapon: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_release(weapon)

#func handle_click(weapon: WeaponClass) -> void:
	#if is_in_ready_position:
		#_check_and_fire_arrow(weapon)
		#return
	#
	##var swing_length := get_default_arm_length(weapon) * 1.2  # 120% of adjusted default length
	##set_arm_length(weapon, swing_length, 0.016, 20.0)
#
#func handle_hold(weapon: WeaponClass, _duration: float) -> void:
	#is_in_ready_position = true
	#_move_to_ready_position(weapon)
#
#func handle_release(weapon: WeaponClass, _duration: float) -> void:
	#if is_in_ready_position:
		#is_in_ready_position = false
		#_check_and_fire_arrow(weapon)
		#
		## Reset to normal position
		#reset_arm_rotation(weapon, 0.016, 10.0)
		#reset_arm_length(weapon, 0.016, 10.0)


func update(weapon: WeaponClass, delta: float) -> void:
	if is_in_ready_position:
		var forward_rotation := deg_to_rad(180)
		#set_arm_rotation(weapon, forward_rotation, delta)
		#set_arm_position(weapon, delta)
	#else:
		#reset_arm_rotation(weapon, delta)
		#reset_arm_length(weapon, delta)


func _move_to_ready_position(bow: WeaponClass) -> void:
	var forward_rotation := deg_to_rad(180)
	var bow_distance := 100.0
	#set_arm_rotation(bow, forward_rotation, 0.016, 15.0)
	#set_arm_length(bow, bow_distance, 0.016, 15.0)


func _check_and_fire_arrow(weapon: WeaponClass) -> void:
	if !weapon.wielder: return
	
	if is_in_ready_position:
		##TODO: Update synnergy weapon
		_attack()


func _attack() -> void:
	pass
