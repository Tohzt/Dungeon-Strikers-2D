class_name PlayerInputHandler extends HandlerClass

@export var attack_handler: HandlerClass

var velocity: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and attack_handler.can_attack:
			attack_handler.attack_confirmed = true
			var mouse_position: Vector2 = Master.get_global_mouse_position()
			attack_handler.attack_direction = (mouse_position - Master.global_position).normalized()
		if event.is_released():
			attack_handler.attack_confirmed = false

func _process(delta: float) -> void:
	if !Master.has_authority: return
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		var prev_dir: Vector2 = velocity.normalized()
		velocity.x = lerp(prev_dir.x, direction.x, delta*10) * Master.SPEED
		velocity.y = lerp(prev_dir.y, direction.y, delta*10) * Master.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, Master.SPEED)
		velocity.y = move_toward(velocity.y, 0, Master.SPEED)
