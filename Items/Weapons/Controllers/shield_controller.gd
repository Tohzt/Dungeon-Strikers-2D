class_name ShieldController extends WeaponControllerBase

var is_blocking: bool = false
var is_bashing: bool = false
var bash_duration: float = 0.0
const BASH_DURATION_MAX: float = 0.3

func handle_input(_weapon: WeaponClass, input_type: String, duration: float) -> void:
	match input_type:
		"click":
			handle_click(_weapon)
		"hold":
			handle_hold(_weapon, duration)
		"release":
			handle_release(_weapon, duration)

func handle_click(_weapon: WeaponClass) -> void:
	# Quick shield bash
	is_bashing = true
	bash_duration = BASH_DURATION_MAX

func handle_hold(weapon: WeaponClass, _duration: float) -> void:
	# Start blocking
	if !is_blocking:
		is_blocking = true
		# Move shield to blocking position (in front of player)
		var block_rotation := rad_to_deg(-90)  # Point forward
		set_arm_rotation(weapon, block_rotation, 0.016, 15.0)  # Fast movement to block position
		# Shorten arm for blocking pose
		var block_length := get_default_arm_length(weapon) * 0.6  # 60% of adjusted default length
		set_arm_length(weapon, block_length, 0.016, 15.0)

func handle_release(weapon: WeaponClass, _duration: float) -> void:
	# Stop blocking
	if is_blocking:
		is_blocking = false
		# Reset arm to default position
		reset_arm_rotation(weapon, 0.016, 10.0)
		# Reset arm length to default
		reset_arm_length(weapon, 0.016, 10.0)

func update(weapon: WeaponClass, delta: float) -> void:
	# Debug: Check if we can access the hand
	var hand := get_hand(weapon)
	if !hand: return
	
	# Handle shield bash animation
	if is_bashing:
		bash_duration -= delta
		# Swing the arm for bash animation
		var swing_direction := -1.0
		swing_arm(weapon, swing_direction * 5.0, delta, 8.0)  # Fast swing
		
		if bash_duration <= 0:
			is_bashing = false
			# Reset arm after bash
			reset_arm_rotation(weapon, delta, 12.0)
	
	# Handle blocking - keep shield in front
	elif is_blocking:
		var block_rotation := deg_to_rad(180)  # Point forward
		set_arm_rotation(weapon, block_rotation, delta, 8.0)
		# Maintain shortened arm length while blocking
		var block_length := get_default_arm_length(weapon) * 0.6
		set_arm_length(weapon, block_length, delta, 8.0)
	
	# Default behavior - reset to idle position
	else:
		reset_arm_rotation(weapon, delta, 8.0)
		reset_arm_length(weapon, delta, 8.0) 
