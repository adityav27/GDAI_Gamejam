extends Node

@onready var enemy: CharacterBody3D = $".."
@onready var animation_player: AnimationPlayer = $"../red enemy/AnimationPlayer"
@export var _blend_time := 0.1

var is_attacking_finished = false

func _physics_process(delta: float) -> void:
	
	match enemy.state:
		enemy.States.idle:
			play("Idle", 1.0)

		enemy.States.chase:
			play("Run", 1)
		
		enemy.States.search:
			play("Look Around", 1)
			await animation_player.animation_finished
			enemy.state = enemy.States.idle

		enemy.States.attack:
			if 	enemy.is_player_in_attack_zone and is_attacking_finished:
				global_vars.damage_player.emit(30)
				is_attacking_finished = false
			play("Punch", 1.0)
			await animation_player.animation_finished
			is_attacking_finished = true
			
			

		enemy.States.death:
			play("Death01", 1.0)	


func play(anim: String,speed:float) -> void:
	if animation_player.current_animation != anim:
		animation_player.speed_scale=speed
		animation_player.play(anim, _blend_time)
