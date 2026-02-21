extends Control
var button_type= null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	button_type = "start"
	$Fade_Transition/AnimationPlayer.play("fade_in")
	await $Fade_Transition/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scene/demo_level.tscn")
	
	
	
	pass # Replace with function body.



func _on_levels_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.




#func _on_timer_timeout() -> void:
	#if button_type=="start":
			#print("anim started")
			#get_tree().change_scene_to_file("res://scene/demo_level.tscn")
	#pass # Replace with function body.
