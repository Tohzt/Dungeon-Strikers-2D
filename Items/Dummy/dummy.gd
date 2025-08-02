extends RigidBody2D

func _ready(): body_entered.connect(_on_weapon_hit)

func _process(_delta: float) -> void:
	z_index = Global.Layers.ENEMIES

func _physics_process(delta):
	var collider = get_colliding_bodies()
	if collider:
		print(collider)

func _on_weapon_hit(body: Node2D) -> void:
	if body and body.is_in_group("Weapon"):
		var weapon_damage = body.Properties.weapon_damage
		var weapon_velocity = body.linear_velocity
		var impact_force = weapon_velocity * weapon_damage
		apply_central_impulse(impact_force)
		
		# Spawn damage display above the dummy
		Global.spawn_damage_display(weapon_damage, global_position)
		
		##TODO: Probs a good idea to add this get_
		#if body.has_method("get_weapon_damage"):
			#weapon_damage = body.get_weapon_damage()
		
