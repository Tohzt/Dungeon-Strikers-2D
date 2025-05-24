extends StateClass

const Attack_Resource = preload("res://Boss/Attacks/attack_resource.gd")
const Boss_Attack_Node = preload("res://Boss/Attacks/boss_attack_node.gd")

@export var attack_resources: Array[AttackResource]
var current_attack: BossAttackNode

func enter_state() -> void:
	##TODO: Get nearest target.. or whatever should take the agro
	Master.target = get_tree().get_first_node_in_group("Player")
	super.enter_state()

func update(_delta: float) -> void:
	if !Master.target_locked:
		exit_to("wander_state")
		return
	
	# Clear current_attack if it's been destroyed
	if current_attack and !is_instance_valid(current_attack):
		print("Attack was destroyed, clearing reference")
		current_attack = null
	
	# Check if we should start a new attack
	if !current_attack and Master.ATTACK_COOLDOWN <= 0:
		print("No current attack and cooldown finished, starting new attack")
		_decide_attack()
	
	# Only move if not casting
	if current_attack and current_attack.is_casting:
		Master.velocity = Vector2.ZERO
		return

func _decide_attack() -> void:
	var attack_node: BossAttackNode = BossAttackNode.new()
	attack_node.attack_data = _get_attack_resource()
	if attack_node.attack_data:
		print("Starting attack: ", attack_node.attack_data.attack_name)
		add_child(attack_node)
		Master.ATTACK_COOLDOWN = attack_node.attack_data.cooldown + attack_node.attack_data.cast_time
		print("Set cooldown to: ", Master.ATTACK_COOLDOWN)
		current_attack = attack_node
		attack_node.start_cast()

func _get_attack_resource() -> AttackResource:
	var valid_attacks: Array[AttackResource] = attack_resources.filter(func(attack: AttackResource) -> bool: 
		return _is_attack_valid(attack)
	)
	printt(attack_resources, valid_attacks)
	return valid_attacks[randi() % valid_attacks.size()] if valid_attacks.size() > 0 else null

func _is_attack_valid(attack: AttackResource) -> bool:
	if !attack: return false
	var distance_to_target := Master.global_position.distance_to(Master.target.global_position)
	
	match attack.attack_type:
		AttackResource.AttackType.MELEE:
			return distance_to_target < 100
		AttackResource.AttackType.PROJECTILE:
			return distance_to_target > 100  # Good for medium range
		AttackResource.AttackType.MAGIC:
			return distance_to_target > 150  # Good for long range
		AttackResource.AttackType.AOE:
			return true  # Can be used at any time
		AttackResource.AttackType.BUFF:
			return true  # Can be used when boss needs buffs
		AttackResource.AttackType.TELEPORT:
			return distance_to_target > 200  # Use when far from target
		AttackResource.AttackType.HEAL:
			return Master.hp < Master.hp_max * 0.5  # Use when below 50% health
	return false
