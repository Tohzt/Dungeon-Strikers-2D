extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = get_parent().name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	global_position = get_parent().global_position - Vector2(50,80)
