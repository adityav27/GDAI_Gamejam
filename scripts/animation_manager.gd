extends Node

@onready var player: CharacterBody3D = $".."
@onready var animation_player: AnimationPlayer = $"../visuals/AnimationPlayer"
@onready var stamina_bar: TextureProgressBar = $"../CanvasLayer/Node/StaminaBar"

@export_group("AnimationSettings")
@export var _blend_time = 0.2

var is_crouching = false

func _physics_process(delta: float) -> void:
	var ground_speed = player.velocity.length()
	var t_pose = Input.is_action_pressed("tpose")
	
	var stamina = stamina_bar.value

	if t_pose:
		play("A_TPose", 1)
			
	# Air logic
	elif not player.is_on_floor():
		if player.velocity.length() > 0.1:
			play("Jump_Start", 1)
		return
	

	
	# Crouch logic (overrides movement)
	elif is_crouching:
		if ground_speed > 0.1:
			play("Crouch_Fwd", 1.2)
		else:
			play("Crouch_Idle", 1)
		return
	
	# Normal ground movement
	elif ground_speed > 2:
		if (player.move_speed == player.run_speed) and (stamina > 1):
			play("Sprint", 1)
		else:
			play("Walk", 1.2)
	else:
		play("Idle", 1)


func play(anim: String, speed: float) -> void:
	if animation_player.current_animation != anim:
		animation_player.speed_scale = speed
		animation_player.play(anim, _blend_time)

func _on_player_crouched() -> void:
	is_crouching = true
	
func _on_player_stood() -> void:
	is_crouching = false
