class_name BallClass extends RigidBody2D

var max_ball_speed: float = 600.0 
var knockback_strength: float = 5.5
var min_velocity_for_knockback: float = 150.0

# Color settings
var color_slow: Color = Color.GREEN
var color_medium: Color = Color.YELLOW
var color_fast: Color = Color.ORANGE
var color_max: Color = Color.RED
var speed_medium_threshold: float = max_ball_speed * 0.3
var speed_fast_threshold: float = max_ball_speed * 0.6

func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		_update_ball_color(0)
	else:
		set_collision_layer_value(3, false)
		set_collision_mask_value(1, false)
		set_collision_mask_value(2, false)
		set_process(false)
		set_physics_process(false)


func _process(_delta: float) -> void:
	_update_ball_color(linear_velocity.length())

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > max_ball_speed:
		linear_velocity = linear_velocity.normalized() * max_ball_speed


func _update_ball_color(speed: float) -> void:
	var new_color: Color
	if speed < speed_medium_threshold:
		var t: float = speed / speed_medium_threshold
		new_color = color_slow.lerp(color_medium, t)
	elif speed < speed_fast_threshold:
		var t: float = (speed - speed_medium_threshold) / (speed_fast_threshold - speed_medium_threshold)
		new_color = color_medium.lerp(color_fast, t)
	else:
		var t: float = (speed - speed_fast_threshold) / (max_ball_speed - speed_fast_threshold)
		t = min(t, 1.0)  
		new_color = color_fast.lerp(color_max, t)
	
	$Sprite2D.modulate = new_color


func _on_body_entered(body: Node) -> void:
	if !multiplayer.is_server() or not body is PlayerClass:
		return
	var ball_speed: float = linear_velocity.length()
	var ball_to_player: Vector2 = (body.global_position - global_position).normalized()
	
	var effective_min_velocity: float = min_velocity_for_knockback
	
	if ball_speed > effective_min_velocity:
		var knockback_force: float = ball_speed * knockback_strength
		body.apply_knockback.rpc(ball_to_player, knockback_force)
