class_name WeaponClass extends RigidBody2D

@export var Properties: WeaponResource
@onready var Sprite := $Sprite2D
@onready var Collision := $CollisionShape2D
@onready var Controller: WeaponControllerBase = $Controller

var wielder: Node2D
var is_attacking: bool = false
var things_nearby: Array[Node2D] = []
var destroy_on_impact: bool = false
var is_thrown: bool = false
var throw_clone: bool = false
var throw_force: float = 800.0
var throw_torque: float = 10.0
var mod_angle: float = 0.0
var has_synergy: bool

var can_pickup: bool = true
var can_pickup_cd: float = 0.0


func _ready() -> void: _set_props()
func _process(delta: float) -> void: _handle_held_or_pickup(delta)
func _physics_process(_delta: float) -> void: _handle_thrown()


func _set_props() -> void:
	if !Properties: 
		queue_free()
		return
	
	Sprite.texture = Properties.weapon_sprite[0]
	
	if Properties.weapon_controller:
		Controller.set_script(Properties.weapon_controller)
		Controller._ready()
	
	if Properties.weapon_name.is_empty():
		var regex := RegEx.new()
		regex.compile("([^/]+)\\.png")
		var result := regex.search(Sprite.texture.load_path)
		if result:
			Properties.weapon_name = result.get_string(1)
	self.name = Properties.weapon_name
	
	if Collision and Collision.shape is CapsuleShape2D:
		Collision.shape.radius = Properties.weapon_col_radius
		Collision.shape.height = Properties.weapon_col_height
		Collision.rotation = Properties.weapon_col_rotation
		Collision.position = Properties.weapon_col_position
	else:
		print_debug("DEBUG: Collision shape is not a CapsuleShape2D")
	
	if wielder:
		modulate = wielder.Sprite.modulate
		_update_collisions("in-hand")
		
		if Controller.has_method("on_equip"):
			Controller.on_equip()
	else:
		_update_collisions("on-ground")


func _handle_held_or_pickup(delta: float) -> void:
	if wielder and !is_thrown:
		var weapon_angle: float = Properties.weapon_angle
		if Controller.is_either_handed() and Controller.in_offhand:
			weapon_angle = 180 - Properties.weapon_angle
		var dir := deg_to_rad(weapon_angle + mod_angle)
		rotation = lerp_angle(rotation, get_parent().rotation + dir, delta*10)
		
		if Properties.weapon_controller:
			Controller.set_script(Properties.weapon_controller)
			Controller.update(delta)
	else:
		can_pickup_cd = max(can_pickup_cd - delta, 0.0)
		if can_pickup_cd == 0.0:
			can_pickup = true
		else:
			print('cooldown: ', can_pickup_cd)
		if !can_pickup: return
		if things_nearby and Input.is_action_just_pressed("interact"):
			attempt_pickup()


func _handle_thrown() -> void:
	if is_thrown:
		wielder = null
		var collisions := get_colliding_bodies()
		for collider: Node2D in collisions:
			if collider:
				if wielder:
					if collider == wielder:
						continue
					if collider.is_in_group("Weapon") and collider.wielder == wielder:
						continue
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
	
	var nearest_thing: Node2D = things_nearby[0]
	var target_hand: PlayerHandClass
	match Properties.weapon_hand:
		Properties.Handedness.LEFT:
			target_hand = nearest_thing.Hands.Left
		Properties.Handedness.RIGHT:
			target_hand = nearest_thing.Hands.Right
		Properties.Handedness.BOTH:
			pass
		Properties.Handedness.EITHER:
			if !nearest_thing.Hands.Left.held_weapon:
				target_hand = nearest_thing.Hands.Left
			elif !nearest_thing.Hands.Right.held_weapon:
				target_hand = nearest_thing.Hands.Right
			else:
				target_hand = nearest_thing.Hands.Left
	
	pickup_weapon(nearest_thing, target_hand)
	#for weapon: WeaponClass in get_tree().get_nodes_in_group("Weapon"):
		#weapon.things_nearby.clear()


func pickup_weapon(player: Node2D, target_hand: PlayerHandClass) -> void:
	wielder = player
	is_thrown = false
	target_hand.held_weapon = self
	things_nearby.erase(player)
	
	##TODO: Rip out to function (used in ready)
	modulate = wielder.Sprite.modulate
	Sprite.position = Properties.weapon_offset
	Collision.position = Properties.weapon_offset
	global_position = target_hand.hand.global_position
	_update_collisions("in-hand")
	
	var held_weapons := target_hand.hand.get_children()
	for held_weapon in held_weapons:
		if held_weapon.is_in_group("Weapon"):
			held_weapon.drop_weapon(held_weapon, wielder)
	
	call_deferred("reparent", target_hand.hand)
	Controller.on_equip()


func drop_weapon(weapon: WeaponClass, player: Node2D) -> void:
	weapon.modulate = Color.WHITE
	weapon.Sprite.position = Vector2.ZERO
	weapon.Collision.position = Vector2.ZERO
	weapon._update_collisions("on-ground")
	
	var hand_holding_weapon: PlayerHandClass = null
	if player.Hands.Left.held_weapon == weapon:
		hand_holding_weapon = player.Hands.Left
	elif player.Hands.Right.held_weapon == weapon:
		hand_holding_weapon = player.Hands.Right
	
	weapon.wielder = null
	if hand_holding_weapon:
		hand_holding_weapon.held_weapon = null
	
	weapon.call_deferred("reparent", player.get_parent())
	weapon.global_position = player.global_position + Vector2(randi_range(-20, 20), randi_range(-20, 20))


