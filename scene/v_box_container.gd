extends VBoxContainer


# Called when the node enters the scene tree for the first time.




func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/level_1.tscn")
	pass # Replace with function body.
	







func _on_quit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.


func _on_exit_button_down() -> void:
	pass # Replace with function body.
