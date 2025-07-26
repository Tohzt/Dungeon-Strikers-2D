class_name WeaponClass extends RigidBody2D

@export var Properties: WeaponResource
@onready var Sprite := $Sprite2D
@onready var Collision := $CollisionShape2D
@onready var Controller := $Controller

var wielder: Node2D
var is_attacking: bool = false
var things_nearby: Array[Node2D] = []
var is_thrown: bool = false
var throw_force: float = 800.0
var throw_torque: float = 10.0
var mod_angle: float = 0.0


func _ready() -> void: _set_props()
func _process(delta: float) -> void: _handle_held_or_pickup(delta)
func _physics_process(_delta: float) -> void: _handle_thrown()


func _set_props() -> void:
	if !Properties: 
		queue_free()
		return
	
	Sprite.texture = Properties.weapon_sprite[0]
	if Properties.weapon_name.is_empty():
		var regex := RegEx.new()
		regex.compile("([^/]+)\\.png")
		var result := regex.search(Sprite.texture.load_path)
		if result:
			Properties.weapon_name = result.get_string(1)
	self.name = Properties.weapon_name
	
	if Properties.weapon_collision:
		if Collision: Collision.queue_free()
		var new_collision: CollisionShape2D = Properties.weapon_collision.instantiate()
		add_child(new_collision)
		new_collision.name = "CollisionShape2D"
		Collision = new_collision
		Collision.position = Sprite.position
	
	if wielder:
		modulate = wielder.Sprite.modulate
		set_z_index(Global.Layers.WEAPON_IN_HAND)
		Sprite.position = Properties.weapon_offset
		Collision.position = Properties.weapon_offset
		_update_collisions("in-hand")
	
		##TODO:
		## Notify weapon controller that weapon was equipped
		#if Properties.weapon_controller:
			#Properties.weapon_controller.on_equip(self)
	else:
		set_z_index(Global.Layers.WEAPON_ON_GROUND)
		_update_collisions("on-ground")


func _handle_held_or_pickup(delta: float) -> void:
	if wielder and !is_thrown:
		var dir := deg_to_rad(Properties.weapon_angle + mod_angle)
		rotation = lerp_angle(rotation, get_parent().rotation + dir, delta*10)
		
		if Properties.weapon_controller:
			Properties.weapon_controller.update(self, delta)
	else:
		if things_nearby and Input.is_action_just_pressed("interact"):
			attempt_pickup()



func _handle_thrown() -> void:
	if is_thrown:
		var collisions := get_colliding_bodies()
		for collider: Node2D in collisions:
			if collider:
				if wielder:
					if collider == wielder:
						continue
					if collider.is_in_group("Weapon") and collider.wielder == wielder:
						continue
				print("Resetting ", Properties.weapon_name, " to ground state")
				reset_to_ground_state()


func _on_pickup_body_entered(body: Node2D) -> void:
	if !body.is_in_group("Player"): return
	if !things_nearby.has(body):
		things_nearby.append(body)

func _on_pickup_body_exited(body: Node2D) -> void:
	if things_nearby.has(body):
		things_nearby.remove_at(things_nearby.find(body))

func attempt_pickup() -> void:
	if wielder or things_nearby.size() == 0: return
	
	## TODO: Not sure, but this could break when another entity is near an item
	var player: Node2D = things_nearby[0]
	var target_hand: PlayerHandClass
	
	match Properties.weapon_hand:
		Properties.Handedness.LEFT:
			target_hand = player.Hands.Left
		Properties.Handedness.RIGHT:
			target_hand = player.Hands.Right
		Properties.Handedness.BOTH:
			if !player.Hands.Left.held_weapon:
				target_hand = player.Hands.Left
			elif !player.Hands.Right.held_weapon:
				target_hand = player.Hands.Right
			else:
				target_hand = player.Hands.Left
	
	if target_hand.held_weapon:
		drop_weapon(target_hand.held_weapon, player)
	
	pickup_weapon(player, target_hand)

