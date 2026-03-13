extends Node

@onready var animation_player: AnimationPlayer = $"../red enemy/AnimationPlayer"
@onready var enemy: CharacterBody3D = $".."
@export var _blend_time := 0.2

var is_attack_finished := true

func _physics_process(delta: float) -> void:
	if not enemy: return

	match enemy.state:
		enemy.State.IDLE:
			play("idle", 1.0)
			
		enemy.State.PATROL:
			play("Walk", 1.0) 	
			
		enemy.State.INVESTIGATE:
			play("Look Around", 1.0)
			
		enemy.State.RETURN:
			play("Walk", 1.0)

		enemy.State.CHASE:
			play("Run", 1.2)

		enemy.State.ATTACK:
			if animation_player.current_animation != "Punch":
				play("Punch",1.3)
				await animation_player.animation_finished
				
				if enemy.is_player_in_attack_zone:
					global_vars.damage_player.emit(50)

				#enemy.change_state(enemy.next_state)


func play(anim_name: String, speed: float) -> void:

	if not animation_player.has_animation(anim_name):
		push_warning("Animation not found: " + anim_name)
		return

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name, _blend_time)
		
	if animation_player.current_animation == anim_name:
		animation_player.speed_scale = speed
