extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		if global_vars.is_keycard_1 and global_vars.is_keycard_2 and global_vars.is_keycard_3 and global_vars.is_keycard_4:
			get_tree().change_scene_to_file("res://scene/win_screen.tscn")