func pickup_weapon(player: Node2D, target_hand: PlayerHandClass) -> void:
	wielder = player
	target_hand.held_weapon = self
	
	##TODO: Rip out to function (used in ready)
	modulate = player.Sprite.modulate
	Sprite.position = Properties.weapon_offset
	Collision.position = Properties.weapon_offset
	global_position = target_hand.hand.global_position
	call_deferred("reparent", target_hand.hand)
	call_deferred("set_z_index", Global.Layers.WEAPON_IN_HAND)
	_update_collisions("in-hand")
	
	things_nearby.erase(player)
	is_thrown = false
	
	##TODO:
	## Notify weapon controller that weapon was equipped
	#if Properties.weapon_controller:
		#Properties.weapon_controller.on_equip(self)

func drop_weapon(weapon: WeaponClass, player: Node2D) -> void:
	##TODO:
	## Notify weapon controller that weapon was unequipped
	#if weapon.Properties.weapon_controller:
		#weapon.Properties.weapon_controller.on_unequip(weapon)
	
	weapon.modulate = Color.WHITE
	weapon.Sprite.position = Vector2.ZERO
	weapon.Collision.position = Vector2.ZERO
	_update_collisions("on-ground")
	
	# Find which hand holds this weapon
	var hand_holding_weapon: PlayerHandClass = null
	if player.Hands.Left.held_weapon == weapon:
		hand_holding_weapon = player.Hands.Left
	elif player.Hands.Right.held_weapon == weapon:
		hand_holding_weapon = player.Hands.Right
	
	# Remove weapon from hand
	weapon.weapon_holder = null
	if hand_holding_weapon:
		hand_holding_weapon.held_weapon = null
	
	# Move weapon back to world
	weapon.call_deferred("reparent", player.get_parent())
	weapon.global_position = player.global_position + Vector2(randi_range(-20, 20), randi_range(-20, 20))

func throw_weapon(throw_direction: Vector2, player: Node2D) -> void:
	if wielder: 
		# Find which hand holds this weapon
		var hand_holding_weapon: PlayerHandClass = null
		if player.Hands.Left.held_weapon == self:
			hand_holding_weapon = player.Hands.Left
		elif player.Hands.Right.held_weapon == self:
			hand_holding_weapon = player.Hands.Right
		
		if !hand_holding_weapon: return
		
		# Capture the hand's world position before reparenting
		var hand_world_position := hand_holding_weapon.hand.global_position
		
		# Ignore collisions with the weapon holder and their weapons BEFORE moving to world
		add_collision_exception_with(weapon_holder)
		if weapon_holder.Hands.Left.held_weapon:
			add_collision_exception_with(weapon_holder.Hands.Left.held_weapon)
		if weapon_holder.Hands.Right.held_weapon:
			add_collision_exception_with(weapon_holder.Hands.Right.held_weapon)
		
		# Remove from hand
		weapon_holder = null
		hand_holding_weapon.held_weapon = null
		
		# Move to world and apply physics
		call_deferred("reparent", player.get_parent())
		global_position = hand_world_position  # Use hand position instead of player position
	
	# Reset sprite and collision shape position (no offset when thrown)
	Sprite.position = Vector2.ZERO
	Collision.position = Vector2.ZERO
	
	# Apply throwing force
	linear_velocity = throw_direction.normalized() * throw_force
	
	# Handle different throw styles
	match Properties.throw_style:
		Properties.ThrowStyle.STRAIGHT:
			# Face the target direction
			global_rotation = throw_direction.angle()
			angular_velocity = 0.0  # No spinning
		Properties.ThrowStyle.SPIN:
			# Set rotation to face direction and add spinning
			global_rotation = throw_direction.angle()
			angular_velocity = throw_torque * 2.0  # Extra spin
		Properties.ThrowStyle.TUMBLE:
			# Set rotation and add tumbling motion
			global_rotation = throw_direction.angle()
			angular_velocity = throw_torque * 0.5  # Slower tumble
	
	# Mark as thrown
	is_thrown = true

