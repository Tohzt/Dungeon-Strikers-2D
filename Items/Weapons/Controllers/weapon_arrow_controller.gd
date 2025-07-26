class_name ArrowController extends WeaponControllerBase
var default_angle: float
var is_in_ready_position: bool = false
var ready_position_duration: float = 0.0
const READY_POSITION_DURATION_MAX: float = 0.5

func handle_input(weapon: WeaponClass, input_type: String, duration: float) -> void:
	match input_type:
		"click":
			handle_click(weapon)
		"hold":
			handle_hold(weapon, duration)
		"release":
			handle_release(weapon, duration)

func handle_click(weapon: WeaponClass) -> void:
	# Arrow stab forward
	# TODO: Implement arrow stab attack
	# For now, just extend arm forward for stab
	var stab_length := get_default_arm_length(weapon) * 1.4  # 140% of adjusted default length
	set_arm_length(weapon, stab_length, 0.016, 20.0)

func handle_hold(weapon: WeaponClass, _duration: float) -> void:
	var player := get_player(weapon)
	if !player or weapon.is_fired: return
	
	# Check if we have a bow in the other hand
	var other_hand := get_other_hand(weapon)
	##TODO: Weapon Pros should contian list of synnergistic weapons
	##      Use instead of hardcoded matches
	if other_hand.held_weapon and other_hand.held_weapon.Properties.weapon_name == "Bow of Ners":
		is_in_ready_position = true
		ready_position_duration = READY_POSITION_DURATION_MAX
		
		# Notify the bow controller that we're entering ready position
		if other_hand.held_weapon.Properties.weapon_controller:
			var bow_controller := other_hand.held_weapon.Properties.weapon_controller as BowController
			if bow_controller:
				bow_controller.is_in_ready_position = true
		
		# Move only the arrow to ready position
		_move_to_ready_position(weapon)

func handle_release(weapon: WeaponClass, _duration: float) -> void:
	# Just reset ready position - the bow will handle firing when it exits ready position
	if is_in_ready_position:
		is_in_ready_position = false
		ready_position_duration = 0.0
		
		# Notify the bow controller that we're exiting ready position
		var player := get_player(weapon)
		if player:
			var other_hand := get_other_hand(weapon)
			if other_hand.held_weapon:
				if other_hand.held_weapon.Properties.weapon_controller:
					var bow_controller := other_hand.held_weapon.Properties.weapon_controller as BowController
					if bow_controller:
						bow_controller.is_in_ready_position = false
		
		# Reset only the arrow
		reset_arm_rotation(weapon, 0.016, 10.0)
		reset_arm_length(weapon, 0.016, 10.0)

func update(weapon: WeaponClass, delta: float) -> void:
	if weapon.is_fired: return
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


func _move_to_ready_position(arrow: WeaponClass) -> void:
	##TODO: Replace hardcode with props
	var forward_rotation := deg_to_rad(180)
	var arrow_distance := 50.0
	set_arm_rotation(arrow, forward_rotation, 0.016, 15.0)
	set_arm_length(arrow, arrow_distance, 0.016, 15.0)
