class_name BossAttackNode extends Node2D

const Attack_Resource = preload("res://Boss/Attacks/attack_resource.gd")

@export var attack_data: AttackResource = null

var is_casting: bool = false
var can_attack: bool = true
var telegraph_instance: Node2D = null
var attack_instance: Node2D = null

func _ready() -> void:
	z_index = Global.Layers.TELEGRAPHS
	if !attack_data:
		push_error("Attack data not set for " + name)
		return

func start_cast() -> void:
	if !can_attack: return
	is_casting = true
	can_attack = false
	print("Starting cast for attack: ", attack_data.attack_name)
	
	# Spawn telegraph
	if attack_data.telegraph_scene:
		telegraph_instance = attack_data.telegraph_scene.instantiate()
		add_child(telegraph_instance)
		telegraph_instance.global_position = get_parent().get_parent().get_parent().target.global_position
		telegraph_instance.initialize(attack_data.cast_time)
	
	# Start cast timer
	var cast_timer: SceneTreeTimer = get_tree().create_timer(attack_data.cast_time)
	cast_timer.timeout.connect(_on_cast_complete)

func _on_cast_complete() -> void:
	is_casting = false
	var attack_position: Vector2
	if telegraph_instance:
		attack_position = telegraph_instance.global_position
		telegraph_instance.queue_free()
	
	# Spawn actual attack
	if attack_data.attack_scene:
		print("Cast complete, spawning attack: ", attack_data.attack_name)
		attack_instance = attack_data.attack_scene.instantiate()
		add_child(attack_instance)
		attack_instance.global_position = attack_position
		attack_instance.initialize(attack_data)
		
		# Connect to the attack's destroyed signal
		attack_instance.tree_exiting.connect(_on_attack_destroyed)
	
	# Start cooldown
	var cooldown_timer: SceneTreeTimer = get_tree().create_timer(attack_data.cooldown)
	cooldown_timer.timeout.connect(_on_cooldown_complete)

func _on_attack_destroyed() -> void:
	print("Attack destroyed: ", attack_data.attack_name)
	queue_free()  # Destroy this node when the attack is destroyed

func _on_cooldown_complete() -> void:
	print("Cooldown complete for attack: ", attack_data.attack_name)
	can_attack = true 
