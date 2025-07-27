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
		Sprite.position = Properties.weapon_offset
		Collision.position = Properties.weapon_offset
		_update_collisions("in-hand")
	
		##TODO:
		## Notify weapon controller that weapon was equipped
		#if Properties.weapon_controller:
			#Properties.weapon_controller.on_equip(self)
	else:
		_update_collisions("on-ground")


func _handle_held_or_pickup(delta: float) -> void:
	if wielder and !is_thrown:
		var dir := deg_to_rad(Properties.weapon_angle + mod_angle)
		rotation = lerp_angle(rotation, get_parent().rotation + dir, delta*10)
		
		if Properties.weapon_controller:
			Properties.weapon_controller.update(self, delta)
	else:
		if things_nearby and Input.is_action_just_pressed("interact"):
			# Only attempt pickup if this is the highest priority weapon
			if _is_highest_priority_weapon():
				attempt_pickup()

func _is_highest_priority_weapon() -> bool:
	if !things_nearby.size() > 0: return false
	
	var player: Node2D = things_nearby[0]
	var player_pos := player.global_position
	
	# Find all weapons near the player
	var nearby_weapons: Array[WeaponClass] = []
	for weapon in get_tree().get_nodes_in_group("Weapon"):
		if weapon is WeaponClass and !weapon.wielder and weapon.things_nearby.has(player):
			nearby_weapons.append(weapon)
	
	# Sort by distance to player (closest first)
	nearby_weapons.sort_custom(func(a: WeaponClass, b: WeaponClass) -> bool: 
		return a.global_position.distance_to(player_pos) < b.global_position.distance_to(player_pos)
	)
	
	# Return true if this weapon is the closest
	return nearby_weapons.size() > 0 and nearby_weapons[0] == self


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
	print("Attempting to pick up: ", Properties.weapon_name)
	wielder = player
	target_hand.held_weapon = self
	
	##TODO: Rip out to function (used in ready)
	modulate = player.Sprite.modulate
	Sprite.position = Properties.weapon_offset
	Collision.position = Properties.weapon_offset
	global_position = target_hand.hand.global_position
	call_deferred("reparent", target_hand.hand)
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
	weapon.wielder = null
	if hand_holding_weapon:
		hand_holding_weapon.held_weapon = null
	
	# Move weapon back to world
	weapon.call_deferred("reparent", player.get_parent())
	weapon.global_position = player.global_position + Vector2(randi_range(-20, 20), randi_range(-20, 20))


func throw_weapon(player: Node2D) -> void:
	is_thrown = true
	Sprite.position = Vector2.ZERO
	Collision.position = Vector2.ZERO
	
	var throw_direction := _calculate_throw_direction(player)
	linear_velocity = throw_direction.normalized() * throw_force
	
	# Handle different throw styles
	match Properties.throw_style:
		Properties.ThrowStyle.STRAIGHT:
			global_rotation = throw_direction.angle()
			angular_velocity = 0.0
		Properties.ThrowStyle.SPIN:
			global_rotation = throw_direction.angle()
			angular_velocity = throw_torque * 2.0
		Properties.ThrowStyle.TUMBLE:
			global_rotation = throw_direction.angle()
			angular_velocity = throw_torque * 0.5
	
	if wielder: 
		var hand_holding_weapon: PlayerHandClass = null
		if player.Hands.Left.held_weapon == self:
			hand_holding_weapon = player.Hands.Left
		elif player.Hands.Right.held_weapon == self:
			hand_holding_weapon = player.Hands.Right
		
		if !hand_holding_weapon: return
		
		###TODO: Might be able to do without this
		#add_collision_exception_with(wielder)
		#add_collision_exception_with(wielder.Hands.Left.held_weapon)
		#add_collision_exception_with(wielder.Hands.Right.held_weapon)
		
		call_deferred("reparent", player.get_parent())
		wielder = null
		hand_holding_weapon.held_weapon = null
		global_position = hand_holding_weapon.hand.global_position
		


func reset_to_ground_state() -> void:
	is_thrown = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	Sprite.position = Vector2.ZERO
	Collision.position = Vector2.ZERO
	_update_collisions("on-ground")


func _set_held_sprite_position() -> void:
	# Safely set sprite position when weapon is held
	if Sprite and Properties:
		Sprite.position = Properties.weapon_offset

# Weapon input handling methods
func handle_input(input_type: String, duration: float = 0.0) -> void:
	if !wielder or !Properties.weapon_controller: return
	
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

##TODO: I think I can remove this and rely on Throw mechanic
#func fire_weapon(trigger_weapon: WeaponClass = null) -> void:
	#if !wielder: return
	#
	#var player: Node2D = wielder
	#var throw_direction := _calculate_throw_direction(player)
	#
	#if !trigger_weapon:
		#throw_weapon(throw_direction, player)
		#return
	#
	## If trigger weapon provided, clone this weapon and fire it
	#var weapon_clone: WeaponClass = Global.WEAPON.instantiate() as WeaponClass
	#if !weapon_clone:
		#print("Failed to create weapon clone!")
		#return
	#
	#weapon_clone.Properties = Properties
	#player.get_parent().add_child(weapon_clone)
	#
	## Ensure the weapon is properly initialized before setting collision layers
	#weapon_clone._sest_props_or_queu()
	#
	#weapon_clone.modulate = player.Sprite.modulate
	#weapon_clone.global_position = trigger_weapon.global_position + throw_direction.normalized() * 20.0
	#weapon_clone.wielder = player
	#
	#weapon_clone.throw_weapon(throw_direction, player)


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
			printt("On Ground: ", Properties.weapon_name)
			set_collision_layer_value(4, true)  # Item
			set_collision_layer_value(5, false) # Weapon
			set_collision_mask_value(2, false)  # Player
			set_collision_mask_value(3, false)  # Enemy
			set_collision_mask_value(4, false)  # Item
			set_collision_mask_value(5, false)  # Weapon
			set_z_index(Global.Layers.WEAPON_ON_GROUND)
			
		"in-hand":
			printt("In Hand: ", Properties.weapon_name)
			set_collision_layer_value(4, false) # Item
			set_collision_layer_value(5, true)  # Weapon
			set_collision_mask_value(2, false)  # Player
			set_collision_mask_value(3, true)   # Enemy
			set_collision_mask_value(4, false)  # Item
			set_collision_mask_value(5, false)  # Weapon
			set_z_index(Global.Layers.WEAPON_IN_HAND)
			
		"projectile":
			printt("Projectile: ", Properties.weapon_name)
			set_collision_layer_value(4, false) # Item
			set_collision_layer_value(5, true)  # Weapon
			set_collision_mask_value(2, false)  # Player (don't hit the player who fired it)
			set_collision_mask_value(3, true)   # Enemy (can hit enemies)
			set_collision_mask_value(4, false)  # Item (don't hit items on ground)
			set_collision_mask_value(5, false)  # Weapon (don't collide with other weapons when flying)
			set_z_index(Global.Layers.PROJECTILES)
