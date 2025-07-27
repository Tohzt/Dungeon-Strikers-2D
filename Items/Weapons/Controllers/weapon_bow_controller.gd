class_name BowController extends WeaponControllerBase

var is_drawn: bool = false
var draw_start_time: float = 0.0
var charge_level: float = 0.0
var is_in_ready_position: bool = false

func handle_input(weapon: WeaponClass, input_type: String, duration: float) -> void:
	match input_type:
		"click":
			handle_click(weapon)
		"hold":
			handle_hold(weapon, duration)
		"release":
			handle_release(weapon, duration)

func handle_click(weapon: WeaponClass) -> void:
	# Check if we're in ready position with an arrow
	if is_in_ready_position:
		# Quick shot - fire immediately on click when in ready position
		_check_and_fire_arrow(weapon)
		return
	
	# Normal bow mechanics
	# Left click = swing bow for melee attack
	# TODO: Implement bow melee attack
	# For now, just swing the arm
	var swing_length := get_default_arm_length(weapon) * 1.2  # 120% of adjusted default length
	set_arm_length(weapon, swing_length, 0.016, 20.0)

func handle_hold(weapon: WeaponClass, _duration: float) -> void:
	# Left hold = go to ready position if arrow is held
	var player := get_player(weapon)
	if !player: return
	
	var other_hand := get_other_hand(weapon)
	if other_hand.held_weapon:
		# Check if other hand has an arrow
		if other_hand.held_weapon.Properties.weapon_name == "Arrow":
			is_in_ready_position = true
			# Move bow to ready position
			_move_to_ready_position(weapon)

func handle_release(weapon: WeaponClass, _duration: float) -> void:
	if is_in_ready_position:
		# Charged shot - fire when releasing hold
		_check_and_fire_arrow(weapon)
		
		is_in_ready_position = false
		
		# Reset to normal position
		reset_arm_rotation(weapon, 0.016, 10.0)
		reset_arm_length(weapon, 0.016, 10.0)

func update(weapon: WeaponClass, delta: float) -> void:
	# Handle ready position - keep bow in position
	if is_in_ready_position:
		# Keep the bow in the ready position using the same rotation as shield
		var forward_rotation := deg_to_rad(180)
		set_arm_rotation(weapon, forward_rotation, delta, 8.0)
		# Maintain extended arm length for ready position
		var ready_length := get_default_arm_length(weapon) * 1.5  # 150% for ready position
		set_arm_length(weapon, ready_length, delta, 8.0)
	else:
		# Default behavior - reset to idle position
		reset_arm_rotation(weapon, delta, 8.0)
		reset_arm_length(weapon, delta, 8.0)

# Move bow to ready position
func _move_to_ready_position(bow: WeaponClass) -> void:
	# Use the same approach as shield - point forward with deg_to_rad(180)
	var forward_rotation := deg_to_rad(180)
	
	# Position bow further from player
	var bow_distance := 100.0
	
	# Set bow position (further from player)
	set_arm_rotation(bow, forward_rotation, 0.016, 15.0)
	set_arm_length(bow, bow_distance, 0.016, 15.0)

# Check if the arrow should fire when bow exits ready position
func _check_and_fire_arrow(bow: WeaponClass) -> void:
	var player := get_player(bow)
	if !player: return
	
	# Check if the other hand has an arrow in ready position
	var other_hand := get_other_hand(bow)
	if other_hand.held_weapon and other_hand.held_weapon.Properties.weapon_name == "Arrow":
		if other_hand.held_weapon.Properties.weapon_controller:
			var arrow_controller := other_hand.held_weapon.Properties.weapon_controller as ArrowController
			if arrow_controller and arrow_controller.is_in_ready_position:
				# Fire the arrow!
				other_hand.held_weapon.fire_weapon(bow)
				
				# Exit ready position after firing
				arrow_controller.is_in_ready_position = false
				arrow_controller.ready_position_duration = 0.0
