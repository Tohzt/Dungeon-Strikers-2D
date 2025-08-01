class_name ShieldController extends WeaponControllerBase

var is_blocking: bool = false
var is_bashing: bool = false
var bash_duration: float = 0.0
const BASH_DURATION_MAX: float = 0.3


func handle_click(weapon: WeaponClass) -> void:
	super.handle_click(weapon)

func handle_hold(weapon: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_hold(weapon)

func handle_release(weapon: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_release(weapon)


#func handle_click(_weapon: WeaponClass) -> void:
	#print("Click from the Shield?")
	## Quick shield bash
	#is_bashing = true
	#bash_duration = BASH_DURATION_MAX
#
#func handle_hold(weapon: WeaponClass, _duration: float) -> void:
	#if is_blocking: return
	#is_blocking = true
	#var block_rotation := rad_to_deg(-90)
	##set_arm_rotation(weapon, block_rotation, 0.016, 15.0)
	##var block_length := get_default_arm_length(weapon) * 0.6
	##set_arm_length(weapon, block_length, 0.016, 15.0)
#
#func handle_release(weapon: WeaponClass, _duration: float) -> void:
	#if is_blocking:
		#is_blocking = false
		##reset_arm_rotation(weapon, 0.016, 10.0)
		##reset_arm_length(weapon, 0.016, 10.0)

func update(_weapon: WeaponClass, _delta: float) -> void:
	pass
	#var hand := get_hand(weapon)
	#if !hand: return
	#
	#if is_bashing:
		#bash_duration -= delta
		#var swing_direction := -1.0
		#swing_arm(weapon, swing_direction * 5.0, delta, 8.0)
		#
		#if bash_duration <= 0:
			#is_bashing = false
			#reset_arm_rotation(weapon, delta, 12.0)
	#
	#elif is_blocking:
		#var block_rotation := deg_to_rad(180)
		#set_arm_rotation(weapon, block_rotation, delta, 8.0)
		#var block_length := get_default_arm_length(weapon) * 0.6
		#set_arm_length(weapon, block_length, delta, 8.0)
	#
	#else:
		#reset_arm_rotation(weapon, delta, 8.0)
		#reset_arm_length(weapon, delta, 8.0) 
