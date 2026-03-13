extends Node3D

@export var float_height: float = 0.15
@export var float_speed: float = 1.5
@export var rotation_speed: float = 1.5
@export var key_number : int

@onready var node_3d: Node3D = $Node3D

var start_y: float
var time := 0.0
var free_self := false
var target_body

func _ready():
	start_y = node_3d.global_position.y

func _process(delta):
	time += delta
	node_3d.global_position.y = start_y + sin(time * float_speed) * float_height
	rotate_y(rotation_speed * delta)
	
	if free_self:
		position = lerp(position, target_body.position, 2 * delta)
		if (target_body.position - position).length() <= 0.5:
			queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		global_vars.regen_player.emit()
		target_body = body
		free_self = true

		
