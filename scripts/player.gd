extends CharacterBody3D

@onready var visuals: Node3D = $player
@onready var camera: Camera3D = %Camera3D
@onready var camera_pivot: Node3D = %camera_pivot
@onready var stamina_bar: TextureProgressBar = $CanvasLayer/Node/StaminaBar
@onready var health_bar: TextureProgressBar = $CanvasLayer/Node/HealthBar
@onready var invis_bar: TextureProgressBar = $CanvasLayer/Node/InvisBar
@onready var ceiling_check: RayCast3D = $CeilingCheck
@onready var hitbox: CollisionShape3D = $CollisionShape3D
@onready var invis_visual := $player/Armature/Skeleton3D/vanguard_Mesh

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
@export var jump_impulse = 10

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

@export_group("Crouching")
@export var stand_height := 1.8
@export var crouch_height := 0.9
@export var stand_hitbox_y := 0.9
@export var crouch_hitbox_y := 0.45

@export_group("Invisibility")
@export var invis_duration := 10.0
@export var max_invis_uses := 1

@export_group("EnvVariable")
@export var _gravity = -30.0
@export var ground_friction := 45
@export var air_friction := 3.0

signal crouched
signal stood

var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector3.ZERO
var is_dashing := false

var stamina_regen_timer := 0.0
var displayed_stamina := 100.0
var displayed_health := 100.0

var displayed_invis_timer := 100.0
var invis_timer := 0.0
var invis_uses_left := 0
var is_invisible := false

var is_crouching = false

func player():
	pass

func _ready():
	displayed_invis_timer = invis_duration
	invis_timer = invis_duration
	stop_invisibility()
	invis_uses_left = max_invis_uses
	
	global_vars.damage_player.connect(_on_damage_player)
	global_vars.regen_player.connect(_on_regen_player)
	global_vars.is_player_invisible = false
	global_vars.is_player_dead = false

func _process(delta: float) -> void:
	displayed_stamina = lerp(displayed_stamina, stamina, 8 * delta)
	stamina_bar.value = displayed_stamina
	stamina_bar.max_value = max_stamina
	
	displayed_health = lerp(displayed_health, health, 4 * delta)
	health_bar.value = displayed_health
	health_bar.max_value = max_health
		
	displayed_invis_timer = invis_timer
	invis_bar.value = displayed_invis_timer
	invis_bar.max_value = invis_duration
	
	if health <= 0.0:
		global_vars.is_player_dead = true
		#await $sfx_manager/GameOver.finished()
		await get_tree().create_timer(1.9).timeout
		get_tree().change_scene_to_file("res://scene/death_menu.tscn")
		
	
	
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

	# ================= INVIS TIMER =================
	if is_invisible:
		invis_timer -= delta

		if invis_timer <= 0:
			stop_invisibility()
			
	# ================= INPUT =================
	var move_input = Input.get_vector("left", "right", "forward", "backward")

	var forward = camera.global_basis.z
	var right = camera.global_basis.x
	var move_direction = forward * move_input.y + right * move_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()


	# ================= DASH INPUT =================
	#if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and is_on_floor() and not is_crouching:
			#dash_direction = last_move_direction
			#dash_timer = dash_duration
			#dash_cooldown_timer = dash_cooldown
			#stamina -= dash_stamina_cost
			#is_dashing = true


	# ================= SPEED =================
	var is_sprinting := false

	# ================= CROUCH INPUT =================
	if Input.is_action_just_pressed("crouch"):

		if not is_crouching:
			crouch()

		else:
			# prevent standing if something above head
			if not ceiling_check.is_colliding():
				stand()
		
	elif Input.is_action_pressed("run") and stamina > 0 and not is_crouching:
		move_speed = run_speed
		is_sprinting = true
		
	else:
		if is_crouching:
			move_speed = crouch_speed
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

	# ================= INVIS INPUT =================
	if Input.is_action_just_pressed("invis") and not is_invisible and invis_uses_left > 0:
		start_invisibility()


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
	
	
func crouch():
	if is_crouching:
		return

	is_crouching = true
	move_speed = crouch_speed
	crouched.emit()
	var shape = hitbox.shape as CapsuleShape3D
	shape.height = crouch_height
	var t = hitbox.transform
	t.origin.y = crouch_hitbox_y
	hitbox.transform = t
	
func stand():
	if ceiling_check.is_colliding():
		return
	is_crouching = false
	move_speed = walk_speed
	stood.emit()

	var shape = hitbox.shape as CapsuleShape3D
	shape.height = stand_height

	var t = hitbox.transform
	t.origin.y = stand_hitbox_y
	hitbox.transform = t

func start_invisibility():
	is_invisible = true
	global_vars.is_player_invisible = true
	invis_timer = invis_duration
	invis_uses_left -= 1
	invis_visual.enabled = true


func stop_invisibility():
	is_invisible = false
	global_vars.is_player_invisible = false
	invis_timer = 0
	invis_visual.enabled = false
	
func _on_damage_player(damage):
	health -= damage
	if health > 0.0:
		$sfx_manager.play_hurt()

func _on_regen_player():
	health = 100
