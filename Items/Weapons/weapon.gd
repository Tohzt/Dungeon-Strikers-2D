extends Node2D
@onready var Sprite: Sprite2D = $Sprite2D
@export var Properties: WeaponResource

var weapon_holder: Node2D

func _ready() -> void:
	if Properties:
		Sprite.texture = Properties.weapon_sprite[0]
		if Properties.weapon_name.is_empty():
			var regex := RegEx.new()
			regex.compile("([^/]+)\\.png")
			var result := regex.search(Sprite.texture.load_path)
			if result:
				Properties.weapon_name = result.get_string(1)
		
		
	else: queue_free()


func _process(delta: float) -> void:
	if weapon_holder:
		var dir := deg_to_rad(Properties.weapon_angle)
		rotation = lerp_angle(rotation, get_parent().rotation + dir, delta*10)


func _on_pickup_body_entered(body: Node2D) -> void:
	if weapon_holder: return
	if !body.is_in_group("Entity"): return
	weapon_holder = body
	Sprite.position = Properties.weapon_offset
	if Properties.weapon_hand == Properties.Handedness.LEFT:
		global_position = body.Hands.Left.hand.global_position #- Properties.weapon_offset
		call_deferred("reparent", body.Hands.Left.hand)
	else:
		global_position =body.Hands.Right.hand.global_position #- Properties.weapon_offset
		call_deferred("reparent", body.Hands.Right.hand)
