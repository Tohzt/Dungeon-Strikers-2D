extends RigidBody2D

var invincible: bool = false
var i_frame_duration: float = 0.1

func _ready() -> void:
	body_entered.connect(_on_weapon_hit)

func _process(_delta: float) -> void:
	z_index = Global.Layers.ENEMIES

func _on_weapon_hit(body: Node2D) -> void:
	if body and body.is_in_group("Weapon") and !invincible:
		var weapon_damage: float = body.Properties.weapon_damage
		var weapon_mod_damage: float = body.Properties.weapon_mod_damage
		var weapon_total_damage: float = weapon_damage + weapon_mod_damage
		var weapon_velocity: Vector2 = body.linear_velocity
		var impact_force := weapon_velocity * weapon_total_damage
		apply_central_impulse(impact_force)
		
		Global.display_damage(weapon_total_damage, global_position)
		
		_start_i_frames()

func _start_i_frames() -> void:
	modulate = Color.RED
	invincible = true
	
	var timer := Timer.new()
	add_child(timer)
	timer.timeout.connect(_end_i_frames)
	timer.start(i_frame_duration)
	timer.one_shot = true

func _end_i_frames() -> void:
	modulate = Color.WHITE
	invincible = false
