class_name BallClass extends RigidBody2D

# Network synchronization variables
var target_position: Vector2 = Vector2.ZERO
var target_velocity: Vector2 = Vector2.ZERO
var smoothing_speed: float = 20.0  # Range: 5.0-30.0 - Higher values make the ball respond faster to server updates
var update_frequency: float = 0.01  # Range: 0.005-0.05 - Lower values send more frequent updates (100 times per second)
var update_timer: float = 0.0
var prediction_factor: float = 1.5  # Range: 0.5-3.0 - Higher values predict further ahead of current trajectory

# Ball physics parameters
var max_ball_speed: float = 600.0  # Maximum speed the ball can travel at

# Knockback parameters
var knockback_strength: float = 5.5  # Range: 0.5-3.0 - How strongly the ball pushes players (increased from 1.5)
var min_velocity_for_knockback: float = 150.0  # Range: 50-200 - Minimum ball velocity to cause knockback

# Visual representation for client
var visual_node: Sprite2D = null

# Collision tracking
var last_collision_time: Dictionary = {}
var collision_cooldown: float = 0.3

# Debug tracking
var last_sent_position: Vector2
var last_sent_velocity: Vector2
var is_moving: bool = false

# Color settings
var color_slow: Color = Color.GREEN
var color_medium: Color = Color.YELLOW
var color_fast: Color = Color.ORANGE
var color_max: Color = Color.RED
var speed_medium_threshold: float = max_ball_speed * 0.3  # 30% of max speed
var speed_fast_threshold: float = max_ball_speed * 0.6    # 60% of max speed

func _ready() -> void:
	global_position = get_tree().current_scene.get_node("Spawn Points/Ball Spawn").global_position
	last_sent_position = global_position
	last_sent_velocity = Vector2.ZERO
	
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		# Initial color is green
		_update_ball_color(0)
	else:
		_setup_client()

func _setup_client() -> void:
	# Disable physics on client
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)  # Don't collide with world
	set_collision_mask_value(2, false)  # Don't collide with players
	set_physics_process(false)
	
	# Initialize target values
	target_position = global_position
	target_velocity = linear_velocity
	
	# Create visual representation
	visual_node = Sprite2D.new()
	visual_node.texture = $Sprite2D.texture
	visual_node.modulate = color_slow  # Start with green
	add_child(visual_node)
	
	# Hide original sprite
	$Sprite2D.visible = false

func _process(delta: float) -> void:
	if multiplayer.is_server():
		# Update ball color on server based on speed
		_update_ball_color(linear_velocity.length())
	elif visual_node:
		_update_client_visuals(delta)
	
	# Update collision cooldown timers
	var keys_to_remove: Array = []
	for player_id: int in last_collision_time:
		last_collision_time[player_id] -= delta
		if last_collision_time[player_id] <= 0:
			keys_to_remove.append(player_id)
	
	for key: int in keys_to_remove:
		last_collision_time.erase(key)

func _update_ball_color(speed: float) -> void:
	var new_color: Color
	
	if speed < speed_medium_threshold:
		# Interpolate between green and yellow
		var t: float = speed / speed_medium_threshold
		new_color = color_slow.lerp(color_medium, t)
	elif speed < speed_fast_threshold:
		# Interpolate between yellow and orange
		var t: float = (speed - speed_medium_threshold) / (speed_fast_threshold - speed_medium_threshold)
		new_color = color_medium.lerp(color_fast, t)
	else:
		# Interpolate between orange and red
		var t: float = (speed - speed_fast_threshold) / (max_ball_speed - speed_fast_threshold)
		t = min(t, 1.0)  # Cap at 1.0 for speeds exceeding max_ball_speed
		new_color = color_fast.lerp(color_max, t)
	
	# Apply color to the appropriate sprite
	if multiplayer.is_server():
		$Sprite2D.modulate = new_color
	elif visual_node:
		visual_node.modulate = new_color

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
	
	# Update ball color based on current velocity
	_update_ball_color(target_velocity.length())

