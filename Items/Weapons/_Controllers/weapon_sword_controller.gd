class_name SwordController extends WeaponControllerBase

var is_slashing: bool = false
var slash_duration: float = 0.0
const SLASH_DURATION_MAX: float = 0.4


func handle_click(weapon: WeaponClass) -> void:
	super.handle_click(weapon)

func handle_hold(weapon: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_hold(weapon)

func handle_release(weapon: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_release(weapon)


#func handle_click(weapon: WeaponClass) -> void:
	#print("Click from the Sword?")
	#is_slashing = true
	#slash_duration = SLASH_DURATION_MAX
	##var slash_length := get_default_arm_length(weapon) * 1.2
	##set_arm_length(weapon, slash_length, 0.016, 20.0)

func update(_weapon: WeaponClass, _delta: float) -> void:
	pass
	#var hand := get_hand(weapon)
	#if !hand: return
	#
	#if is_slashing:
		#slash_duration -= delta
		#var swing_direction := 1.0 if hand.handedness == "left" else -1.0
		#swing_arm(weapon, swing_direction * 3.0, delta, 6.0)  # Medium swing speed
		#
		#if slash_duration <= 0:
			#is_slashing = false
			#reset_arm_rotation(weapon, delta, 10.0)
			#reset_arm_length(weapon, delta, 10.0)
	#
	#else:
		#reset_arm_rotation(weapon, delta, 8.0)
		#reset_arm_length(weapon, delta, 8.0) 
