extends Node

@onready var spring_arm: SpringArm3D = $"../camera_pivot/SpringArm3D"
@onready var camera: Camera3D = %Camera3D
@onready var camera_pivot: Node3D = %camera_pivot

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensi := 0.1
@export_range(-90.0, 0.0, 0.1, "radians_as_degree") var min_vertical_angle := -PI / 4
@export_range(0.0, 90.0, 0.1, "radians_as_degree") var max_vertical_angle := PI / 4
@export var min_zoom := 0.5
@export var max_zoom := 5.0
@export var zoom_speed := 0.5
@export var invert_y := false

# --- ADDED (controller only) ---
@export var joystick_sensi := 2.5
@export var joystick_deadzone := 0.15
# --------------------------------

var _camera_input_direction := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:

	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var y_input = motion.relative.y * mouse_sensi
		if invert_y:
			y_input *= -1

		_camera_input_direction.x += motion.relative.x * mouse_sensi
		_camera_input_direction.y += y_input

	# Zoom
	if event.is_action_pressed("wheel_up"):
		spring_arm.spring_length -= zoom_speed
	if event.is_action_pressed("wheel_down"):
		spring_arm.spring_length += zoom_speed

	spring_arm.spring_length = clamp(spring_arm.spring_length, min_zoom, max_zoom)

func _process(delta: float) -> void:
	# --- ADDED (controller only) ---
	var joy_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var joy_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)

	if abs(joy_x) > joystick_deadzone:
		_camera_input_direction.x += joy_x * joystick_sensi

	if abs(joy_y) > joystick_deadzone:
		var joy_input_y = joy_y * joystick_sensi
		if invert_y:
			joy_input_y *= -1

		_camera_input_direction.y -= joy_input_y
	# --------------------------------

	# Vertical
	camera_pivot.rotation.x -= _camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, min_vertical_angle, max_vertical_angle)

	# Horizontal
	camera_pivot.rotation.y -= _camera_input_direction.x * delta
	camera_pivot.rotation.y = fmod(camera_pivot.rotation.y + TAU, TAU)

	# Reset after use
	_camera_input_direction = Vector2.ZERO
