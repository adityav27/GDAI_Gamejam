extends Node

@onready var player: CharacterBody3D = $".."
@onready var animation_player: AnimationPlayer = $"../visuals/AnimationPlayer"

@export_group("AnimationSettings")
@export var _blend_time = 0.2

func _physics_process(delta: float) -> void:
	var ground_speed = player.velocity.length()
	var is_crouching = Input.is_action_pressed("crouch")
	
	# Air logic
	if not player.is_on_floor():
		if player.velocity.length() > 0.1:
			play("Jump_Start", 1)
		return
	
	# Crouch logic (overrides movement)
	if is_crouching:
		if ground_speed > 0.1:
			play("Crouch_Fwd", 1.2)
		else:
			play("Crouch_Idle", 1)
		return
	
	# Normal ground movement
	if ground_speed > 2:
		if player.move_speed == player.run_speed:
			play("Sprint", 1)
		else:
			play("Walk", 1.2)
	else:
		play("Idle", 1)


func play(anim: String, speed: float) -> void:
	if animation_player.current_animation != anim:
		animation_player.speed_scale = speed
		animation_player.play(anim, _blend_time)
