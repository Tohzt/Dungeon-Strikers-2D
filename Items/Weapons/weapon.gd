class_name WeaponClass extends RigidBody2D

@export var Properties: WeaponResource
@onready var Sprite := $Sprite2D
@onready var Collision := $CollisionShape2D
@onready var Controller := $Controller

var weapon_holder: Node2D
var is_attacking: bool = false
var nearby: Array[Node2D] = []
var is_thrown: bool = false
var throw_force: float = 800.0
var throw_torque: float = 10.0
var mod_angle: float = 0.0

func _ready() -> void:
	if Properties:
		Sprite.texture = Properties.weapon_sprite[0]
		if Properties.weapon_name.is_empty():
			var regex := RegEx.new()
			regex.compile("([^/]+)\\.png")
			var result := regex.search(Sprite.texture.load_path)
			if result:
				Properties.weapon_name = result.get_string(1)
		
		# Replace collision shape if resource provides one
		if Properties.weapon_collision:
			if Collision: Collision.queue_free()
			var new_collision: CollisionShape2D = Properties.weapon_collision.instantiate()
			add_child(new_collision)
			new_collision.name = "CollisionShape2D"
			Collision = new_collision
			Collision.position = Sprite.position
		
		_update_collisions("on-ground")
	else: 
		queue_free()

func _process(_delta: float) -> void:
	if weapon_holder:
		var dir := deg_to_rad(Properties.weapon_angle + mod_angle)
		rotation = lerp_angle(rotation, get_parent().rotation + dir, _delta*10)
		
		# Update weapon controller if it exists
		if Properties.weapon_controller:
			Properties.weapon_controller.update(self, _delta)
	else:
		# Check for interaction when not held
		if nearby and Input.is_action_just_pressed("interact"):
			attempt_pickup()

func _physics_process(_delta: float) -> void:
	if is_thrown:
		var collisions := get_colliding_bodies()
		for collider: Node2D in collisions:
			if collider:
				reset_to_ground_state()

func _on_pickup_body_entered(body: Node2D) -> void:
	if !body.is_in_group("Player"): return
	if !nearby.has(body):
		nearby.append(body)

func _on_pickup_body_exited(body: Node2D) -> void:
	if nearby.has(body):
		nearby.remove_at(nearby.find(body))

func attempt_pickup() -> void:
	if weapon_holder: return
	if nearby.size() == 0: return
	
	var player: Node2D = nearby[0]  # Get the first nearby player
	
	var target_hand: PlayerHandClass
	
	# Determine which hand this weapon goes to
	if Properties.weapon_hand == Properties.Handedness.LEFT:
		target_hand = player.Hands.Left
	elif Properties.weapon_hand == Properties.Handedness.RIGHT:
		target_hand = player.Hands.Right
	else:
		# For BOTH handed weapons, prefer the empty hand
		if !player.Hands.Left.held_weapon and !player.Hands.Right.held_weapon:
			target_hand = player.Hands.Left
		elif !player.Hands.Left.held_weapon:
			target_hand = player.Hands.Left
		elif !player.Hands.Right.held_weapon:
			target_hand = player.Hands.Right
		else:
			# Both hands full, use left hand and drop current weapon
			target_hand = player.Hands.Left
	
	# If the target hand already has a weapon, drop it first
	if target_hand.held_weapon:
		drop_weapon(target_hand.held_weapon, player)
	
	# Pick up this weapon
	pickup_weapon(player, target_hand)

func pickup_weapon(player: Node2D, target_hand: PlayerHandClass) -> void:
	weapon_holder = player
	target_hand.held_weapon = self
	
	# Set up the weapon on the hand with offset
	Sprite.position = Properties.weapon_offset
	Collision.position = Properties.weapon_offset
	global_position = target_hand.hand.global_position
	call_deferred("reparent", target_hand.hand)
	call_deferred("set_z_index", Global.Layers.WEAPON_IN_HAND)
	
	# Apply player color
	modulate = player.Sprite.modulate
	
	# Remove from nearby players list
	nearby.erase(player)
	
	# Reset thrown state
	is_thrown = false
	
	_update_collisions("in-hand")
	
	# Notify weapon controller that weapon was equipped
	if Properties.weapon_controller:
		Properties.weapon_controller.on_equip(self)

func drop_weapon(weapon: WeaponClass, player: Node2D) -> void:
	# Notify weapon controller that weapon was unequipped
	if weapon.Properties.weapon_controller:
		weapon.Properties.weapon_controller.on_unequip(weapon)
	
	weapon.modulate = Color.WHITE
	
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
	
	# Reset sprite and collision shape position (no offset when on ground)
	weapon.Sprite.position = Vector2.ZERO
	weapon.Collision.position = Vector2.ZERO
	
	_update_collisions("on-ground")

func throw_weapon(throw_direction: Vector2, player: Node2D) -> void:
	if !weapon_holder: return
	
	# Find which hand holds this weapon
	var hand_holding_weapon: PlayerHandClass = null
	if player.Hands.Left.held_weapon == self:
		hand_holding_weapon = player.Hands.Left
	elif player.Hands.Right.held_weapon == self:
		hand_holding_weapon = player.Hands.Right
	
	if !hand_holding_weapon: return
	
	# Capture the hand's world position before reparenting
	var hand_world_position := hand_holding_weapon.hand.global_position
	
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
func handle_input(input_type: String, input_side: String, duration: float = 0.0) -> void:
	if !Properties.weapon_controller:
		return
	
	# Route to controller based on input_mode
	match Properties.input_mode:
		Properties.InputMode.CLICK_ONLY:
			if input_type == "click":
				Properties.weapon_controller.handle_click(self, input_side)
		Properties.InputMode.HOLD_ACTION:
			if input_type == "click":
				Properties.weapon_controller.handle_click(self, input_side)
			elif input_type == "hold":
				Properties.weapon_controller.handle_hold(self, input_side, duration)
			elif input_type == "release":
				Properties.weapon_controller.handle_release(self, input_side, duration)
		Properties.InputMode.BOTH:
			Properties.weapon_controller.handle_input(self, input_type, input_side, duration)

func _update_collisions(state: String) -> void:
	match state:
		"on-ground":
			set_collision_layer_value(4, true)   # Item
			set_collision_layer_value(5, false)   # Weapon
			
			set_collision_mask_value(2, false)   # Player
			set_collision_mask_value(3, false)   # Enemy
			set_collision_mask_value(4, true)   # Item
			set_collision_mask_value(5, false)   # Weapon
			
		"in-hand":
			set_collision_layer_value(4, false)   # Item
			set_collision_layer_value(5, true)   # Weapon
			
			set_collision_mask_value(2, false)   # Player
			set_collision_mask_value(3, true)   # Enemy
			set_collision_mask_value(4, false)   # Item
			set_collision_mask_value(5, true)   # Weapon
