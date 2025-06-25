extends StaticBody2D

@export var has_items: bool
@export var items: Array[Resource]
var nearby: Array[Node2D]


func _process(_delta: float) -> void:
	if nearby and Input.is_action_just_pressed("interact"):
		_open_chest()


func _open_chest() -> void:
	if items:
		for item in items:
			var _item: WeaponClass = Global.WEAPON.instantiate()
			_item.Properties = item	
			var _offset = Vector2(randi_range(-20, 20), randi_range(-20, 20))
			_item.global_position = global_position + _offset
			get_parent().add_child(_item)
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	nearby.append(body)


func _on_area_2d_body_exited(body):
	if nearby.has(body):
		nearby.remove_at(nearby.find(body))
