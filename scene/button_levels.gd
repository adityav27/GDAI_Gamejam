extends Button

func _ready():
	pivot_offset = size / 2

func _on_mouse_entered():
	create_tween().tween_property(self, "scale", Vector2(1.3,1.13), 0.15)

func _on_mouse_exited():
	create_tween().tween_property(self, "scale", Vector2(1,1), 0.15)
