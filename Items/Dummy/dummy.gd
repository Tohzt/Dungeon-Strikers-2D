extends RigidBody2D
@onready var rot_start := rotation
var wiggle := false
var wiggle_intensity := 0.0
var wiggle_direction := 1
var wiggle_decay := 0.95


func _process(_delta: float) -> void:
	z_index = Global.Layers.ENEMIES
	if wiggle:
		pass
		#rotate(deg_to_rad(wiggle_intensity * wiggle_direction))
		#wiggle_intensity *= wiggle_decay

func _physics_process(_delta: float) -> void:
	var collision: KinematicCollision2D = move_and_collide(Vector2.ZERO, true)
	if !collision: return
	var collider := collision.get_collider()
	if collider and collider.is_in_group("Weapon") and !wiggle: 
		printt(collider.Properties.weapon_damage, " || ", collider.linear_velocity)
		apply_central_impulse(collider.linear_velocity * collider.Properties.weapon_damage)
		#_start_wiggle()
		#wiggle_intensity = (collider.Properties.weapon_damage / 100.0) * 15.0
		#wiggle_direction = 1 if randf() > 0.5 else -1


func _start_wiggle() -> void:
	wiggle = true
	var timer := Timer.new()
	add_child(timer)
	timer.connect("timeout", _stop_wiggle)
	timer.start(0.5)

func _stop_wiggle() -> void:
	rotation = rot_start
	wiggle = false
	wiggle_intensity = 0.0
