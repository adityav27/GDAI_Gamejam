extends Node

@onready var player: CharacterBody3D = $".."
@onready var stamina_bar: TextureProgressBar = $"../CanvasLayer/Node/StaminaBar"

@onready var sfx_run: AudioStreamPlayer3D = $Run
@onready var sfx_walk: AudioStreamPlayer3D = $Walk
@onready var sfx_jump: AudioStreamPlayer3D = $Jump

var is_crouching = false
var _current_sfx = ""

func _physics_process(delta: float) -> void:
	var ground_speed = player.velocity.length()
	var t_pose = Input.is_action_pressed("tpose")
	var stamina = stamina_bar.value

	if t_pose:
		stop_all()


	elif not player.is_on_floor():
		if player.velocity.length() > 0.1:
			play("Jump")
		return


	elif is_crouching:
		stop_all()
		return

	# Normal ground movement
	elif ground_speed > 2:
		if (player.move_speed == player.run_speed) and (stamina > 1):
			play("Run")
		else:
			play("Walk")
	else:
		stop_all()

# stops .
func play(sfx_name: String) -> void:
	if _current_sfx == sfx_name:
		return

	stop_all()
	_current_sfx = sfx_name

	match sfx_name:
		"Run":
			sfx_walk.pitch_scale = 1.4
			sfx_walk.play()
		"Walk":
			sfx_walk.pitch_scale = 1.0
			sfx_walk.play()
		"Crouch":
			sfx_walk.pitch_scale = 0.8
			sfx_walk.play()
		"Jump":
			sfx_jump.play()

func stop_all() -> void:
	_current_sfx = ""
	sfx_run.stop()
	sfx_walk.stop()
	sfx_jump.stop()

func _on_player_crouched() -> void:
	is_crouching = true

func _on_player_stood() -> void:
	is_crouching = false
