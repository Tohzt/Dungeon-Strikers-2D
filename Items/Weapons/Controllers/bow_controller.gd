class_name BowController extends WeaponControllerBase

var is_drawn: bool = false
var draw_start_time: float = 0.0
var charge_level: float = 0.0
var is_in_ready_position: bool = false

func handle_input(_weapon: WeaponClass, input_type: String, input_side: String, duration: float) -> void:
	match input_type:
		"click":
			handle_click(_weapon, input_side)
		"hold":
			handle_hold(_weapon, input_side, duration)
		"release":
			handle_release(_weapon, input_side, duration)

func handle_click(_weapon: WeaponClass, input_side: String) -> void:
	# Check if we're in ready position with an arrow
	if is_in_ready_position:
		# Fire the arrow!
		print("FIRE ARROW! Left click while in ready position!")
		_fire_arrow(_weapon)
		return
	
	# Normal bow mechanics
	if input_side == "left":
		# Left click = swing bow for melee attack
		# TODO: Implement bow melee attack
		# For now, just swing the arm
		var swing_length := get_default_arm_length(_weapon) * 1.2  # 120% of adjusted default length
		set_arm_length(_weapon, swing_length, 0.016, 20.0)

func handle_hold(_weapon: WeaponClass, input_side: String, duration: float) -> void:
	if input_side == "left":
		# Left hold = nothing unless you are holding an arrow in the right hand
		var player := get_player(_weapon)
		if player and player.Hands.Right.held_weapon:
			# Check if right hand has an arrow
			if player.Hands.Right.held_weapon.Properties.weapon_name == "Arrow":
				is_in_ready_position = true
				# Move bow to ready position
				_move_to_ready_position(_weapon)

func handle_release(_weapon: WeaponClass, input_side: String, _duration: float) -> void:
	if input_side == "left":
		if is_in_ready_position:
			is_in_ready_position = false
			# Reset to normal position
			reset_arm_rotation(_weapon, 0.016, 10.0)
			reset_arm_length(_weapon, 0.016, 10.0)

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

# Helper method to get the player
func get_player(weapon: WeaponClass) -> PlayerClass:
	if weapon.weapon_holder:
		return weapon.weapon_holder as PlayerClass
	return null

# Move bow to ready position
func _move_to_ready_position(bow: WeaponClass) -> void:
	# Use the same approach as shield - point forward with deg_to_rad(180)
	var forward_rotation := deg_to_rad(180)
	
	# Position bow further from player
	var bow_distance := 100.0
	
	# Set bow position (further from player)
	set_arm_rotation(bow, forward_rotation, 0.016, 15.0)
	set_arm_length(bow, bow_distance, 0.016, 15.0)

# Fire an arrow from the bow
func _fire_arrow(bow: WeaponClass) -> void:
	var player := get_player(bow)
	if !player:
		return
	
	# Get the arrow from the right hand
	var arrow: WeaponClass = player.Hands.Right.held_weapon
	if !arrow or arrow.Properties.weapon_name != "Arrow":
		print("No arrow in right hand to fire!")
		return
	
	# Calculate throw direction (same as weapon throwing)
	var throw_direction: Vector2
	if !player.Input_Handler.look_dir.is_zero_approx():
		# Use look direction (mouse or controller aim)
		throw_direction = player.Input_Handler.look_dir
	elif !player.tar_pos.is_zero_approx():
		# Use target direction if no look input
		throw_direction = player.tar_pos.normalized()
	else:
		# Fallback to player's facing direction
		throw_direction = Vector2(cos(player.rotation - PI/2), sin(player.rotation - PI/2))
	
	# Clone the existing arrow using Godot's built-in duplicate method
	var arrow_clone: WeaponClass = arrow.duplicate() as WeaponClass
	if !arrow_clone:
		print("Failed to clone arrow!")
		return
	
	# Add to the scene first so the @onready variables are properly initialized
	player.get_parent().add_child(arrow_clone)
	
	# Initialize the cloned arrow as a thrown weapon
	arrow_clone.weapon_holder = null  # Not held by anyone
	arrow_clone.is_thrown = true      # Mark as thrown
	
	# Reset sprite and collision positions (no offset when thrown)
	arrow_clone.Sprite.position = Vector2.ZERO
	arrow_clone.Collision.position = Vector2.ZERO
	
	# Copy collision layers and masks from the original arrow
	arrow_clone.collision_layer = arrow.collision_layer
	arrow_clone.collision_mask = arrow.collision_mask
	
	# Update collision layers for thrown state
	arrow_clone._update_collisions("on-ground")
	
	# Position the clone at the bow's position
	arrow_clone.global_position = bow.global_position
	
	# Apply throwing physics
	arrow_clone.linear_velocity = throw_direction.normalized() * arrow_clone.throw_force
	
	# Handle different throw styles
	match arrow_clone.Properties.throw_style:
		arrow_clone.Properties.ThrowStyle.STRAIGHT:
			# Face the target direction
			arrow_clone.global_rotation = throw_direction.angle()
			arrow_clone.angular_velocity = 0.0  # No spinning
		arrow_clone.Properties.ThrowStyle.SPIN:
			# Set rotation to face direction and add spinning
			arrow_clone.global_rotation = throw_direction.angle()
			arrow_clone.angular_velocity = arrow_clone.throw_torque * 2.0  # Extra spin
		arrow_clone.Properties.ThrowStyle.TUMBLE:
			# Set rotation and add tumbling motion
			arrow_clone.global_rotation = throw_direction.angle()
			arrow_clone.angular_velocity = arrow_clone.throw_torque * 0.5  # Slower tumble
	
	# Exit ready position after firing
	is_in_ready_position = false
