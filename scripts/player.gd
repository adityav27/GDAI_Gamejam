extends CharacterBody3D

@onready var visuals: Node3D = %visuals
@onready var camera: Camera3D = %Camera3D
@onready var camera_pivot: Node3D = %camera_pivot

var last_move_direction = Vector3.BACK

@export_group("Movement")
@export var walk_speed = 3
@export var run_speed = 8
@export var crouch_speed = 1
@export var move_speed = 0
@export var acceleration = 20
@export var turn_speed = 12
@export var jump_impulse = 12

@export_group("Dash")
@export var dash_speed = 20
@export var dash_duration = 0.15
@export var dash_cooldown = 1

@export_group("EnvVariable")
@export var _gravity = -30.0
@export var ground_friction := 45
@export var air_friction := 3.0

var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector3.ZERO
var is_dashing := false

func player():
	pass
	
func _physics_process(delta: float) -> void:

	# ================= DASH TIMERS =================
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			dash_timer = 0.0
			is_dashing = false

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer < 0.0:
			dash_cooldown_timer = 0.0


	# ================= INPUT =================
	var move_input = Input.get_vector("left", "right", "forward", "backward")

	var forward = camera.global_basis.z
	var right = camera.global_basis.x
	var move_direction = forward * move_input.y + right * move_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()


	# ================= DASH INPUT =================
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and is_on_floor() :
		dash_direction = last_move_direction
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		is_dashing = true


	# ================= SPEED =================
	if Input.is_action_pressed("crouch"):
		move_speed = crouch_speed
		
	elif Input.is_action_pressed("run"):
		move_speed = run_speed
		
	else:
		move_speed = walk_speed

	

	# ================= MOVEMENT =================
	var y_velocity = velocity.y
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)

	if dash_timer > 0.0:
		horizontal_velocity = dash_direction * dash_speed
	else:
		if move_direction.length() > 0.1:
			horizontal_velocity = horizontal_velocity.move_toward(
				move_direction * move_speed,
				acceleration * delta
			)
		else:
			# -------- FRICTION --------
			var friction = ground_friction if is_on_floor() else air_friction
			horizontal_velocity = horizontal_velocity.move_toward(
				Vector3.ZERO,
				friction * delta
			)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	velocity.y = y_velocity + _gravity * delta


	# ================= JUMP =================
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump_impulse

	move_and_slide()
	
	# ================= CROUCH =================


	# ================= ROTATION =================
	if dash_timer <= 0.0 and move_direction.length() > 0.1:
		last_move_direction = move_direction

	var target_angle = Vector3.BACK.signed_angle_to(last_move_direction, Vector3.UP)
	visuals.global_rotation.y = lerp_angle(
		visuals.global_rotation.y,
		target_angle,
		turn_speed * delta
	)
