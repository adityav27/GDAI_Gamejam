extends Node

@onready var animation_player: AnimationPlayer = $"../Black Enemy/AnimationPlayer"
@onready var enemy: CharacterBody3D = $".."
@export var _blend_time := 0.2

func _physics_process(delta: float) -> void:
	if not enemy: return

	match enemy.state:
		enemy.State.IDLE:
			play("idle", 1.0)
			
		enemy.State.PATROL:
			play("Walk", 1.0) 	
			
		enemy.State.INVESTIGATE:
			play("look Around", 1.0)
			
		enemy.State.RETURN:
			play("Walk", 1.0)

		enemy.State.CHASE:
			play("run", 1.2)

		enemy.State.ATTACK:
			play("punch", 1.0)

func play(anim_name: String, speed: float) -> void:

	if not animation_player.has_animation(anim_name):
		push_warning("Animation not found: " + anim_name)
		return

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name, _blend_time)
		
	if animation_player.current_animation == anim_name:
		animation_player.speed_scale = speed
