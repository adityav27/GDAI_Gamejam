extends CharacterBody3D
@export var navAgent: NavigationAgent3D
@onready var visuals: Node3D = $Visuals

enum States{attack,idle,chase,death}
@export_group("Enemy Stats")
@export var speed=5.0
@export var acc=6.0
@export var turn_speed=10.0
@export var chase_radius=5.491
@export var attack_radius=1.087
@export var hp=100
@export var state=States.idle
var target =null 
var gravity = -30

signal is_player_detected(state: bool)

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.y+=gravity*delta
	if target == null and state == States.chase:
		state = States.idle
		return
	match state:
		States.idle:
			velocity=Vector3.ZERO
		States.chase:
			navAgent.target_position=target.global_position
			var direction =navAgent.get_next_path_position()-global_position
			direction = direction.normalized()		
			velocity=velocity.lerp(direction*speed,acc*delta)
			var target_angle= Vector3.BACK.signed_angle_to(direction,Vector3.UP)
			visuals.global_rotation.y=lerp_angle(visuals.global_rotation.y,target_angle,turn_speed*delta)
			
		States.attack:
			velocity=Vector3.ZERO
		States.death:
			velocity=Vector3.ZERO
	move_and_slide()
	

func _on_chase_area_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		target=body
		state = States.chase
		is_player_detected.emit(true)

func _on_chase_area_body_exited(body: Node3D) -> void:
	if body.has_method("player"):
		target=null
		state = States.idle

func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		state = States.attack
		
func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.has_method("player"):
		target=body
		state = States.chase
