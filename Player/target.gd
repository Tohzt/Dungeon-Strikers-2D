extends TextureRect
@onready var Master: PlayerClass = get_parent()
var offset: Vector2 = Vector2(-64,-64)

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	modulate = Master.Sprite.modulate
	if Master.target:
		global_position = Master.target.global_position + offset
		if !visible: show()
	else:
		position = Vector2.ZERO
		if visible: hide()