func _physics_process(delta: float) -> void:
	# This will only run on the server due to set_physics_process(false) on clients
	
	# Cap the ball speed to the maximum
	if linear_velocity.length() > max_ball_speed:
		linear_velocity = linear_velocity.normalized() * max_ball_speed
		print("⚠️ Ball speed capped at maximum: %.2f" % max_ball_speed)
	
	update_timer += delta
	if update_timer >= update_frequency:
		_update_ball_state()
		update_timer = 0.0
		
		# Track if the ball is actually moving significantly
		is_moving = (global_position - last_sent_position).length() > 1.0
		last_sent_position = global_position
		last_sent_velocity = linear_velocity

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
	var is_host: bool = player_id == 1
	var player_type: String = "HOST" if is_host else "CLIENT"
	
	# Apply collision cooldown
	if player_id in last_collision_time and last_collision_time[player_id] > 0:
		print("⚠️ COLLISION REJECTED - Too soon after last collision with %s" % player_type)
		return
	
	# Set collision cooldown
	last_collision_time[player_id] = collision_cooldown
	
	print("⚽ BALL COLLISION with %s (ID: %s)" % [player_type, player_id])
	
	var ball_speed: float = linear_velocity.length()
	var ball_to_player: Vector2 = (body.global_position - global_position).normalized()
	
	# CRITICAL CHECK: Is the ball really moving?
	if !is_moving or ball_speed < 50:
		print("  ⚠️ Ball appears stationary (moved: %s, speed: %.2f) - NO KNOCKBACK" % [is_moving, ball_speed])
		return
	
	print("  ⚡ Ball speed: %.2f, Player speed: %.2f" % [ball_speed, body.velocity.length()])
	
	# Check if player is deliberately moving toward the ball
	var player_moving_toward_ball: bool = _is_player_moving_toward_ball(body, ball_to_player)
	if player_moving_toward_ball:
		print("  ❌ NO KNOCKBACK: %s player is walking into ball" % player_type)
		return
	
	# Check if the ball is moving toward the player and is fast enough
	var ball_dir: Vector2 = linear_velocity.normalized()
	var ball_moving_toward_player: bool = ball_dir.dot(ball_to_player) < -0.3
	print("  🔍 Ball moving toward player: %s (dot: %.2f)" % [ball_moving_toward_player, ball_dir.dot(ball_to_player)])
	
	if !ball_moving_toward_player:
		print("  ❌ NO KNOCKBACK: Ball is not moving toward player")
		return
	
	# For clients, require a higher minimum velocity to account for prediction error
	var effective_min_velocity: float = min_velocity_for_knockback
	if player_id != 1:  # If not the host
		effective_min_velocity = min_velocity_for_knockback * 1.5  # Higher threshold for non-host players
	
	print("  📊 Effective min velocity: %.2f (base: %.2f)" % [effective_min_velocity, min_velocity_for_knockback])
	
	if ball_speed > effective_min_velocity:
		var knockback_force: float = ball_speed * knockback_strength
		print("  ✅ APPLYING KNOCKBACK to %s: Force=%.2f, Direction=%.2f,%.2f" % 
			[player_type, knockback_force, ball_to_player.x, ball_to_player.y])
		
		# Fix: Handle host and client knockback differently
		if is_host:
			# For the host (server), directly call apply_knockback instead of using RPC
			print("  🌐 Direct knockback for HOST")
			body.apply_knockback(ball_to_player, knockback_force)
		else:
			# For remote clients, use RPC to send knockback
			print("  📡 RPC knockback for CLIENT")
			body.apply_knockback_rpc.rpc_id(player_id, ball_to_player, knockback_force)
	else:
		print("  ❌ NO KNOCKBACK: Ball not fast enough or not moving toward player")

func _is_player_moving_toward_ball(player: PlayerClass, ball_to_player: Vector2) -> bool:
	if player.velocity.length() <= 50:
		return false
		
	var player_to_ball_dir: Vector2 = -ball_to_player
	var player_dir: Vector2 = player.velocity.normalized()
	var dot_product: float = player_dir.dot(player_to_ball_dir)
	
	return dot_product > 0.3  # Player is moving toward ball
