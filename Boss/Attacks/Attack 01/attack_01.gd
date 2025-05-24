extends BossAttackClass

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func initialize(attack_data: AttackResource) -> void:
	# Set up the attack based on the attack resource data
	var boss: BossClass = get_parent().get_parent().get_parent().get_parent()
	var target_pos: Vector2 = boss.target.global_position
	var direction: Vector2 = (target_pos - boss.global_position).normalized()
	var attack_type_str: String = AttackResource.AttackType.keys()[attack_data.attack_type].to_lower()
	
	# Use the position that was set by boss_attack_node (where the telegraph was)
	spawn_position = global_position
	
	# Set common properties
	Attacker = boss
	attack_power = attack_data.damage
	attack_type = attack_type_str
	attack_direction = direction
	attack_duration = attack_data.attack_duration
	
	# Start the destroy timer
	var destroy_timer: SceneTreeTimer = get_tree().create_timer(attack_duration)
	destroy_timer.timeout.connect(trigger_destroy)
	
	# Activate the attack
	_activate_TorF(true)
