class_name ArrowController extends WeaponControllerBase
var default_angle: float
var is_in_ready_position: bool = false
var ready_position_duration: float = 0.0
const READY_POSITION_DURATION_MAX: float = 0.5

func handle_input(_weapon: WeaponClass, input_type: String, input_side: String, duration: float) -> void:
	match input_type:
		"click":
			handle_click(_weapon, input_side)
		"hold":
			handle_hold(_weapon, input_side, duration)
		"release":
			handle_release(_weapon, input_side, duration)

func handle_click(_weapon: WeaponClass, input_side: String) -> void:
	# Arrow stab forward
	# TODO: Implement arrow stab attack
	# For now, just extend arm forward for stab
	var stab_length := get_default_arm_length(_weapon) * 1.4  # 140% of adjusted default length
	set_arm_length(_weapon, stab_length, 0.016, 20.0)

func handle_hold(_weapon: WeaponClass, input_side: String, duration: float) -> void:
	# Check if we have a bow in the other hand
	var player := get_player(_weapon)
	if !player:
		return
	
	var other_hand: PlayerHandClass
	if input_side == "right":
		other_hand = player.Hands.Left
	else:
		other_hand = player.Hands.Right
	
	# Check if the other hand has a bow
	if other_hand.held_weapon and other_hand.held_weapon.Properties.weapon_name == "Bow of Ners":
		is_in_ready_position = true
		ready_position_duration = READY_POSITION_DURATION_MAX
		
		# Notify the bow controller that we're entering ready position
		if other_hand.held_weapon.Properties.weapon_controller:
			var bow_controller := other_hand.held_weapon.Properties.weapon_controller as BowController
			if bow_controller:
				bow_controller.is_in_ready_position = true
		
		# Move only the arrow to ready position
		_move_to_ready_position(_weapon, input_side)

func handle_release(_weapon: WeaponClass, input_side: String, _duration: float) -> void:
	if is_in_ready_position:
		is_in_ready_position = false
		ready_position_duration = 0.0
		
		# Reset only the arrow to normal position
		var player := get_player(_weapon)
		if player:
			var other_hand: PlayerHandClass
			if input_side == "right":
				other_hand = player.Hands.Left
			else:
				other_hand = player.Hands.Right
			
			if other_hand.held_weapon:
				# Notify the bow controller that we're exiting ready position
				if other_hand.held_weapon.Properties.weapon_controller:
					var bow_controller := other_hand.held_weapon.Properties.weapon_controller as BowController
					if bow_controller:
						bow_controller.is_in_ready_position = false
				
				# Reset only the arrow
				reset_arm_rotation(_weapon, 0.016, 10.0)
				reset_arm_length(_weapon, 0.016, 10.0)

func update(weapon: WeaponClass, delta: float) -> void:
	# Handle ready position animation
	if is_in_ready_position:
		weapon.mod_angle = 90 - weapon.Properties.weapon_angle
		ready_position_duration -= delta
		if ready_position_duration <= 0:
			is_in_ready_position = false
	
	# Default behavior - reset to idle position
	else:
		weapon.mod_angle = 0
		reset_arm_rotation(weapon, delta, 8.0)
		reset_arm_length(weapon, delta, 8.0)

# Helper method to get the player
func get_player(weapon: WeaponClass) -> PlayerClass:
	if weapon.weapon_holder:
		return weapon.weapon_holder as PlayerClass
	return null

# Move only the arrow to ready position
func _move_to_ready_position(arrow: WeaponClass, arrow_side: String) -> void:
	# Use the same approach as shield - point forward with deg_to_rad(180)
	var forward_rotation := deg_to_rad(180)
	
	# Position arrow closer to player
	var arrow_distance := 50.0
	
	# Set arrow position (closer to player)
	set_arm_rotation(arrow, forward_rotation, 0.016, 15.0)
	set_arm_length(arrow, arrow_distance, 0.016, 15.0)
