extends Node

@onready var enemy: CharacterBody3D = $".."
@onready var animation_player: AnimationPlayer = $"../red enemy/AnimationPlayer"
@export var _blend_time := 0.25



var is_attacking_finished = false

func _physics_process(delta: float) -> void:

	if enemy.state != enemy.next_state:

		# Prevent interrupting attack animation
		if enemy.state == enemy.States.attack:
			return

		enemy.change_state(enemy.next_state)


	match enemy.state:

		enemy.States.idle:
			play("idle",1)

		enemy.States.chase:
			play("Run",1)

		enemy.States.search:
			play("Look Around",1)

		enemy.States.attack:
			if animation_player.current_animation != "Punch":
				play("Punch",1.3)
				await animation_player.animation_finished

				if enemy.is_player_in_attack_zone:
					global_vars.damage_player.emit(10)

				enemy.change_state(enemy.next_state)

		enemy.States.death:
			play("Death01",1)

func play(anim: String,speed:float) -> void:
	if animation_player.current_animation != anim:
		animation_player.speed_scale=speed
		animation_player.play(anim, _blend_time)
