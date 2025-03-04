class_name BallClass extends RigidBody2D

var target_position: Vector2 = Vector2.ZERO
var target_velocity: Vector2 = Vector2.ZERO
var smoothing_speed: float = 20.0  # Increased for even faster updates
var update_frequency: float = 0.01  # Send updates every 0.01 seconds (100 times per second)
var update_timer: float = 0.0
var prediction_factor: float = 1.5  # Adjust prediction strength

# Visual representation for client
var visual_node: Node2D = null

func _ready() -> void:
	global_position = get_tree().current_scene.get_node("Spawn Points/Ball Spawn").global_position
	
	if !multiplayer.is_server():
		self.set_collision_layer_value(3, false)
		# Only disable physics_process, but keep process enabled for interpolation
		self.set_physics_process(false)
		# Initialize target values
		target_position = global_position
		target_velocity = linear_velocity
		
		# Create a visual-only representation for the client
		# This helps separate the visual from the physics representation
		visual_node = Sprite2D.new()
		visual_node.texture = $Sprite2D.texture
		visual_node.modulate = $Sprite2D.modulate
		add_child(visual_node)
		
		# Make the original sprite invisible on client
		$Sprite2D.visible = false
	else: 
		modulate = Color.LIME_GREEN

func _process(delta: float) -> void:
	if !multiplayer.is_server() and visual_node:
		# Calculate smoothing factor based on delta and smoothing speed
		var factor: float = clamp(delta * smoothing_speed, 0.0, 1.0)
		
		# Apply enhanced prediction - estimate where the ball will be based on velocity
		# The prediction_factor allows us to "look ahead" more to compensate for network delay
		var predicted_position: Vector2 = target_position + (target_velocity * delta * prediction_factor)
		
		# Update the visual representation's position
		visual_node.global_position = visual_node.global_position.lerp(predicted_position, factor)
		
		# Update the actual ball position (for collision purposes)
		# We use a higher factor for the actual position to ensure collisions are more accurate
		global_position = global_position.lerp(target_position, factor * 1.5)
		linear_velocity = linear_velocity.lerp(target_velocity, factor * 1.5)

func _physics_process(delta: float) -> void:
	# This will only run on the server due to set_physics_process(false) on clients
	update_timer += delta
	if update_timer >= update_frequency:
		_update_ball_state()
		update_timer = 0.0

func _update_ball_state() -> void:
	# This function is called on the server to update the ball's state
	# Broadcast the ball's position and velocity to clients
	rpc("update_ball_state", global_position, linear_velocity)

@rpc("call_remote")
func update_ball_state(_position: Vector2, _velocity: Vector2) -> void:
	if !multiplayer.is_server():
		target_position = _position
		target_velocity = _velocity
