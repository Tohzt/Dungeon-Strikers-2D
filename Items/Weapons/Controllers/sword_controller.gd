class_name SwordController extends WeaponControllerBase

var is_slashing: bool = false
var slash_duration: float = 0.0
const SLASH_DURATION_MAX: float = 0.4

# Sword controller - simple click-to-attack weapon
func handle_click(_weapon: WeaponClass, input_side: String) -> void:
	# Basic sword slash
	print("Sword slash from ", input_side, " hand!")
	is_slashing = true
	slash_duration = SLASH_DURATION_MAX
	# Extend arm slightly for slash
	var slash_length := get_default_arm_length(_weapon) * 1.2  # 120% of adjusted default length
	set_arm_length(_weapon, slash_length, 0.016, 20.0)

func update(weapon: WeaponClass, delta: float) -> void:
	# Debug: Check if we can access the hand
	var hand := get_hand(weapon)
	if !hand:
		print("ERROR: Could not get hand reference for weapon!")
		return
	
	# Handle sword slash animation
	if is_slashing:
		slash_duration -= delta
		# Swing the arm for slash animation
		var swing_direction := 1.0 if hand.handedness == "left" else -1.0
		swing_arm(weapon, swing_direction * 3.0, delta, 6.0)  # Medium swing speed
		print("Sword slashing - arm swinging (", hand.handedness, " hand)")
		
		if slash_duration <= 0:
			is_slashing = false
			# Reset arm after slash
			reset_arm_rotation(weapon, delta, 10.0)
			reset_arm_length(weapon, delta, 10.0)
			print("Sword slash finished - resetting arm")
	
	# Default behavior - reset to idle position
	else:
		reset_arm_rotation(weapon, delta, 8.0)
		reset_arm_length(weapon, delta, 8.0) 
