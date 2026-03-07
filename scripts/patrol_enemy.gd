extends CharacterBody3D

# --------------------
# NODES
# --------------------
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_ray: RayCast3D = $VisionRay 
@onready var visuals: Node3D = $Visuals

# --------------------
# CONFIGURATION
# --------------------
@export_group("Movement Stats")
@export var speed_walk: float = 2.0
@export var speed_run: float = 5.0
@export var turn_speed: float = 12.0 
@export var acceleration: float = 8.0

@export_group("Vision Settings")
@export_range(10, 360) var view_angle: float = 120.0 # Change this to widen/narrow FOV
@export var vision_range: float = 25.0 # How far the enemy can see (meters)

@export_group("AI Logic")
@export var patrol_points: Array[Node3D] = [] 
@export var attack_range: float = 1.5
@export var investigate_wait_time: float = 4.0 
@export var patrol_wait_time: float = 3.0 

# --------------------
# STATE MACHINE
# --------------------
enum State { IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, RETURN }
var state: State = State.IDLE

var patrol_index: int = 0
var state_timer: float = 0.0
var return_position: Vector3
var target: Node3D = null 
var last_known_position: Vector3 
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var path_update_timer: float = 0.0
const PATH_UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	
	vision_ray.enabled = true
	vision_ray.add_exception(self)
	
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = 1.0
	
	if patrol_points.is_empty():
		_enter_state(State.IDLE)
	else:
		_enter_state(State.PATROL)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	_update_path_logic(delta)

	match state:
		State.IDLE:        _state_idle(delta)
		State.PATROL:      _state_patrol(delta)
		State.INVESTIGATE: _state_investigate(delta)
		State.CHASE:       _state_chase(delta)
		State.ATTACK:      _state_attack(delta)
		State.RETURN:      _state_return(delta)

	_handle_vision_ray_rotation()
	move_and_slide()

# --------------------
# STATE HANDLERS
# --------------------
func _state_idle(delta: float) -> void:
	_stop_movement(delta)
	if _can_see_player(): _enter_state(State.CHASE)

func _state_patrol(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		_stop_movement(delta)
		state_timer -= delta
		if state_timer <= 0.0:
			_go_to_next_patrol_point()
			state_timer = patrol_wait_time 
	else:
		state_timer = patrol_wait_time 
		_move_towards_target(speed_walk, delta)

	if _can_see_player(): _enter_state(State.CHASE)

func _state_investigate(delta: float) -> void:
	_stop_movement(delta)
	state_timer -= delta
	visuals.rotate_y(1.0 * delta) 
	if state_timer <= 0.0:
		_enter_state(State.RETURN)
	if _can_see_player(): _enter_state(State.CHASE)

func _state_chase(delta: float) -> void:
	if not target:
		_enter_state(State.RETURN)
		return

	# Target Locking: Ignore FOV angle if we already have a lock (Raycast connects)
	var can_see = _can_see_player()
	
	if can_see:
		last_known_position = target.global_position
		nav_agent.target_position = target.global_position
		_face_target(target.global_position, delta)
		
		var dist = global_position.distance_to(target.global_position)
		if dist < attack_range:
			_enter_state(State.ATTACK)
		else:
			_move_towards_target(speed_run, delta)
	else:
		if nav_agent.is_navigation_finished():
			_enter_state(State.INVESTIGATE)
		else:
			nav_agent.target_position = last_known_position
			_move_towards_target(speed_run, delta)

func _state_attack(delta: float) -> void:
	_stop_movement(delta)
	if target:
		_face_target(target.global_position, delta)
		if global_position.distance_to(target.global_position) > attack_range:
			_enter_state(State.CHASE)

func _state_return(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		_enter_state(State.PATROL)
	elif _can_see_player():
		_enter_state(State.CHASE)
	else:
		_move_towards_target(speed_walk, delta)

# --------------------
# HELPER FUNCTIONS
# --------------------
func _enter_state(new_state: State) -> void:
	if new_state == State.PATROL and patrol_points.is_empty():
		state = State.IDLE
		return
	state = new_state
	match state:
		State.PATROL:
			nav_agent.target_position = patrol_points[patrol_index].global_position
			state_timer = patrol_wait_time
		State.INVESTIGATE:
			state_timer = investigate_wait_time
		State.CHASE:
			return_position = global_position 
			if target: last_known_position = target.global_position
		State.RETURN:
			nav_agent.target_position = return_position

func _go_to_next_patrol_point() -> void:
	if patrol_points.is_empty(): return
	patrol_index = (patrol_index + 1) % patrol_points.size()
	nav_agent.target_position = patrol_points[patrol_index].global_position

func _update_path_logic(delta: float) -> void:
	path_update_timer -= delta
	if path_update_timer > 0.0: return
	path_update_timer = PATH_UPDATE_INTERVAL
	if state == State.CHASE and target and _can_see_player():
		nav_agent.target_position = target.global_position

# --------------------
# MOVEMENT & ROTATION
# --------------------
func _move_towards_target(current_speed: float, delta: float) -> void:
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - global_position).normalized()
	_face_direction(dir, delta)
	velocity.x = lerp(velocity.x, dir.x * current_speed, acceleration * delta)
	velocity.z = lerp(velocity.z, dir.z * current_speed, acceleration * delta)

func _stop_movement(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
	velocity.z = lerp(velocity.z, 0.0, acceleration * delta)

func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length() > 0.001:
		var target_rotation = atan2(dir.x, dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rotation, turn_speed * delta)

func _face_target(pos: Vector3, delta: float) -> void:
	var dir = (pos - global_position).normalized()
	_face_direction(dir, delta)

# --------------------
# VISION (LOCKED SETTINGS)
# --------------------
func _can_see_player() -> bool:
	if not target: return false
	
	var dist = global_position.distance_to(target.global_position)
	if dist > vision_range: return false 
	
	var in_fov = false
	
	if state == State.CHASE or state == State.ATTACK:
		in_fov = true # 360 combat awareness
	else:
		var to_player = (target.global_position - global_position).normalized()
		var forward_vector = Vector3.FORWARD
		
		# LOCKED: Automatic Forward Detection
		# 1. If moving, look where we are going
		if velocity.length() > 0.1:
			forward_vector = velocity.normalized()
		# 2. If standing still, look where the body is facing (-Z)
		else:
			forward_vector = -visuals.global_transform.basis.z 
		
		var angle = rad_to_deg(acos(clamp(forward_vector.dot(to_player), -1.0, 1.0)))
		
		if angle < view_angle / 2.0:
			in_fov = true

	if not in_fov:
		return false

	if vision_ray.is_colliding():
		var collider = vision_ray.get_collider()
		if collider == target:
			return true
			
	return false

func _handle_vision_ray_rotation() -> void:
	if target:
		vision_ray.look_at(target.global_position, Vector3.UP)
