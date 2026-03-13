extends VBoxContainer


# Called when the node enters the scene tree for the first time.
@onready var levels: Button = $Levels
@onready var exit: Button = $Exit

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file("res://cutscene/cutscene.tscn")



func _on_levels_mouse_entered() -> void:
	levels.create_tween().tween_property(levels, "scale", Vector2(1.3,1.3), 0.15)


func _on_levels_mouse_exited() -> void:
	levels.	create_tween().tween_property(levels, "scale", Vector2(1,1), 0.15)
