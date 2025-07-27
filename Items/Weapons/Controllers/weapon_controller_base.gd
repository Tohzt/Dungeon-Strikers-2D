class_name WeaponControllerBase extends Resource

# Base class for all weapon controllers
# This defines the interface that all weapon controllers must implement

# Called when weapon is equipped
func on_equip(weapon: WeaponClass) -> void:
	
	# Set the initial arm length based on weapon_arm_length
	if weapon.Properties.weapon_arm_length != 0:
		var arm := get_arm(weapon)
		if arm:
			# Modify the arm's target_position to change the maximum reach
			var current_direction: Vector2 = arm.target_position.normalized()
			var new_length: float = arm.target_position.length() + weapon.Properties.weapon_arm_length
			arm.target_position = current_direction * new_length

# Called when weapon is unequipped
func on_unequip(weapon: WeaponClass) -> void:	
	# Reset arm length to hand's default when weapon is unequipped
	var hand := get_hand(weapon)
	if hand:
		var arm := get_arm(weapon)
		if arm:
			# Reset the arm's target_position to the hand's default length
			var current_direction: Vector2 = arm.target_position.normalized()
			arm.target_position = current_direction * hand.def_arm_length

# Handle quick click input
func handle_click(_weapon: WeaponClass) -> void:
	pass

# Handle hold input with duration
func handle_hold(_weapon: WeaponClass, _duration: float) -> void:
	pass

# Handle input release
func handle_release(_weapon: WeaponClass, _duration: float) -> void:
	pass

# Handle generic input (for BOTH mode weapons)
func handle_input(_weapon: WeaponClass, _input_type: String, _duration: float) -> void:
	pass

# Called every frame when weapon is held
func update(_weapon: WeaponClass, _delta: float) -> void:
	pass

# Helper methods for accessing weapon properties and handedness
func get_weapon_properties(weapon: WeaponClass) -> WeaponResource:
	# Get the weapon's properties resource
	return weapon.Properties

func get_weapon_handedness(weapon: WeaponClass) -> WeaponResource.Handedness:
	# Get which hand this weapon is designed for
	var properties := get_weapon_properties(weapon)
	if properties:
		return properties.weapon_hand
	return WeaponResource.Handedness.RIGHT  # Default fallback

func is_left_handed(weapon: WeaponClass) -> bool:
	# Check if this weapon is designed for the left hand
	return get_weapon_handedness(weapon) == WeaponResource.Handedness.LEFT

func is_right_handed(weapon: WeaponClass) -> bool:
	# Check if this weapon is designed for the right hand
	return get_weapon_handedness(weapon) == WeaponResource.Handedness.RIGHT

func is_both_handed(weapon: WeaponClass) -> bool:
	# Check if this weapon can be used in either hand
	return get_weapon_handedness(weapon) == WeaponResource.Handedness.BOTH

func get_actual_hand(weapon: WeaponClass) -> PlayerHandClass:
	# Get the actual hand that is currently holding this weapon
	return get_hand(weapon)

func get_other_hand(weapon: WeaponClass) -> PlayerHandClass:
	# Get the hand that is NOT holding this weapon
	var player := get_player(weapon)
	if !player:
		return null
	
	var current_hand := get_actual_hand(weapon)
	if current_hand == player.Hands.Left:
		return player.Hands.Right
	else:
		return player.Hands.Left

func get_player(weapon: WeaponClass) -> PlayerClass:
	# Get the player holding this weapon
	if weapon.wielder:
		return weapon.wielder as PlayerClass
	return null

##TODO: Consider writing a Global function 'get_entitiy_holding(item_uid)
##      item_uid will need to be added. 
## Potentially scratch that. Weapon.gd has a 'weapon_holder' variable
## Get the entity from there and then get the arm/hand

# Helper methods for accessing hand and arm components
func get_hand(weapon: WeaponClass) -> PlayerHandClass:
	# Use weapon_holder to get the player, then find which hand holds this weapon
	if weapon.wielder:
		var player: PlayerClass = weapon.wielder as PlayerClass
		if player:
			# Check which hand holds this weapon
			if player.Hands.Left.held_weapon == weapon:
				return player.Hands.Left
			elif player.Hands.Right.held_weapon == weapon:
				return player.Hands.Right
	return null

func get_arm(weapon: WeaponClass) -> RayCast2D:
	# Get the hand first, then get its arm
	var hand := get_hand(weapon)
	if hand:
		return hand.arm
	return null

func get_hand_sprite(weapon: WeaponClass) -> Sprite2D:
	# Weapon -> Hand (Sprite2D)
	return weapon.get_parent() as Sprite2D

# Arm control methods
func swing_arm(weapon: WeaponClass, direction: float, delta: float, speed: float = 3.0) -> void:
	var arm := get_arm(weapon)
	if arm:
		arm.rotation += direction * speed * delta

func set_arm_rotation(weapon: WeaponClass, target_rotation: float, delta: float, speed: float = 10.0) -> void:
	var arm := get_arm(weapon)
	if arm:
		arm.rotation = lerp_angle(arm.rotation, target_rotation, delta * speed)

func reset_arm_rotation(weapon: WeaponClass, delta: float, speed: float = 10.0) -> void:
	var hand := get_hand(weapon)
	if hand:
		set_arm_rotation(weapon, hand.def_arm_rot, delta, speed)

# Arm length control methods
func get_default_arm_length(weapon: WeaponClass) -> float:
	var hand := get_hand(weapon)
	if hand:
		var base_length: float = hand.def_arm_length
		# Apply weapon_arm_length offset if it's not 0
		if weapon.Properties.weapon_arm_length != 0:
			base_length += weapon.Properties.weapon_arm_length
		return base_length
	return 100.0  # Fallback default

func set_arm_length(weapon: WeaponClass, target_length: float, delta: float, speed: float = 10.0) -> void:
	var arm := get_arm(weapon)
	if arm:
		var current_pos: Vector2 = arm.target_position
		var current_length: float = current_pos.length()
		var new_length: float = lerp(current_length, target_length, delta * speed)
		arm.target_position = current_pos.normalized() * new_length

func reset_arm_length(weapon: WeaponClass, delta: float, speed: float = 10.0) -> void:
	var default_length := get_default_arm_length(weapon)
	set_arm_length(weapon, default_length, delta, speed)
