extends MeshInstance3D

@export var invis_material : Material
@export var transition_speed := 2.5

var enabled := false
var shimmer := 0.0

func _ready():
	invis_material = invis_material.duplicate()
	set_surface_override_material(0, invis_material)
	#set_surface_override_material(1, invis_material)

func _process(delta):

	if enabled:
		shimmer = min(shimmer + delta * transition_speed, 1.0)
		set_surface_override_material(0, invis_material)
		#set_surface_override_material(1, invis_material)
	else:
		shimmer = max(shimmer - delta * transition_speed, 0.0)
		set_surface_override_material(0, null)
		#set_surface_override_material(1, null)
		
		

	invis_material.set_shader_parameter("shimmer_amount", shimmer)
