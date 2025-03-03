extends CanvasLayer


func _ready() -> void:
	visible = multiplayer.is_server()


func _process(_delta: float) -> void:
	pass
