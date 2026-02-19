extends Node

@onready var enemy: CharacterBody3D = $".."
@onready var animation_player: AnimationPlayer = $"../Visuals/AnimationPlayer"
@export var _blend_time := 0.1


func _physics_process(delta: float) -> void:
	match enemy.state:
		enemy.States.idle:
			play("Idle", 1.0)

		enemy.States.chase:
			play("Sprint", 1)

		enemy.States.attack:
			play("Punch_Jab", 1.0)

		enemy.States.death:
			play("Death01", 1.0)	


func play(anim: String,speed:float) -> void:
	if animation_player.current_animation != anim:
		animation_player.speed_scale=speed
		animation_player.play(anim, _blend_time)
