extends CharacterBody3D
@export var navAgent: NavigationAgent3D
@onready var visuals: Node3D = $"red enemy"

enum States{attack,idle,search,chase,death}
@export_group("Enemy Stats")
@export var speed=5.0
@export var acc=6.0
@export var turn_speed=10.0
@export var chase_radius=5.491
@export var attack_radius=1.087
@export var hp=100
@export var state=States.idle
@export var acceleration: float = 8.0

var is_player_in_attack_zone := false
var is_player_in_chase_zone := false
var is_player_detected := false

var next_state = States.idle
var state_timer := 0.0

var target = null 
var gravity = -30
var is_attacking: bool = false
var pending_exit: bool = false
@export var attack_duration: float = 1.0
var attack_timer: float = 0.0

var body_target : Node3D


signal player_detected(state: bool)

func _process(delta: float) -> void:

	if is_player_in_attack_zone and not global_vars.is_player_invisible:
		next_state = States.attack

	elif is_player_in_chase_zone and not global_vars.is_player_invisible:
		next_state = States.chase
		target = body_target
		is_player_detected = true

	elif is_player_detected and global_vars.is_player_invisible:
		next_state = States.search

	else:
		next_state = States.idle

func _physics_process(delta: float) -> void:
	# Lose target if player becomes invisible
	if target != null and global_vars.is_player_invisible:
		target = null
		state = States.idle

	
	if !is_on_floor():
		velocity.y += gravity * delta
	if target == null and state == States.chase:
		state = States.idle
		return
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			on_attack_finished()

	match state:
		States.idle:
			velocity = Vector3.ZERO
		States.search:
			state_timer = 3.0
			_stop_movement(delta)
			state_timer -= delta
			if state_timer <= 0.0:
				state = States.idle
						
		States.chase:
			navAgent.target_position = target.global_position
			var direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()		
			velocity = velocity.lerp(direction * speed, acc * delta)
			var target_angle = Vector3.BACK.signed_angle_to(direction, Vector3.UP)
			visuals.global_rotation.y = lerp_angle(visuals.global_rotation.y, target_angle, turn_speed * delta)
		States.attack:
			velocity = Vector3.ZERO
		States.death:
			velocity = Vector3.ZERO
	move_and_slide()

func on_attack_finished() -> void:
	is_attacking = false
	if pending_exit:
		pending_exit = false
		if target != null:
			state = States.chase
		else:
			state = States.idle

func _on_chase_area_body_entered(body: Node3D) -> void:
	body_target = body
	if body.has_method("player"):
		is_player_in_chase_zone = true
		if not global_vars.is_player_invisible:
			is_player_detected = true
			target = body
			state = States.chase


func _on_chase_area_body_exited(body: Node3D) -> void:
	is_player_in_chase_zone = false
	is_player_detected = false
	if body.has_method("player"):
		target = null
		state = States.idle

func _on_attack_area_body_entered(body: Node3D) -> void:
	body_target = body
	if body.has_method("player"):	
		is_player_in_attack_zone = true

		if not is_attacking and not global_vars.is_player_invisible:
			is_attacking = true
			attack_timer = attack_duration
			pending_exit = false
			state = States.attack
			body.get_node("sfx_manager").play_hurt()
		
func _on_attack_area_body_exited(body: Node3D) -> void:
	body_target = body
	is_player_in_attack_zone = false
	if body.has_method("player"):
		if is_attacking:
			target = body
			pending_exit = true
		else:
			target = body
			state = States.chase


func change_state(new_state):
	if state == new_state:
		return

	state = new_state


			
func _stop_movement(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
	velocity.z = lerp(velocity.z, 0.0, acceleration * delta)
