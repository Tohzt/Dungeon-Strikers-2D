class_name BossClass extends CharacterBody2D

var color: Color = Color.TRANSPARENT
@onready var Sprite: Sprite2D = $"Sprite Inner"
@export var Hands: Node2D
@export var Attack_Origin: Marker2D
@onready var ray_target := $RayCast2D

var hp_max: float = 1000.0
var hp: float = hp_max
@export var healthbar: TextureProgressBar

var name_display: String
const SPEED: float = 300.0  
var ATTACK: float = 400.0  
var DEFENSE: float = 100.0

var spawn_pos: Vector2 = Vector2.ZERO
var spawn_rot: float = 0.0

var is_in_iframes: bool = false
var iframes_duration: float = 0.5

var target: PlayerClass
var target_locked: bool = false

func _enter_tree() -> void:
	if multiplayer.is_server():
		set_multiplayer_authority(1)

func _ready() -> void:
	healthbar.max_value = hp_max
	healthbar.value = hp_max


func _process(delta: float) -> void:
	_update_hp(delta)
	##TODO: Get nearest target.. or whatever should take the agro
	target = get_tree().get_first_node_in_group("Player")
	var target_angle := position.direction_to(target.global_position).angle()
	var _offset := deg_to_rad(90)
	ray_target.global_rotation = target_angle + _offset
	var ray_collider: Node2D = ray_target.get_collider()
	if ray_collider:
		target_locked = ray_collider.is_in_group("Player")
	else:
		target_locked = false

	if !is_multiplayer_authority(): return
	
func _physics_process(_delta: float) -> void:
	if !Server.OFFLINE and !multiplayer.is_server(): return
	move_and_slide()


func _update_hp(delta: float) -> void:
	healthbar.global_position = global_position - Vector2(70,80)
	healthbar.value = lerp(healthbar.value, float(hp/hp_max)*hp_max, delta*10)

func reset_position(pos: Vector2) -> void:
	spawn_pos = pos
	global_position = spawn_pos

@rpc("any_peer", "call_local")
func set_color(col: Color) -> void:
	color = col
	healthbar.tint_progress = col
	healthbar.tint_under = col.darkened(0.5)
	Sprite.modulate = color
	set_hand_color(col)

func set_hand_color(col: Color) -> void:
	var hands: Array = Hands.get_children()
	for hand: BossHandClass in hands:
		hand.hand.modulate = col
		hand.particle.modulate = col

func under_attack(atk: float, dir: Vector2) -> void:
	apply_knockback.rpc(dir, atk*100)

@rpc("any_peer", "call_local")
func take_damage(dmg: float, dir: Vector2) -> void:
	if is_in_iframes: return
	if hp > 0:
		hp -= int(dmg)
	apply_knockback(dir, dmg*10)

@rpc("any_peer")
func apply_knockback(_direction: Vector2, _force: float) -> void:
	if is_in_iframes: return
	is_in_iframes = true
	#NOTE: Removing Handlers 
	#Input_Handler.velocity += direction * force
	
	modulate.a = 0.5
	var timer: SceneTreeTimer = get_tree().create_timer(iframes_duration)
	timer.timeout.connect(_end_iframes)

func _end_iframes() -> void:
	is_in_iframes = false
	modulate.a = 1.0
