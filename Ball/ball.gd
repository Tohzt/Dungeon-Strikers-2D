class_name BallClass extends RigidBody2D

# Network synchronization variables
var target_position: Vector2 = Vector2.ZERO
var target_velocity: Vector2 = Vector2.ZERO
var smoothing_speed: float = 20.0  # Range: 5.0-30.0 - Higher values make the ball respond faster to server updates
var update_frequency: float = 0.01  # Range: 0.005-0.05 - Lower values send more frequent updates (100 times per second)
var update_timer: float = 0.0
var prediction_factor: float = 1.5  # Range: 0.5-3.0 - Higher values predict further ahead of current trajectory

# Knockback parameters
var knockback_strength: float = 1.5  # Range: 0.5-3.0 - How strongly the ball pushes players
var min_velocity_for_knockback: float = 150.0  # Range: 50-200 - Minimum ball velocity to cause knockback

# Visual representation for client
var visual_node: Sprite2D = null

func _ready() -> void:
	global_position = get_tree().current_scene.get_node("Spawn Points/Ball Spawn").global_position
	
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		modulate = Color.LIME_GREEN
	else:
		_setup_client()

func _setup_client() -> void:
	# Disable physics on client
	set_collision_layer_value(3, false)
	set_physics_process(false)
	
	# Initialize target values
	target_position = global_position
	target_velocity = linear_velocity
	
	# Create visual representation
	visual_node = Sprite2D.new()
	visual_node.texture = $Sprite2D.texture
	visual_node.modulate = $Sprite2D.modulate
	add_child(visual_node)
	
	# Hide original sprite
	$Sprite2D.visible = false

func _process(delta: float) -> void:
	if !multiplayer.is_server() and visual_node:
		_update_client_visuals(delta)

func _update_client_visuals(delta: float) -> void:
	# Calculate smoothing factor based on delta and smoothing speed
	var factor: float = clamp(delta * smoothing_speed, 0.0, 1.0)
	
	# Apply prediction to estimate where the ball will be
	var predicted_position: Vector2 = target_position + (target_velocity * delta * prediction_factor)
	
	# Update the visual representation's position
	visual_node.global_position = visual_node.global_position.lerp(predicted_position, factor)
	
	# Update the actual ball position for collision purposes
	global_position = global_position.lerp(target_position, factor * 1.5)
	linear_velocity = linear_velocity.lerp(target_velocity, factor * 1.5)

func _physics_process(delta: float) -> void:
	# This will only run on the server due to set_physics_process(false) on clients
	update_timer += delta
	if update_timer >= update_frequency:
		_update_ball_state()
		update_timer = 0.0

func _update_ball_state() -> void:
	# Broadcast the ball's position and velocity to clients
	rpc("update_ball_state", global_position, linear_velocity)

@rpc("call_remote")
func update_ball_state(_position: Vector2, _velocity: Vector2) -> void:
	if !multiplayer.is_server():
		target_position = _position
		target_velocity = _velocity

func _on_body_entered(body: Node) -> void:
	# Only the server should handle physics interactions
	if !multiplayer.is_server() or not body is PlayerClass:
		return
	
	var player_id: int = int(str(body.name))
	var ball_speed: float = linear_velocity.length()
	var ball_to_player: Vector2 = (body.global_position - global_position).normalized()
	
	# Check if player is deliberately moving toward the ball
	if _is_player_moving_toward_ball(body, ball_to_player):
		return
	
	# Check if the ball is moving toward the player and is fast enough
	var ball_dir: Vector2 = linear_velocity.normalized()
	var ball_moving_toward_player: bool = ball_dir.dot(ball_to_player) < -0.3
	
	# For clients, require a higher minimum velocity to account for prediction error
	var effective_min_velocity: float = min_velocity_for_knockback
	if player_id != 1:  # If not the host
		effective_min_velocity = min_velocity_for_knockback * 1.5  # Higher threshold for non-host players
	
	if ball_speed > effective_min_velocity and ball_moving_toward_player:
		var knockback_force: float = ball_speed * knockback_strength
		
		# The server has authority over all players, so we can call the RPC directly
		body.apply_knockback_rpc(ball_to_player, knockback_force)

func _is_player_moving_toward_ball(player: PlayerClass, ball_to_player: Vector2) -> bool:
	if player.velocity.length() <= 50:
		return false
		
	var player_to_ball_dir: Vector2 = -ball_to_player
	var player_dir: Vector2 = player.velocity.normalized()
	var dot_product: float = player_dir.dot(player_to_ball_dir)
	
	return dot_product > 0.3  # Player is moving toward ball
