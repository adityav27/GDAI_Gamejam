extends CharacterBody3D

@onready var visuals: Node3D = %visuals
@onready var camera: Camera3D = %Camera3D
@onready var camera_pivot: Node3D = %camera_pivot
@onready var stamina_bar: TextureProgressBar = $CanvasLayer/Node/StaminaBar
@onready var health_bar: TextureProgressBar = $CanvasLayer/Node/HealthBar

var last_move_direction = Vector3.BACK

@export_group("Health")
@export var max_health := 100.0
@export var health := 100.0

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

@export_group("Stamina")
@export var max_stamina := 100.0
@export var stamina := 100.0
@export var sprint_stamina_cost := 20.0
@export var jump_stamina_cost := .0
@export var dash_stamina_cost := 30.0
@export var stamina_regen := 15.
@export var stamina_regen_delay := 2

@export_group("EnvVariable")
@export var _gravity = -30.0
@export var ground_friction := 45
@export var air_friction := 3.0

var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector3.ZERO
var is_dashing := false

var stamina_regen_timer := 0.0
var displayed_stamina := 100.0
var displayed_health := 100.0

func player():
	pass

func _process(delta: float) -> void:
	displayed_stamina = lerp(displayed_stamina, stamina, 8 * delta)
	stamina_bar.value = displayed_stamina
	stamina_bar.max_value = max_stamina
	
	displayed_health = lerp(displayed_health, health, 4 * delta)
	health_bar.value = displayed_health
	health_bar.max_value = max_health
	
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

	# ================= STAMINA TIMER =================
	if stamina_regen_timer > 0.0:
		stamina_regen_timer -= delta
		if stamina_regen_timer < 0:
			stamina_regen_timer = 0

	# ================= INPUT =================
	var move_input = Input.get_vector("left", "right", "forward", "backward")

	var forward = camera.global_basis.z
	var right = camera.global_basis.x
	var move_direction = forward * move_input.y + right * move_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()


	# ================= DASH INPUT =================
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and is_on_floor()  and stamina > dash_stamina_cost:
		dash_direction = last_move_direction
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		stamina -= dash_stamina_cost
		is_dashing = true


	# ================= SPEED =================
	var is_sprinting := false

	if Input.is_action_pressed("crouch"):
		move_speed = crouch_speed

	elif Input.is_action_pressed("run") and stamina > 0:
		move_speed = run_speed
		is_sprinting = true

	else:
		move_speed = walk_speed

	# ================= STAMINA =================
	# drain stamina while sprinting
	if is_sprinting and move_direction.length() > 0.1 and stamina > 0:
		stamina -= sprint_stamina_cost * delta
		stamina_regen_timer = stamina_regen_delay

	# regen stamina when not sprinting
	if stamina_regen_timer == 0 and not is_sprinting:
		stamina += stamina_regen * delta

	# clamp stamina
	stamina = clamp(stamina, 0.0, max_stamina)


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
	if Input.is_action_just_pressed("jump") and is_on_floor() and stamina >= jump_stamina_cost:
		velocity.y += jump_impulse
		stamina -= jump_stamina_cost
		stamina_regen_timer = stamina_regen_delay
		
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
