extends StateClass

##HACK: Temp display crosshair
signal target_position_changed(new_position: Vector2)

var target_position: Vector2
var direction_timer: float = 0.0
const DIRECTION_CHANGE_TIME: float = 2.0
const WANDER_RADIUS: float = 200.0
const SPEED_MULTIPLIER: float = 10000.0

func enter() -> void:
	super.enter()
	_pick_new_target()

func update(delta: float) -> void:
	_is_on_target()
	
	direction_timer += delta
	if direction_timer >= DIRECTION_CHANGE_TIME:
		_pick_new_target()
		direction_timer = 0
	
	var direction: Vector2 = (target_position - Master.global_position).normalized()
	##TODO: Don't set velocity directly. Update Master's target_position
	Master.velocity = direction * SPEED_MULTIPLIER * delta

func _is_on_target() -> void:
	if Master.global_position.distance_to(target_position) < 10:
		direction_timer = DIRECTION_CHANGE_TIME

func _pick_new_target() -> void:
	var random_angle: float = randf_range(0, TAU)
	var tar_pos := Master.global_position + Vector2(
		cos(random_angle) * WANDER_RADIUS,
		sin(random_angle) * WANDER_RADIUS
	)
	
	## TODO: Consider getting room from Master
	# Master can track room on enter/exit
	var current_room: RoomClass
	for room in get_tree().get_nodes_in_group("Room"):
		if room.current_room:
			current_room = room
			break
	
	if current_room:
		var padding := 10.0
		var room_area: Area2D = current_room.area
		var room_shape: CollisionShape2D = room_area.get_node("CollisionShape2D")
		var room_rect := Rect2(
			room_area.global_position,
			room_shape.shape.size
		)
		
		if !room_rect.grow(-padding).has_point(tar_pos):
			_pick_new_target()
			return
	target_position = tar_pos
	
	##HACK: Temp display crosshair
	emit_signal("target_position_changed", target_position)
