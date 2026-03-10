extends Node

@onready var animation_player: AnimationPlayer = $"../Visuals/AnimationPlayer"
@onready var enemy: CharacterBody3D = $".."
@export var _blend_time := 0.2

func _physics_process(delta: float) -> void:
	if not enemy: return

	match enemy.state:
		enemy.State.IDLE:
			play("Idle", 1.0)
			
		enemy.State.PATROL:
			play("Walk", 1.0) 	
			
		enemy.State.INVESTIGATE:
			play("Fixing_Kneeling", 1.0)
			
		enemy.State.RETURN:
			play("Walk", 1.0)

		enemy.State.CHASE:
			play("Sprint", 1.2)

		enemy.State.ATTACK:
			play("Punch_Jab", 1.0)

func play(anim_name: String, speed: float) -> void:

	if not animation_player.has_animation(anim_name):
		push_warning("Animation not found: " + anim_name)
		return

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name, _blend_time)
		
	if animation_player.current_animation == anim_name:
		animation_player.speed_scale = speed