func throw_weapon(mod_damage: float = 0.0) -> void:
	if !wielder: return
	var throw_direction := _calculate_throw_direction(wielder)
	var projectile: WeaponClass
	
	if throw_clone:
		projectile = self.duplicate() as WeaponClass
		if !projectile: return
		projectile.Properties = projectile.Properties.duplicate()
		if !projectile.Properties: return
		
		wielder.get_parent().add_child(projectile)
		projectile.throw_clone = true
		projectile.wielder = wielder
		projectile.Sprite.position = Vector2.ZERO
		projectile.Collision.position = Vector2.ZERO
		projectile.Properties.weapon_mod_damage = mod_damage
		projectile._update_collisions("projectile")
	else:
		projectile = self
		# Remove from hand
		var hand_holding_weapon: PlayerHandClass = null
		if wielder.Hands.Left.held_weapon == self:
			hand_holding_weapon = wielder.Hands.Left
		elif wielder.Hands.Right.held_weapon == self:
			hand_holding_weapon = wielder.Hands.Right
		if hand_holding_weapon:
			hand_holding_weapon.held_weapon = null
		
		projectile.is_thrown = true
		projectile.Sprite.position = Vector2.ZERO
		projectile.Collision.position = Vector2.ZERO
		projectile._update_collisions("projectile")
		projectile.Controller.reset_arm_position(get_process_delta_time(), 10.0)

	
	var throw_style := projectile.Properties.weapon_throw_style
	if projectile.Controller.in_offhand and projectile.Controller.hold_position:
		throw_style = Properties.ThrowStyle.STRAIGHT
		projectile.Controller.handle_release()
	match throw_style:
		Properties.ThrowStyle.STRAIGHT:
			projectile.global_rotation = throw_direction.angle()
			projectile.angular_velocity = 0.0
		Properties.ThrowStyle.SPIN:
			projectile.global_rotation = throw_direction.angle()
			projectile.angular_velocity = throw_torque * 2.0
		Properties.ThrowStyle.TUMBLE:
			projectile.global_rotation = throw_direction.angle()
			projectile.angular_velocity = throw_torque * 0.5
	
	if !throw_clone: call_deferred("reparent", wielder.get_parent())
	
	projectile.wielder = null
	projectile.global_position = global_position
	projectile.linear_velocity = throw_direction.normalized() * throw_force
	projectile.is_thrown = true
	

func reset_to_ground_state() -> void:
	destroy_on_impact = destroy_on_impact or throw_clone
	if destroy_on_impact: 
		queue_free()
		return
	can_pickup = false
	can_pickup_cd = get_process_delta_time() * 100
	wielder = null
	is_thrown = false
	angular_velocity = 0.0
	linear_velocity = Vector2.ZERO
	Sprite.position = Vector2.ZERO
	Controller.in_offhand = false
	Controller.hold_position = false
	Controller.cooldown_duration = 0.0
	Collision.position = Vector2.ZERO
	Properties.weapon_mod_damage = 0.0
	_update_collisions("on-ground")
	var Entities := get_tree().get_first_node_in_group("Entities")
	call_deferred("reparent", Entities)


#func _set_held_sprite_position() -> void:
	## Safely set sprite position when weapon is held
	#if Sprite and Properties:
		#Sprite.position = Properties.weapon_offset

# Weapon input handling methods
func handle_input(input_type: String, duration: float = 0.0) -> void:
	if !wielder: return
	match input_type:
		"click":
			Controller.handle_click()
		"hold":
			Controller.handle_hold()
		"release":
			Controller.handle_release()
		_:
			Controller.handle_input(input_type, duration)


func _calculate_throw_direction(player: Node2D) -> Vector2:
	if !player.Input_Handler.look_dir.is_zero_approx():
		return player.Input_Handler.look_dir
	elif !player.tar_pos.is_zero_approx():
		return player.tar_pos.normalized()
	else:
		return Vector2(cos(player.rotation - PI/2), sin(player.rotation - PI/2))


func _update_collisions(state: String) -> void:
	match state:
		"on-ground":
			#modulate = Color.WEB_GRAY
			set_collision_layer_value(4, true)  # Item
			set_collision_layer_value(5, false) # Weapon
			set_collision_mask_value(2, false)  # Player
			set_collision_mask_value(1, true)  # World
			set_collision_mask_value(3, false)  # Enemy
			set_collision_mask_value(4, true)  # Item
			set_collision_mask_value(5, false)  # Weapon
			set_z_index(Global.Layers.WEAPON_ON_GROUND)
			
		"in-hand":
			#modulate = Color.BLUE
			set_collision_layer_value(4, false) # Item
			set_collision_layer_value(5, false)  # Weapon
			set_collision_mask_value(2, false)  # Player
			set_collision_mask_value(1, false)  # World
			set_collision_mask_value(3, false)   # Enemy
			set_collision_mask_value(4, false)  # Item
			set_collision_mask_value(5, false)  # Weapon
			set_z_index(Global.Layers.WEAPON_IN_HAND)
			
		"projectile":
			#modulate = Color.RED
			set_collision_layer_value(4, false) # Item
			set_collision_layer_value(5, true)  # Weapon
			set_collision_mask_value(1, true)  # World
			set_collision_mask_value(2, false)  # Player
			set_collision_mask_value(3, true)   # Enemy
			set_collision_mask_value(4, false)  # Item
			set_collision_mask_value(5, false)  # Weapon
			set_z_index(Global.Layers.PROJECTILES)