func reset_to_ground_state() -> void:
	is_thrown = false
	
	# Stop all movement
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	# Reset sprite and collision shape to center when on ground
	Sprite.position = Vector2.ZERO
	Collision.position = Vector2.ZERO
	
	_update_collisions("on-ground")

func _set_held_sprite_position() -> void:
	# Safely set sprite position when weapon is held
	if Sprite and Properties:
		Sprite.position = Properties.weapon_offset

# Weapon input handling methods
func handle_input(input_type: String, duration: float = 0.0) -> void:
	if !Properties.weapon_controller: return
	if !weapon_holder: return
	
	# Route to controller based on input_mode
	match Properties.input_mode:
		Properties.InputMode.CLICK_ONLY:
			if input_type == "click":
				Properties.weapon_controller.handle_click(self)
		Properties.InputMode.HOLD_ACTION:
			if input_type == "click":
				Properties.weapon_controller.handle_click(self)
			elif input_type == "hold":
				Properties.weapon_controller.handle_hold(self, duration)
			elif input_type == "release":
				Properties.weapon_controller.handle_release(self, duration)
		Properties.InputMode.BOTH:
			Properties.weapon_controller.handle_input(self, input_type, duration)

# Fire weapon method - can be used for special firing mechanics (like bow firing arrow)
func fire_weapon(trigger_weapon: WeaponClass = null) -> void:
	if !weapon_holder: return
	
	var player: Node2D = weapon_holder
	var throw_direction := _calculate_throw_direction(player)
	
	# If no trigger weapon provided, do normal throw
	if !trigger_weapon:
		# Do normal throw using calculated direction
		throw_weapon(throw_direction, player)
		return
	
	# If trigger weapon provided, clone this weapon and fire it
	var weapon_clone: WeaponClass = Global.WEAPON.instantiate() as WeaponClass
	if !weapon_clone:
		print("Failed to create weapon clone!")
		return
	
	weapon_clone.Properties = Properties
	player.get_parent().add_child(weapon_clone)
	
	# Ensure the weapon is properly initialized before setting collision layers
	weapon_clone._sest_props_or_queu()
	
	weapon_clone.modulate = player.Sprite.modulate
	weapon_clone.global_position = trigger_weapon.global_position + throw_direction.normalized() * 20.0
	weapon_clone.weapon_holder = player
	weapon_clone.is_fired = true  # Mark this as a fired weapon
	
	weapon_clone.throw_weapon(throw_direction, player)


# Helper method to calculate throw direction
func _calculate_throw_direction(player: Node2D) -> Vector2:
	if !player.Input_Handler.look_dir.is_zero_approx():
		# Use look direction (mouse or controller aim)
		return player.Input_Handler.look_dir
	elif !player.tar_pos.is_zero_approx():
		# Use target direction if no look input
		return player.tar_pos.normalized()
	else:
		# Fallback to player's facing direction
		return Vector2(cos(player.rotation - PI/2), sin(player.rotation - PI/2))

func _update_collisions(state: String) -> void:
	match state:
		"on-ground":
			set_collision_layer_value(4, true)   # Item
			set_collision_layer_value(5, false)   # Weapon
			
			set_collision_mask_value(2, false)   # Player
			set_collision_mask_value(3, false)   # Enemy
			set_collision_mask_value(4, false)   # Item
			set_collision_mask_value(5, false)   # Weapon
			
		"in-hand":
			set_collision_layer_value(4, false)   # Item
			set_collision_layer_value(5, true)   # Weapon
			
			set_collision_mask_value(2, false)   # Player
			set_collision_mask_value(3, true)   # Enemy
			set_collision_mask_value(4, false)   # Item
			set_collision_mask_value(5, false)   # Weapon
			
		"projectile":
			set_collision_layer_value(4, false)   # Item
			set_collision_layer_value(5, true)   # Weapon
			
			set_collision_mask_value(2, false)   # Player (don't hit the player who fired it)
			set_collision_mask_value(3, true)   # Enemy (can hit enemies)
			set_collision_mask_value(4, false)   # Item (don't hit items on ground)
			set_collision_mask_value(5, false)   # Weapon (don't collide with other weapons when flying)
